import 'package:flutter_test/flutter_test.dart';
import 'package:dev_mirror/services/terminal_parser.dart';

void main() {
  group('TerminalParser Tests', () {
    test('Parses Windows ipconfig output correctly', () {
      const ipconfigOutput = '''
Windows IP Configuration

Wireless LAN adapter Wi-Fi:
   Connection-specific DNS Suffix  . : home
   Link-local IPv6 Address . . . . . : fe80::1234:5678:abcd:ef01%12
   IPv4 Address. . . . . . . . . . . : 192.168.1.25
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . : 192.168.1.1
''';

      final result = TerminalParser.parse(ipconfigOutput);
      expect(result, isNotNull);
      expect(result!.ip, '192.168.1.25');
    });

    test('Parses Vite / Live Server dev URL correctly', () {
      const viteTerminalOutput = '''
  VITE v5.4.2  ready in 240 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: http://192.168.1.45:5173/
  ➜  press h + enter to show help
''';

      final result = TerminalParser.parse(viteTerminalOutput);
      expect(result, isNotNull);
      expect(result!.ip, '192.168.1.45');
      expect(result.port, 5173);
    });

    test('Parses Live Server URL correctly', () {
      const liveServerUrl = 'http://192.168.1.100:5500/index.html';
      final result = TerminalParser.parse(liveServerUrl);
      expect(result, isNotNull);
      expect(result!.ip, '192.168.1.100');
      expect(result.port, 5500);
    });

    test('Parses raw IP string', () {
      final result = TerminalParser.parse('192.168.0.88');
      expect(result, isNotNull);
      expect(result!.ip, '192.168.0.88');
    });

    test('Returns null for empty / invalid text without IPv4', () {
      expect(TerminalParser.parse(''), isNull);
      expect(TerminalParser.parse('Hello world this has no IP'), isNull);
    });
  });
}
