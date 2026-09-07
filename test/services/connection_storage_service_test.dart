import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dev_mirror/models/server_connection.dart';
import 'package:dev_mirror/services/connection_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectionStorageService Tests', () {
    late ConnectionStorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = await ConnectionStorageService.init();
    });

    test('Initial connection list is empty and last used is null', () {
      expect(storageService.getConnections(), isEmpty);
      expect(storageService.getLastUsedConnection(), isNull);
    });

    test('Saving connection adds to list and sets as last used', () async {
      final conn = ServerConnection(
        id: '192.168.1.5_3000',
        label: 'Node Server',
        ip: '192.168.1.5',
        port: 3000,
        lastUsedAt: DateTime.now(),
      );

      await storageService.saveConnection(conn);

      final list = storageService.getConnections();
      expect(list.length, 1);
      expect(list.first.id, conn.id);
      expect(list.first.label, 'Node Server');

      final lastUsed = storageService.getLastUsedConnection();
      expect(lastUsed, isNotNull);
      expect(lastUsed!.id, conn.id);
    });

    test('Deleting connection removes it from list and updates last used', () async {
      final conn1 = ServerConnection(
        id: 'conn1',
        label: 'First',
        ip: '192.168.1.10',
        port: 3000,
        lastUsedAt: DateTime.now(),
      );
      final conn2 = ServerConnection(
        id: 'conn2',
        label: 'Second',
        ip: '192.168.1.20',
        port: 5173,
        lastUsedAt: DateTime.now(),
      );

      await storageService.saveConnection(conn1);
      await storageService.saveConnection(conn2);

      expect(storageService.getConnections().length, 2);

      await storageService.deleteConnection('conn2');
      final remaining = storageService.getConnections();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'conn1');
    });

    test('ThemeMode persistence works correctly', () async {
      expect(storageService.getThemeMode(), ThemeMode.system);

      await storageService.setThemeMode(ThemeMode.dark);
      expect(storageService.getThemeMode(), ThemeMode.dark);

      await storageService.setThemeMode(ThemeMode.light);
      expect(storageService.getThemeMode(), ThemeMode.light);
    });
  });
}
