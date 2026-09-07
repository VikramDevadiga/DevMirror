import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/server_connection.dart';
import '../services/reachability_service.dart';
import '../theme/app_theme.dart';

class WebViewScreen extends StatefulWidget {
  final ServerConnection connection;

  const WebViewScreen({
    super.key,
    required this.connection,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;
  String _pageTitle = '';
  String _currentUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  bool _isDesktopMode = false;
  String? _webError;

  // Custom User Agents
  static const String _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.connection.url;
    _pageTitle = widget.connection.label.isNotEmpty
        ? widget.connection.label
        : widget.connection.address;
    _initWebViewController();
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _currentUrl = url;
                _webError = null;
              });
              _updateNavigationState();
            }
          },
          onPageFinished: (String url) async {
            if (mounted) {
              final title = await _controller.getTitle();
              setState(() {
                _isLoading = false;
                _currentUrl = url;
                if (title != null && title.trim().isNotEmpty) {
                  _pageTitle = title;
                }
              });
              _updateNavigationState();
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Only capture main frame errors
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _webError = error.description;
                  _isLoading = false;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.connection.url));
  }

  Future<void> _updateNavigationState() async {
    final canBack = await _controller.canGoBack();
    final canForward = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canBack;
        _canGoForward = canForward;
      });
    }
  }

  Future<void> _toggleDesktopMode() async {
    final newDesktopMode = !_isDesktopMode;
    setState(() {
      _isDesktopMode = newDesktopMode;
    });

    if (newDesktopMode) {
      await _controller.setUserAgent(_desktopUserAgent);
    } else {
      await _controller.setUserAgent(null); // Reset to default mobile
    }

    _controller.reload();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          content: Text(
            newDesktopMode ? 'Switched to Desktop Mode' : 'Switched to Mobile Mode',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Future<void> _retryConnection() async {
    setState(() {
      _webError = null;
      _isLoading = true;
    });

    final reachability = await ReachabilityService.checkReachability(
      widget.connection.ip,
      widget.connection.port,
    );

    if (!reachability.isReachable) {
      if (mounted) {
        setState(() {
          _webError = reachability.errorMessage;
          _isLoading = false;
        });
      }
      return;
    }

    _controller.reload();
  }

  void _copyUrlToClipboard() {
    Clipboard.setData(ClipboardData(text: _currentUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        content: Text('URL copied to clipboard'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _canGoBack) {
          await _controller.goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to Connect',
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _pageTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _webError == null ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _currentUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isDesktopMode ? Icons.desktop_windows : Icons.phone_android,
                color: _isDesktopMode ? (isDark ? Colors.white : Colors.black) : null,
              ),
              tooltip: _isDesktopMode ? 'Desktop Mode (Active)' : 'Switch to Desktop Mode',
              onPressed: _toggleDesktopMode,
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              tooltip: 'Copy URL',
              onPressed: _copyUrlToClipboard,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reload',
              onPressed: () => _controller.reload(),
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3.0),
                  child: LinearProgressIndicator(
                    value: _loadingProgress > 0 ? _loadingProgress / 100.0 : null,
                    minHeight: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? Colors.white : Colors.black,
                    ),
                  ),
                )
              : null,
        ),
        body: _webError != null ? _buildErrorView(theme, isDark) : _buildWebView(),
        bottomNavigationBar: _buildBottomToolbar(theme, isDark),
      ),
    );
  }

  Widget _buildWebView() {
    return RefreshIndicator(
      onRefresh: () async {
        await _controller.reload();
      },
      child: WebViewWidget(controller: _controller),
    );
  }

  Widget _buildErrorView(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to Load Preview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: Text(
                widget.connection.url,
                style: const TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _webError ?? 'The server could not be reached.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Edit Address'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _retryConnection,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                  tooltip: 'Go Back',
                  onPressed: _canGoBack
                      ? () async {
                          await _controller.goBack();
                          _updateNavigationState();
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  tooltip: 'Go Forward',
                  onPressed: _canGoForward
                      ? () async {
                          await _controller.goForward();
                          _updateNavigationState();
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.home_rounded, size: 20),
                  tooltip: 'Reload Root URL',
                  onPressed: () {
                    _controller.loadRequest(Uri.parse(widget.connection.url));
                  },
                ),
              ],
            ),
            // Desktop Mode badge / status
            if (_isDesktopMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white12 : Colors.black12,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.desktop_windows, size: 13, color: isDark ? Colors.white : Colors.black),
                    const SizedBox(width: 4),
                    Text(
                      'DESKTOP',
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              tooltip: 'Refresh',
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
      ),
    );
  }
}
