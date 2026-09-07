import 'dart:async';
import 'dart:io';

class ReachabilityResult {
  final bool isReachable;
  final String? errorMessage;
  final String? tip;

  const ReachabilityResult.success()
      : isReachable = true,
        errorMessage = null,
        tip = null;

  const ReachabilityResult.failure(this.errorMessage, {this.tip})
      : isReachable = false;
}

class ReachabilityService {
  static const Duration defaultTimeout = Duration(seconds: 3);

  /// Validates if string is a valid IPv4 address
  static bool isValidIPv4(String ip) {
    final trimmed = ip.trim();
    if (trimmed.isEmpty) return false;

    // Direct parser check
    final addr = InternetAddress.tryParse(trimmed);
    if (addr != null && addr.type == InternetAddressType.IPv4) {
      return true;
    }

    // Strict 4 octet 0-255 regex check
    final regex = RegExp(
      r'^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.'
      r'(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.'
      r'(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.'
      r'(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$',
    );
    return regex.hasMatch(trimmed);
  }

  /// Validates port number (1 - 65535)
  static bool isValidPort(String portStr) {
    final port = int.tryParse(portStr.trim());
    return port != null && port >= 1 && port <= 65535;
  }

  /// Performs a fast TCP socket reachability check before loading WebView
  static Future<ReachabilityResult> checkReachability(
    String ip,
    int port, {
    Duration timeout = defaultTimeout,
  }) async {
    final trimmedIp = ip.trim();

    if (!isValidIPv4(trimmedIp) && trimmedIp != 'localhost') {
      return const ReachabilityResult.failure(
        'Invalid IPv4 address format.',
        tip: 'Example: 192.168.1.15',
      );
    }

    if (port < 1 || port > 65535) {
      return const ReachabilityResult.failure(
        'Port must be between 1 and 65535.',
        tip: 'Common dev ports: 3000, 5173, 8080',
      );
    }

    try {
      final socket = await Socket.connect(
        trimmedIp,
        port,
        timeout: timeout,
      );
      socket.destroy();
      return const ReachabilityResult.success();
    } on TimeoutException {
      return const ReachabilityResult.failure(
        'Connection timed out (no response within 3s).',
        tip: 'Check that both your phone and PC are connected to the same Wi-Fi network and AP isolation is disabled.',
      );
    } on SocketException catch (e) {
      final message = e.message.toLowerCase();
      final osError = e.osError?.message.toLowerCase() ?? '';
      final errorCode = e.osError?.errorCode ?? 0;

      // Common connection refused codes: 111 (Linux), 61 (macOS/iOS), 10061 (Windows WSAECONNREFUSED)
      if (message.contains('connection refused') ||
          osError.contains('connection refused') ||
          errorCode == 111 ||
          errorCode == 61 ||
          errorCode == 10061) {
        return ReachabilityResult.failure(
          'Connection refused on port $port.',
          tip: 'Is your dev server running and listening on 0.0.0.0 (all interfaces)? For Vite/Next.js, try running with --host.',
        );
      }

      if (message.contains('no route to host') ||
          osError.contains('no route to host') ||
          message.contains('network is unreachable') ||
          osError.contains('network is unreachable') ||
          message.contains('host is down')) {
        return const ReachabilityResult.failure(
          'Host or network unreachable.',
          tip: 'Verify your PC IP address (ipconfig on Windows or ifconfig on Mac/Linux) and ensure your firewall allows inbound local traffic.',
        );
      }

      if (message.contains('failed host lookup') || message.contains('name or service not known')) {
        return const ReachabilityResult.failure(
          'Could not resolve host.',
          tip: 'Double check the IP address format (e.g. 192.168.x.x).',
        );
      }

      return ReachabilityResult.failure(
        'Unable to connect: ${e.message}',
        tip: 'Verify that your dev server is running and accessible on the local network.',
      );
    } catch (e) {
      return ReachabilityResult.failure(
        'Unexpected connection error: $e',
        tip: 'Please check your network settings and try again.',
      );
    }
  }
}
