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

  /// Finds the device's local Wi-Fi / Ethernet IPv4 address
  static Future<String?> getLocalDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Sort interfaces: prioritize Wi-Fi/Ethernet/USB before cellular/VPN
      interfaces.sort((a, b) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();
        final aIsWifi = aName.contains('wlan') ||
            aName.contains('wifi') ||
            aName.contains('eth') ||
            aName.contains('rndis') ||
            aName.contains('en');
        final bIsWifi = bName.contains('wlan') ||
            bName.contains('wifi') ||
            bName.contains('eth') ||
            bName.contains('rndis') ||
            bName.contains('en');

        if (aIsWifi && !bIsWifi) return -1;
        if (!aIsWifi && bIsWifi) return 1;
        return 0;
      });

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          if (!ip.startsWith('127.') && !ip.startsWith('169.254.')) {
            return ip;
          }
        }
      }
    } catch (_) {}
    return null;
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

  /// Scans the local subnet for active dev servers using a smooth, non-blocking worker pool
  static Stream<DiscoveredServer> scanSubnet({
    List<int> ports = commonPorts,
    List<String> priorityIps = const [],
    void Function(double progress, String currentIp)? onProgress,
  }) {
    late final StreamController<DiscoveredServer> controller;

    controller = StreamController<DiscoveredServer>(
      onListen: () async {
        try {
          final localIp = await getLocalDeviceIp();
          if (localIp == null || controller.isClosed) {
            // Still scan priority IPs if available (e.g. 127.0.0.1 or user-specified IP)
            if (priorityIps.isNotEmpty && !controller.isClosed) {
              for (final ip in priorityIps) {
                for (final port in ports) {
                  final isOpen = await probeSocket(ip, port);
                  if (isOpen && !controller.isClosed) {
                    controller.add(
                      DiscoveredServer(
                        ip: ip,
                        port: port,
                        serverType: _identifyServer(port),
                      ),
                    );
                  }
                }
              }
            }
            if (!controller.isClosed) await controller.close();
            return;
          }

          final parts = localIp.split('.');
          if (parts.length != 4) {
            if (!controller.isClosed) await controller.close();
            return;
          }

          final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
          final myHostNumber = int.tryParse(parts[3]) ?? 0;

          // Priority 1: User's priority IPs (e.g. manually entered IP, saved servers, 127.0.0.1)
          final List<String> targetIps = [];
          for (final pip in priorityIps) {
            if (pip.isNotEmpty && !targetIps.contains(pip)) {
              targetIps.add(pip);
            }
          }

          // Priority 2: Device's own IP & default gateway (.1)
          if (myHostNumber >= 1 && myHostNumber <= 254) {
            final myIp = '$subnetPrefix.$myHostNumber';
            if (!targetIps.contains(myIp)) targetIps.add(myIp);
          }
          final gatewayIp = '$subnetPrefix.1';
          if (!targetIps.contains(gatewayIp)) targetIps.add(gatewayIp);

          // Priority 3: Immediate neighbors (+/- 30)
          for (int offset = 1; offset <= 30; offset++) {
            if (myHostNumber - offset >= 1) {
              final ip = '$subnetPrefix.${myHostNumber - offset}';
              if (!targetIps.contains(ip)) targetIps.add(ip);
            }
            if (myHostNumber + offset <= 254) {
              final ip = '$subnetPrefix.${myHostNumber + offset}';
              if (!targetIps.contains(ip)) targetIps.add(ip);
            }
          }

          // Priority 4: Remainder of subnet (.2 to .254)
          for (int i = 1; i <= 254; i++) {
            final ip = '$subnetPrefix.$i';
            if (!targetIps.contains(ip)) {
              targetIps.add(ip);
            }
          }

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

          Future<void> worker() async {
            while (currentTaskIndex < tasks.length && !controller.isClosed) {
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
                controller.add(baseServer);

                // Fetch HTML title asynchronously without blocking the worker pool
                fetchHtmlTitle(task.ip, task.port).then((title) {
                  if (title != null && !controller.isClosed) {
                    controller.add(baseServer.copyWith(pageTitle: title));
                  }
                }).catchError((_) {});
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
            onProgress?.call(1.0, '$subnetPrefix.$myHostNumber');
            await controller.close();
          }
        } catch (_) {
          if (!controller.isClosed) {
            await controller.close();
          }
        }
      },
    );

    return controller.stream;
  }
}
