import 'package:flutter_test/flutter_test.dart';
import 'package:dev_mirror/services/reachability_service.dart';

void main() {
  group('ReachabilityService Validator Tests', () {
    test('isValidIPv4 correctly validates valid IPv4 addresses', () {
      expect(ReachabilityService.isValidIPv4('192.168.1.1'), isTrue);
      expect(ReachabilityService.isValidIPv4('10.0.0.1'), isTrue);
      expect(ReachabilityService.isValidIPv4('127.0.0.1'), isTrue);
      expect(ReachabilityService.isValidIPv4('172.16.0.100'), isTrue);
      expect(ReachabilityService.isValidIPv4('0.0.0.0'), isTrue);
      expect(ReachabilityService.isValidIPv4('255.255.255.255'), isTrue);
    });

    test('isValidIPv4 correctly rejects invalid IPv4 addresses', () {
      expect(ReachabilityService.isValidIPv4(''), isFalse);
      expect(ReachabilityService.isValidIPv4('192.168.1'), isFalse);
      expect(ReachabilityService.isValidIPv4('192.168.1.256'), isFalse);
      expect(ReachabilityService.isValidIPv4('192.168.1.1.1'), isFalse);
      expect(ReachabilityService.isValidIPv4('abc.def.ghi.jkl'), isFalse);
      expect(ReachabilityService.isValidIPv4('192.168.1.-1'), isFalse);
      expect(ReachabilityService.isValidIPv4('http://192.168.1.1'), isFalse);
    });

    test('isValidPort correctly validates port range (1 - 65535)', () {
      expect(ReachabilityService.isValidPort('1'), isTrue);
      expect(ReachabilityService.isValidPort('80'), isTrue);
      expect(ReachabilityService.isValidPort('3000'), isTrue);
      expect(ReachabilityService.isValidPort('5173'), isTrue);
      expect(ReachabilityService.isValidPort('8080'), isTrue);
      expect(ReachabilityService.isValidPort('65535'), isTrue);

      expect(ReachabilityService.isValidPort('0'), isFalse);
      expect(ReachabilityService.isValidPort('65536'), isFalse);
      expect(ReachabilityService.isValidPort('-10'), isFalse);
      expect(ReachabilityService.isValidPort('abc'), isFalse);
      expect(ReachabilityService.isValidPort(''), isFalse);
    });

    test('checkReachability rejects invalid IP immediately with descriptive failure', () async {
      final result = await ReachabilityService.checkReachability('999.999.999.999', 3000);
      expect(result.isReachable, isFalse);
      expect(result.errorMessage, contains('Invalid IPv4 address format'));
    });

    test('checkReachability rejects invalid port immediately with descriptive failure', () async {
      final result = await ReachabilityService.checkReachability('192.168.1.1', 99999);
      expect(result.isReachable, isFalse);
      expect(result.errorMessage, contains('Port must be between 1 and 65535'));
    });
  });
}
