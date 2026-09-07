import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../models/server_connection.dart';
import '../services/browser_service.dart';
import '../services/connection_storage_service.dart';
import '../services/network_discovery_service.dart';
import '../services/reachability_service.dart';
import '../theme/app_theme.dart';
import 'help_screen.dart';

class ConnectScreen extends StatefulWidget {
  final ConnectionStorageService storageService;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const ConnectScreen({
    super.key,
    required this.storageService,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '5500');

  bool _isChecking = false;
  List<ServerConnection> _savedConnections = [];

  // Live Auto-Discovery State
  final List<DiscoveredServer> _liveServers = [];
  bool _isScanning = false;
  double _scanProgress = 0.0;
  StreamSubscription<DiscoveredServer>? _scanSubscription;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _loadSavedConnections();

    // Auto-discover live servers on Wi-Fi immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLiveScan();
    });
  }

  void _loadSavedConnections() {
    final connections = widget.storageService.getConnections();
    final lastUsed = widget.storageService.getLastUsedConnection();

    setState(() {
      _savedConnections = connections;
      if (lastUsed != null && _ipController.text.isEmpty) {
        _ipController.text = lastUsed.ip;
        _portController.text = lastUsed.port.toString();
      }
    });
  }

  void _startLiveScan() {
    _scanSubscription?.cancel();

    setState(() {
      _liveServers.clear();
      _isScanning = true;
      _scanProgress = 0.0;
    });

    final ports = List<int>.from(NetworkDiscoveryService.commonPorts);
    final customPort = int.tryParse(_portController.text.trim());
    if (customPort != null &&
        customPort >= 1 &&
        customPort <= 65535 &&
        !ports.contains(customPort)) {
      ports.insert(0, customPort);
    }

    final stream = NetworkDiscoveryService.scanSubnet(
      ports: ports,
      onProgress: (progress, currentIp) {
        if (mounted) {
          setState(() {
            _scanProgress = progress;
          });
        }
      },
    );

    _scanSubscription = stream.listen(
      (server) {
        if (mounted) {
          setState(() {
            final idx = _liveServers
                .indexWhere((s) => s.ip == server.ip && s.port == server.port);
            if (idx >= 0) {
              _liveServers[idx] = server;
            } else {
              _liveServers.add(server);
            }
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _scanProgress = 1.0;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanSubscription?.cancel();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    final isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;
    widget.onThemeModeChanged(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _handleConnect({
    String? explicitIp,
    int? explicitPort,
    String? explicitLabel,
    bool force = false,
  }) async {
    final ip = (explicitIp ?? _ipController.text).trim();
    final port =
        explicitPort ?? int.tryParse(_portController.text.trim()) ?? 5500;
    String label = (explicitLabel ?? '').trim();

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Please enter an IP address'),
        ),
      );
      return;
    }

    setState(() {
      _isChecking = true;
    });

    if (!force) {
      final result = await ReachabilityService.checkReachability(ip, port);
      if (!result.isReachable) {
        if (mounted) {
          setState(() {
            _isChecking = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(result.errorMessage ?? 'Could not reach server'),
              action: SnackBarAction(
                label: 'Open anyway',
                onPressed: () => _handleConnect(
                  explicitIp: ip,
                  explicitPort: port,
                  explicitLabel: label,
                  force: true,
                ),
              ),
            ),
          );
        }
        return;
      }
    }

    // Auto-fetch HTML <title> from the server if label is empty
    if (label.isEmpty || label == 'Dev Server') {
      final pageTitle = await NetworkDiscoveryService.fetchHtmlTitle(ip, port);
      if (pageTitle != null && pageTitle.isNotEmpty) {
        label = pageTitle;
      } else {
        label = 'Dev Server';
      }
    }

    // Save connection
    final connection = ServerConnection(
      id: '${ip}_$port',
      label: label,
      ip: ip,
      port: port,
      lastUsedAt: DateTime.now(),
    );

    await widget.storageService.saveConnection(connection);
    _loadSavedConnections();

    if (mounted) {
      setState(() {
        _isChecking = false;
      });

      // Launch in In-App External Browser (Chrome Custom Tabs)
      await BrowserService.openInAppBrowser(
        context,
        connection: connection,
        isDark: Theme.of(context).brightness == Brightness.dark,
      );

      _loadSavedConnections();
    }
  }

  Future<void> _deleteConnection(ServerConnection connection) async {
    await widget.storageService.deleteConnection(connection.id);
    _loadSavedConnections();

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemTitle = connection.label.isNotEmpty ? connection.label : connection.address;

    final snackBg = isDark ? Colors.white : const Color(0xFF18181B);
    final snackFg = isDark ? Colors.black : Colors.white;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackBg,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
        content: Text(
          'Deleted "$itemTitle"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: snackFg,
            fontWeight: FontWeight.w600,
          ),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: snackFg,
          onPressed: () async {
            await widget.storageService.saveConnection(connection);
            _loadSavedConnections();
          },
        ),
      ),
    );
  }

  Future<void> _sendFeedbackEmail(String type) async {
    const email = 'redropecompany@gmail.com';
    final subject = Uri.encodeComponent('[DevMirror] $type');
    final body = Uri.encodeComponent('Hi DevMirror Team,\n\nHere is my $type:\n\n');
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');

    try {
      final launched = await launcher.launchUrl(
        uri,
        mode: launcher.LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _copyEmailToClipboard();
      }
    } catch (_) {
      if (mounted) {
        _copyEmailToClipboard();
      }
    }
  }

  void _copyEmailToClipboard() {
    const email = 'redropecompany@gmail.com';
    Clipboard.setData(const ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Email copied to clipboard: redropecompany@gmail.com'),
      ),
    );
  }

  void _showFeedbackDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final mutedFg = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: fg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.mail_outline_rounded,
                      color: isDark ? Colors.black : Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Feedback & Suggestions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'redropecompany@gmail.com',
                          style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 11,
                            color: mutedFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy Email',
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _copyEmailToClipboard();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildFeedbackOption(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Send Feedback / Suggestion',
                subtitle: 'Share your thoughts and ideas',
                isDark: isDark,
                borderColor: borderColor,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _sendFeedbackEmail('Feedback & Suggestion');
                },
              ),
              const SizedBox(height: 10),
              _buildFeedbackOption(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Request a Feature',
                subtitle: 'Let us know what you want to see added',
                isDark: isDark,
                borderColor: borderColor,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _sendFeedbackEmail('Feature Request');
                },
              ),
              const SizedBox(height: 10),
              _buildFeedbackOption(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug / Issue',
                subtitle: 'Tell us if something is not working',
                isDark: isDark,
                borderColor: borderColor,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _sendFeedbackEmail('Bug Report');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final fg = isDark ? Colors.white : Colors.black;
    final mutedFg = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedFg,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: mutedFg),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;
    final mutedFg = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.35, end: 1.0)
                        .animate(_pulseController),
                    child: Icon(
                      Icons.sensors_rounded,
                      size: 13,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              'DevMirror',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: fg),
            tooltip: 'How to Connect',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
          ),
          IconButton(
            icon: _isScanning
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                : Icon(Icons.refresh_rounded, color: fg),
            tooltip: 'Rescan Wi-Fi',
            onPressed: _isScanning ? null : _startLiveScan,
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: fg,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: _toggleTheme,
          ),
        ],
        bottom: _isScanning
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _scanProgress > 0 ? _scanProgress : null,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : null,
      ),
      body: RefreshIndicator(
        color: fg,
        onRefresh: () async {
          _startLiveScan();
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── 1. LIVE SERVERS FOUND ──
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _liveServers.isNotEmpty
                        ? AppTheme.liveGreen
                        : (_isScanning ? fg : mutedFg),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isScanning
                      ? 'SCANNING FOR SERVERS...'
                      : (_liveServers.isNotEmpty
                          ? 'LIVE SERVERS (${_liveServers.length})'
                          : 'LIVE SERVERS'),
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: mutedFg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_liveServers.isNotEmpty) ...[
              ..._liveServers.map((server) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _handleConnect(
                        explicitIp: server.ip,
                        explicitPort: server.port,
                        explicitLabel: server.displayName,
                        force: true,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    server.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    server.address,
                                    style: TextStyle(
                                      fontFamily: AppTheme.monoFont,
                                      fontSize: 12,
                                      color: mutedFg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: fg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                color: isDark ? Colors.black : Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ] else if (!_isScanning) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'No dev servers found on this Wi-Fi.',
                        style: TextStyle(fontSize: 13, color: mutedFg),
                      ),
                    ),
                    TextButton(
                      onPressed: _startLiveScan,
                      child: const Text('Scan again'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── 2. MANUAL CONNECT ROW ──
            Text(
              'MANUAL IP & PORT',
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: mutedFg,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _ipController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: '192.168.1.5',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: '5500',
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: fg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isChecking ? null : () => _handleConnect(),
                      child: _isChecking
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.chevron_right_rounded,
                              color: isDark ? Colors.black : Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 3. SAVED / RECENT SERVERS ──
            if (_savedConnections.isNotEmpty) ...[
              Text(
                'RECENT SERVERS',
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: mutedFg,
                ),
              ),
              const SizedBox(height: 10),
              ..._savedConnections.map((conn) {
                return Dismissible(
                  key: Key(conn.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 20),
                  ),
                  onDismissed: (_) => _deleteConnection(conn),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _handleConnect(
                          explicitIp: conn.ip,
                          explicitPort: conn.port,
                          explicitLabel: conn.label,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  conn.label.isNotEmpty
                                      ? conn.label
                                      : conn.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              Text(
                                conn.address,
                                style: TextStyle(
                                  fontFamily: AppTheme.monoFont,
                                  fontSize: 11.5,
                                  color: mutedFg,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(Icons.close_rounded,
                                    size: 16, color: mutedFg),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                tooltip: 'Delete',
                                onPressed: () => _deleteConnection(conn),
                              ),
                              Icon(Icons.chevron_right_rounded,
                                  size: 18, color: mutedFg),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],

            // ── 4. FOOTER: HOW TO CONNECT & FEEDBACK ──
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  ),
                  icon: Icon(Icons.help_outline_rounded, size: 15, color: mutedFg),
                  label: Text(
                    'How to connect',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: mutedFg,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final pulse = _pulseController.value;
                    const neonColor = Color(0xFF00FF66); // Live Neon Green
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: neonColor.withValues(alpha: 0.18 + (0.32 * pulse)),
                            blurRadius: 8 + (6 * pulse),
                            spreadRadius: 1 + (1.5 * pulse),
                          ),
                        ],
                      ),
                      child: Material(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _showFeedbackDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: neonColor.withValues(alpha: 0.70 + (0.30 * pulse)),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: neonColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: neonColor.withValues(alpha: 0.9),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 13,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Feedback',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : Colors.black,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
