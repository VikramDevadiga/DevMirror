class ParsedTarget {
  final String ip;
  final int? port;
  final String? label;

  const ParsedTarget({
    required this.ip,
    this.port,
    this.label,
  });

  @override
  String toString() => 'ParsedTarget(ip: $ip, port: $port, label: $label)';
}

class TerminalParser {
  // Regex for full URL (e.g. http://192.168.1.15:5173/path)
  static final RegExp _urlRegex = RegExp(
    r'https?://([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|localhost)(?::([0-9]{1,5}))?',
    caseSensitive: false,
  );

  // Regex for ipconfig (Windows: IPv4 Address. . . : 192.168.1.15)
  static final RegExp _windowsIpconfigRegex = RegExp(
    r'IPv4\s+Address[.\s:]+([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})',
    caseSensitive: false,
  );

  // Regex for ifconfig / ip addr (Mac / Linux: inet 192.168.1.15)
  static final RegExp _unixIpRegex = RegExp(
    r'inet\s+(?:addr:)?([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})',
    caseSensitive: false,
  );

  // Generic IPv4 regex
  static final RegExp _genericIpv4Regex = RegExp(
    r'\b(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.'
    r'(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.'
    r'(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.'
    r'(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\b',
  );

  // Generic port pattern (:3000, port 5173, etc.)
  static final RegExp _portRegex = RegExp(
    r'(?::|port\s+|:)([0-9]{2,5})\b',
    caseSensitive: false,
  );

  /// Parses any terminal text, ipconfig output, or QR code content
  static ParsedTarget? parse(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return null;

    // 1. Try URL matches (e.g. http://192.168.1.15:5173 or http://localhost:5173)
    final urlMatches = _urlRegex.allMatches(text).toList();
    if (urlMatches.isNotEmpty) {
      // Prioritize non-localhost / private IP addresses first
      RegExpMatch chosenMatch = urlMatches.first;
      for (final match in urlMatches) {
        final host = match.group(1)!;
        if (host != 'localhost' && host != '127.0.0.1') {
          chosenMatch = match;
          break;
        }
      }

      final ip = chosenMatch.group(1)!;
      final portStr = chosenMatch.group(2);
      final port = portStr != null ? int.tryParse(portStr) : null;
      return ParsedTarget(
        ip: ip,
        port: (port != null && port >= 1 && port <= 65535) ? port : null,
        label: 'Dev Server URL',
      );
    }

    // 2. Try Windows ipconfig match (IPv4 Address . . . : 192.168.1.15)
    final ipconfigMatch = _windowsIpconfigRegex.firstMatch(text);
    if (ipconfigMatch != null) {
      final ip = ipconfigMatch.group(1)!;
      if (_isValidUsableIp(ip)) {
        final port = _extractPort(text);
        return ParsedTarget(ip: ip, port: port, label: 'ipconfig Output');
      }
    }

    // 3. Try Linux/Mac ifconfig match (inet 192.168.1.15)
    final unixMatch = _unixIpRegex.firstMatch(text);
    if (unixMatch != null) {
      final ip = unixMatch.group(1)!;
      if (_isValidUsableIp(ip)) {
        final port = _extractPort(text);
        return ParsedTarget(ip: ip, port: port, label: 'ifconfig Output');
      }
    }

    // 4. Scan all IPv4 addresses in text and pick the most probable local network IP
    final matches = _genericIpv4Regex.allMatches(text).map((m) => m.group(0)!).toList();
    if (matches.isNotEmpty) {
      // Prioritize private network IPs: 192.168.x.x, 10.x.x.x, 172.16-31.x.x
      String? chosenIp;
      for (final ip in matches) {
        if (ip.startsWith('192.168.') && !ip.endsWith('.1') && !ip.endsWith('.255')) {
          chosenIp = ip;
          break;
        }
      }

      chosenIp ??= matches.firstWhere(
        (ip) => _isValidUsableIp(ip) && ip != '127.0.0.1' && ip != '0.0.0.0',
        orElse: () => matches.first,
      );

      final port = _extractPort(text);
      return ParsedTarget(ip: chosenIp, port: port, label: 'Detected IP');
    }

    return null;
  }

  static int? _extractPort(String text) {
    final match = _portRegex.firstMatch(text);
    if (match != null) {
      final p = int.tryParse(match.group(1)!);
      if (p != null && p >= 1 && p <= 65535) {
        return p;
      }
    }
    return null;
  }

  static bool _isValidUsableIp(String ip) {
    if (ip == '0.0.0.0' || ip == '255.255.255.255') return false;
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null || p < 0 || p > 255)) {
      return false;
    }
    return true;
  }
}
