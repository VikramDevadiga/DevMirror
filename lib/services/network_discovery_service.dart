import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DiscoveredServer {
  final String ip;
  final int port;
  final String serverType;
  final String? pageTitle;

  const DiscoveredServer({
    required this.ip,
    required this.port,
    required this.serverType,
    this.pageTitle,
  });

  String get displayName {
    if (pageTitle != null && pageTitle!.trim().isNotEmpty) {
      return pageTitle!.trim();
    }
    return serverType;
  }

  String get address => '$ip:$port';
  String get url => 'http://$ip:$port';

  DiscoveredServer copyWith({
    String? ip,
    int? port,
    String? serverType,
    String? pageTitle,
  }) {
    return DiscoveredServer(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      serverType: serverType ?? this.serverType,
      pageTitle: pageTitle ?? this.pageTitle,
    );
  }
}

enum ScanLogLevel { command, info, probe, open, title, warn, done }

/// A single line of the live scan log, rendered terminal-style in the UI
class ScanLogEntry {
  final ScanLogLevel level;
  final String message;
  final Duration elapsed;

  const ScanLogEntry(this.level, this.message, this.elapsed);
}

class _ProbeTask {
  final String ip;
  final int port;
  const _ProbeTask(this.ip, this.port);
}

class NetworkDiscoveryService {
  static const List<int> commonPorts = [
    // Standard protocols
    21, // FTP
    22, // SSH
    80, // HTTP
    443, // HTTPS

    // JavaScript / Node / React / Next.js
    3000, // React / Node / Express / Next.js
    3001, // React / Node alternative
    3002, // Node / React alternative
    4000, // Common Node / GraphQL

    // Frontend Frameworks
    4200, // Angular
    5000, // Flask / ASP.NET
    5001, // ASP.NET Core
    5173, // Vite
    5174, // Vite alternative

    // Live Server / VS Code
    5500, // VS Code Live Server
    5501, // VS Code Live Server alternative
    5502, // Live Server alternative

    // Component & Storybook
    6006, // Storybook

    // Python / Backend / AI
    8000, // Django / FastAPI / Python
    8001, // Python / backend alternative
    8002, // Python / backend alternative

    // Webpack / Vue / Spring / Metro / Frontend Alternatives
    8080, // Webpack / Vue / Spring Boot
    8081, // Webpack / Metro
    8082, // Frontend alternative
    8083, // Frontend alternative
    8084, // Frontend alternative
    8085, // Frontend alternative

    // Tools & Data Science
    8888, // Jupyter Notebook
    9000, // Various development tools
  ];

  /// Interface name prefixes that never share a LAN with the dev machine
  /// (loopback, cellular, VPN)
  static const List<String> _excludedInterfacePrefixes = [
    'lo', 'dummy', 'rmnet', 'r_rmnet', 'rev_rmnet', 'ccmni', 'seth', 'pdp',
    'ppp', 'clat', 'v4-', 'tun', 'ipsec', 'wg',
  ];

  static const int unknownInterfaceRank = 3;

  /// Scan order for an interface (lower first): Wi-Fi, Ethernet, then
  /// hotspot / USB / Bluetooth tethering. Returns null for excluded interfaces.
  static int? interfaceRank(String name) {
    final n = name.toLowerCase();
    bool startsWithAny(List<String> prefixes) => prefixes.any(n.startsWith);

    if (startsWithAny(_excludedInterfacePrefixes)) return null;
    if (startsWithAny(['wlan', 'wifi'])) return 0;
    if (startsWithAny(['eth', 'en'])) return 1;
    if (startsWithAny(['ap', 'swlan', 'softap', 'rndis', 'ncm', 'usb', 'bt-pan'])) {
      return 2;
    }
    return unknownInterfaceRank;
  }

  /// Picks the device addresses whose subnets should be scanned, best first.
  /// Unrecognised interfaces are only used when no known LAN interface has an address.
  static List<String> selectLanIps(Map<String, List<String>> addressesByInterface) {
    final ipsByRank = <int, List<String>>{};
    addressesByInterface.forEach((name, addresses) {
      final rank = interfaceRank(name);
      if (rank == null) return;
      for (final ip in addresses) {
        if (!ip.startsWith('127.') && !ip.startsWith('169.254.')) {
          ipsByRank.putIfAbsent(rank, () => []).add(ip);
        }
      }
    });

    final knownRanks = ipsByRank.keys.where((r) => r < unknownInterfaceRank).toList()..sort();
    final known = [for (final rank in knownRanks) ...ipsByRank[rank]!];
    return known.isNotEmpty ? known : (ipsByRank[unknownInterfaceRank] ?? []);
  }

