import 'package:flutter_test/flutter_test.dart';
import 'package:dev_mirror/models/server_connection.dart';

void main() {
  group('ServerConnection Model Tests', () {
    test('Correctly serializes to and from JSON', () {
      final now = DateTime.now();
      final connection = ServerConnection(
        id: '192.168.1.10_3000',
        label: 'React Frontend',
        ip: '192.168.1.10',
        port: 3000,
        lastUsedAt: now,
        isFavorite: true,
      );

      final json = connection.toJson();
      expect(json['id'], '192.168.1.10_3000');
      expect(json['label'], 'React Frontend');
      expect(json['ip'], '192.168.1.10');
      expect(json['port'], 3000);
      expect(json['isFavorite'], true);

      final deserialized = ServerConnection.fromJson(json);
      expect(deserialized.id, connection.id);
      expect(deserialized.label, connection.label);
      expect(deserialized.ip, connection.ip);
      expect(deserialized.port, connection.port);
      expect(deserialized.isFavorite, connection.isFavorite);
      expect(deserialized.url, 'http://192.168.1.10:3000');
      expect(deserialized.address, '192.168.1.10:3000');
    });

    test('copyWith properly updates specified fields', () {
      final connection = ServerConnection(
        id: '1',
        label: 'Old Label',
        ip: '192.168.1.5',
        port: 5173,
        lastUsedAt: DateTime.now(),
      );

      final updated = connection.copyWith(
        label: 'Vite Next',
        port: 8080,
      );

      expect(updated.label, 'Vite Next');
      expect(updated.port, 8080);
      expect(updated.ip, '192.168.1.5');
      expect(updated.url, 'http://192.168.1.5:8080');
    });
  });
}
