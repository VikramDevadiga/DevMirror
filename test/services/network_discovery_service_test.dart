import 'package:flutter_test/flutter_test.dart';
import 'package:dev_mirror/services/network_discovery_service.dart';

void main() {
  group('NetworkDiscoveryService interface selection', () {
    test('interfaceRank orders Wi-Fi, Ethernet, then tethering/hotspot', () {
      expect(NetworkDiscoveryService.interfaceRank('wlan0'), 0);
      expect(NetworkDiscoveryService.interfaceRank('eth0'), 1);
      expect(NetworkDiscoveryService.interfaceRank('rndis0'), 2);
      expect(NetworkDiscoveryService.interfaceRank('ncm0'), 2);
      expect(NetworkDiscoveryService.interfaceRank('ap0'), 2);
      expect(NetworkDiscoveryService.interfaceRank('swlan0'), 2);
    });

    test('interfaceRank excludes loopback, cellular and VPN interfaces', () {
      expect(NetworkDiscoveryService.interfaceRank('lo'), isNull);
      expect(NetworkDiscoveryService.interfaceRank('rmnet_data0'), isNull);
      expect(NetworkDiscoveryService.interfaceRank('v4-rmnet_data2'), isNull);
      expect(NetworkDiscoveryService.interfaceRank('ccmni1'), isNull);
      expect(NetworkDiscoveryService.interfaceRank('tun0'), isNull);
      expect(NetworkDiscoveryService.interfaceRank('dummy0'), isNull);
    });

    test('selectLanIps keeps Wi-Fi first when USB tethering is also active', () {
      final ips = NetworkDiscoveryService.selectLanIps({
        'rndis0': ['192.168.201.32'],
        'wlan0': ['192.168.10.82'],
        'rmnet_data0': ['10.45.12.7'],
        'lo': ['127.0.0.1'],
      });
      expect(ips, ['192.168.10.82', '192.168.201.32']);
    });

    test('selectLanIps only falls back to unknown interfaces when no LAN is known', () {
      expect(
        NetworkDiscoveryService.selectLanIps({
          'wlan0': ['192.168.1.20'],
          'oem_net0': ['172.20.0.5'],
        }),
        ['192.168.1.20'],
      );
      expect(
        NetworkDiscoveryService.selectLanIps({
          'oem_net0': ['172.20.0.5'],
          'rmnet_data0': ['10.45.12.7'],
        }),
        ['172.20.0.5'],
      );
    });

    test('selectLanIps ignores link-local addresses', () {
      expect(
        NetworkDiscoveryService.selectLanIps({
          'wlan0': ['169.254.10.4'],
        }),
        isEmpty,
      );
    });
  });

  group('NetworkDiscoveryService target ordering', () {
    test('buildTargetIps scans priority IPs, then near hosts of every subnet, then the rest', () {
      final targets = NetworkDiscoveryService.buildTargetIps(
        ['192.168.10.82', '192.168.201.32'],
        ['192.168.201.220'],
      );

      expect(targets.first, '192.168.201.220');
      expect(targets.sublist(1, 3), ['192.168.10.82', '192.168.10.1']);
      expect(targets.toSet().length, targets.length);
      expect(targets.length, 254 * 2);

      // Both subnets' gateways and neighbors come before either subnet's far hosts
      final farWifiHost = targets.indexOf('192.168.10.200');
      expect(targets.indexOf('192.168.201.1'), lessThan(farWifiHost));
      expect(targets.indexOf('192.168.201.60'), lessThan(farWifiHost));
      // The Wi-Fi remainder is scanned before the tethering remainder
      expect(farWifiHost, lessThan(targets.indexOf('192.168.201.200')));
    });

    test('buildTargetIps still scans priority IPs when no local network is found', () {
      expect(
        NetworkDiscoveryService.buildTargetIps([], ['', '10.0.0.5', '10.0.0.5']),
        ['10.0.0.5'],
      );
    });
  });
}