  /// Finds the device's local IPv4 addresses on every network a dev machine
  /// could share (Wi-Fi, Ethernet, hotspot, USB tethering), Wi-Fi first
  static Future<List<String>> getLocalNetworkIps() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      return selectLanIps({
        for (final interface in interfaces)
          interface.name: [for (final addr in interface.addresses) addr.address],
      });
    } catch (_) {
      return [];
    }
  }

  /// Orders the hosts to probe: priority IPs, then each subnet's own host,
  /// gateway (.1) and +/- 30 neighbors, then the remainder of each subnet
  static List<String> buildTargetIps(List<String> localIps, List<String> priorityIps) {
    final targetIps = <String>{...priorityIps.where((ip) => ip.isNotEmpty)};

    final subnets = <(String prefix, int host)>[];
    for (final ip in localIps) {
      final parts = ip.split('.');
      final host = parts.length == 4 ? int.tryParse(parts[3]) : null;
      if (host != null) subnets.add((parts.take(3).join('.'), host));
    }

    for (final (prefix, host) in subnets) {
      if (host >= 1 && host <= 254) targetIps.add('$prefix.$host');
      targetIps.add('$prefix.1');
      for (int offset = 1; offset <= 30; offset++) {
        if (host - offset >= 1) targetIps.add('$prefix.${host - offset}');
        if (host + offset <= 254) targetIps.add('$prefix.${host + offset}');
      }
    }

    for (final (prefix, _) in subnets) {
      for (int i = 1; i <= 254; i++) {
        targetIps.add('$prefix.$i');
      }
    }

    return targetIps.toList();
  }

  /// Probes a single IP and port via TCP socket
  static Future<bool> probeSocket(
    String ip,
    int port, {
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      socket?.destroy();
      return false;
    }
  }

  /// Fetches the HTML <title> from the dev server URL
  static Future<String?> fetchHtmlTitle(
    String ip,
    int port, {
    Duration timeout = const Duration(milliseconds: 1000),
  }) async {
    try {
      final client = HttpClient()..connectionTimeout = timeout;
      final uri = Uri.parse('http://$ip:$port/');
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'text/html,application/xhtml+xml');
      request.headers.set(HttpHeaders.userAgentHeader, 'DevMirror/1.0');
      
      final response = await request.close().timeout(timeout);
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length > 20480) break; // First 20KB is ample for <head><title>
      }
      client.close(force: true);

      final html = utf8.decode(bytes, allowMalformed: true);
      final titleMatch = RegExp(
        r'<title[^>]*>(.*?)</title>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(html);

      if (titleMatch != null) {
        final raw = titleMatch.group(1)?.trim() ?? '';
        final cleaned = raw
            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll('&nbsp;', ' ')
            .trim();

        if (cleaned.isNotEmpty && cleaned.toLowerCase() != 'document' && cleaned != 'Index of /') {
          return cleaned;
        }
      }
    } catch (_) {}
    return null;
  }

  static String _identifyServer(int port) {
    switch (port) {
      case 21:
        return 'FTP Server';
      case 22:
        return 'SSH Server';
      case 80:
        return 'HTTP Web Server';
      case 443:
        return 'HTTPS Web Server';
      case 3000:
        return 'React / Node / Next.js';
      case 3001:
      case 3002:
        return 'Node / React';
      case 4000:
        return 'Node / GraphQL';
      case 4200:
        return 'Angular';
      case 5000:
        return 'Flask / ASP.NET';
      case 5001:
        return 'ASP.NET Core';
      case 5173:
        return 'Vite App';
      case 5174:
        return 'Vite (Alt)';
      case 5500:
      case 5501:
      case 5502:
        return 'Live Server';
      case 6006:
        return 'Storybook';
      case 8000:
      case 8001:
      case 8002:
        return 'Django / FastAPI / Python';
      case 8080:
        return 'Webpack / Vue / Spring Boot';
      case 8081:
        return 'Webpack / Metro';
      case 8082:
      case 8083:
      case 8084:
      case 8085:
        return 'Frontend Dev Server';
      case 8888:
        return 'Jupyter Notebook';
      case 9000:
        return 'Dev Server';
      default:
        return 'Dev Server';
    }
  }

  static String _formatCount(int n) => n
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  /// Scans every local subnet (Wi-Fi first) for active dev servers using a smooth, non-blocking worker pool
  static Stream<DiscoveredServer> scanSubnet({
    List<int> ports = commonPorts,
    List<String> priorityIps = const [],
    void Function(double progress, String currentIp)? onProgress,
    void Function(ScanLogEntry entry)? onLog,
  }) {
    late final StreamController<DiscoveredServer> controller;
    bool cancelled = false;

    controller = StreamController<DiscoveredServer>(
      // Stop the worker pool when the listener goes away (rescan / screen disposed)
      onCancel: () => cancelled = true,
      onListen: () async {
        final stopwatch = Stopwatch()..start();
        int openCount = 0;

        void log(ScanLogLevel level, String message) {
          if (!cancelled) {
            onLog?.call(ScanLogEntry(level, message, stopwatch.elapsed));
          }
        }

        try {
          log(ScanLogLevel.command, 'devmirror scan --lan --ports ${ports.length}');
          log(ScanLogLevel.info, 'resolving network interfaces');

          final localIps = await getLocalNetworkIps();
          if (controller.isClosed) return;

          if (localIps.isEmpty) {
            log(ScanLogLevel.warn, 'no Wi-Fi/LAN interface found');
          }
          for (final ip in localIps) {
            log(ScanLogLevel.info, 'local ip $ip/24');
          }
          final savedHosts = priorityIps.where((ip) => ip.isNotEmpty).toSet().length;
          if (savedHosts > 0) {
            log(
              ScanLogLevel.info,
              'probing $savedHosts saved ${savedHosts == 1 ? 'host' : 'hosts'} first',
            );
          }

          // Priority IPs (manually entered IP, saved servers) are still scanned
          // when no local network is found
          final targetIps = buildTargetIps(localIps, priorityIps);

          // Build task queue
          final List<_ProbeTask> tasks = [];
          for (final ip in targetIps) {
            for (final port in ports) {
              tasks.add(_ProbeTask(ip, port));
            }
          }

          final int totalTasks = tasks.length;
          int completedTasks = 0;
          DateTime lastProgressUpdate = DateTime.now();

          // Controlled concurrency pool (35 concurrent socket workers)
          const int concurrency = 35;
          int currentTaskIndex = 0;
          Duration lastProbeLog = Duration.zero;
          log(
            ScanLogLevel.info,
            'queued ${_formatCount(totalTasks)} probes, $concurrency workers',
          );

          Future<void> worker() async {
            while (currentTaskIndex < tasks.length &&
                !controller.isClosed &&
                !cancelled) {
              final taskIndex = currentTaskIndex++;
              if (taskIndex >= tasks.length) break;

              final task = tasks[taskIndex];
              final isOpen = await probeSocket(task.ip, task.port);

              if (isOpen && !controller.isClosed) {
                // Instantly emit discovered server with serverType in <10ms
                final baseServer = DiscoveredServer(
                  ip: task.ip,
                  port: task.port,
                  serverType: _identifyServer(task.port),
                );
                openCount++;
                log(ScanLogLevel.open, '${task.ip}:${task.port}  ${baseServer.serverType}');
                controller.add(baseServer);

                // Fetch HTML title asynchronously without blocking the worker pool
                fetchHtmlTitle(task.ip, task.port).then((title) {
                  if (title != null && !controller.isClosed) {
                    log(ScanLogLevel.title, ':${task.port} -> "$title"');
                    controller.add(baseServer.copyWith(pageTitle: title));
                  }
                }).catchError((_) {});
              } else if (stopwatch.elapsed - lastProbeLog >
                  const Duration(milliseconds: 80)) {
                // Sample closed probes so the log streams without flooding the UI
                lastProbeLog = stopwatch.elapsed;
                log(ScanLogLevel.probe, '${task.ip}:${task.port}');
              }

              completedTasks++;

              // Throttle progress updates to at most once per 100ms
              final now = DateTime.now();
              if (now.difference(lastProgressUpdate).inMilliseconds > 100 || completedTasks == totalTasks) {
                lastProgressUpdate = now;
                onProgress?.call(completedTasks / totalTasks, task.ip);
              }

              // Micro-yield to event loop
              if (completedTasks % 35 == 0) {
                await Future.delayed(Duration.zero);
              }
            }
          }

          final workers = List.generate(concurrency, (_) => worker());
          await Future.wait(workers);

          if (!controller.isClosed) {
            onProgress?.call(1.0, localIps.firstOrNull ?? '');
            final seconds = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
            log(ScanLogLevel.done, 'scan complete: $openCount open in ${seconds}s');
            await controller.close();
          }
        } catch (_) {
          log(ScanLogLevel.warn, 'scan aborted');
          if (!controller.isClosed) {
            await controller.close();
          }
        }
      },
    );

    return controller.stream;
  }
}
