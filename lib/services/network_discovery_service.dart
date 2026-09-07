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

class NetworkDiscoveryService {
  static const List<int> commonPorts = [
    5500, // VS Code Live Server
    5501, // VS Code Live Server #2
    5173, // Vite
    5174, // Vite #2
    3000, // React / Next.js / Node
    3001, // React / Next.js #2
    8080, // Webpack / Vue / Spring
    8081, // Metro / React Native / Webpack
    8000, // Django / FastAPI / PHP
    4200, // Angular
    5000, // Flask / ASP.NET
    9000, // PHP-FPM / Webpack
    8888, // Jupyter / Local Web
  ];

  /// Finds the device's local Wi-Fi IPv4 address
  static Future<String?> getLocalDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

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

  /// Probes a single IP and port quickly via TCP socket
  static Future<bool> probeSocket(
    String ip,
    int port, {
    Duration timeout = const Duration(milliseconds: 300),
  }) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the HTML <title> from the dev server URL
  static Future<String?> fetchHtmlTitle(
    String ip,
    int port, {
    Duration timeout = const Duration(milliseconds: 1200),
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
      case 5500:
      case 5501:
        return 'Live Server';
      case 5173:
      case 5174:
        return 'Vite App';
      case 3000:
      case 3001:
        return 'React / Next.js';
      case 8080:
      case 8081:
        return 'Vue / Webpack';
      case 8000:
        return 'Django / Python';
      case 4200:
        return 'Angular App';
      case 5000:
        return 'Flask / Express';
      default:
        return 'Dev Server';
    }
  }

  /// Scans the local subnet for active dev servers
  static Stream<DiscoveredServer> scanSubnet({
    List<int> ports = commonPorts,
    void Function(double progress, String currentIp)? onProgress,
  }) async* {
    final localIp = await getLocalDeviceIp();
    if (localIp == null) return;

    final parts = localIp.split('.');
    if (parts.length != 4) return;

    final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
    final myHostNumber = int.tryParse(parts[3]) ?? 0;

    // Scan priority order: neighboring IPs around the device's IP, then .1 - .254
    final List<int> hostNumbers = [];

    // Check nearest neighbors first (+/- 30 from device IP)
    for (int offset = 1; offset <= 30; offset++) {
      if (myHostNumber - offset >= 1) hostNumbers.add(myHostNumber - offset);
      if (myHostNumber + offset <= 254) hostNumbers.add(myHostNumber + offset);
    }

    // Add remaining hosts in the subnet
    for (int i = 1; i <= 254; i++) {
      if (!hostNumbers.contains(i) && i != myHostNumber) {
        hostNumbers.add(i);
      }
    }

    // Scan in concurrent batches
    const int batchSize = 15;
    int scannedCount = 0;
    final int totalToScan = hostNumbers.length;

    for (int b = 0; b < hostNumbers.length; b += batchSize) {
      final batch = hostNumbers.sublist(
        b,
        (b + batchSize > hostNumbers.length) ? hostNumbers.length : b + batchSize,
      );

      final List<Future<DiscoveredServer?>> futures = [];

      for (final host in batch) {
        final targetIp = '$subnetPrefix.$host';

        for (final port in ports) {
          futures.add(
            probeSocket(targetIp, port).then((isOpen) async {
              if (isOpen) {
                // Port is open! Try fetching real HTML title
                final title = await fetchHtmlTitle(targetIp, port);
                return DiscoveredServer(
                  ip: targetIp,
                  port: port,
                  serverType: _identifyServer(port),
                  pageTitle: title,
                );
              }
              return null;
            }),
          );
        }
      }

      final results = await Future.wait(futures);
      scannedCount += batch.length;
      onProgress?.call(scannedCount / totalToScan, '$subnetPrefix.${batch.last}');

      for (final res in results) {
        if (res != null) {
          yield res;
        }
      }
    }
  }
}
