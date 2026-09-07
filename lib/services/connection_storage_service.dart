import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_connection.dart';

class ConnectionStorageService {
  static const String _connectionsKey = 'devmirror_saved_connections';
  static const String _lastUsedKey = 'devmirror_last_used_connection';
  static const String _themeModeKey = 'devmirror_theme_mode';

  final SharedPreferences _prefs;

  ConnectionStorageService(this._prefs);

  static Future<ConnectionStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return ConnectionStorageService(prefs);
  }

  List<ServerConnection> getConnections() {
    final rawList = _prefs.getStringList(_connectionsKey);
    if (rawList == null || rawList.isEmpty) {
      return [];
    }

    try {
      final list = rawList
          .map((item) => ServerConnection.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();

      // Sort: favorites first, then by lastUsedAt descending
      list.sort((a, b) {
        if (a.isFavorite != b.isFavorite) {
          return a.isFavorite ? -1 : 1;
        }
        return b.lastUsedAt.compareTo(a.lastUsedAt);
      });
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveConnection(ServerConnection connection) async {
    final currentList = getConnections();
    final index = currentList.indexWhere(
      (c) => c.id == connection.id || (c.ip == connection.ip && c.port == connection.port),
    );

    if (index >= 0) {
      // Retain custom label if new label is empty
      final existing = currentList[index];
      final updatedLabel = connection.label.trim().isEmpty ? existing.label : connection.label;
      currentList[index] = connection.copyWith(
        id: existing.id,
        label: updatedLabel,
        isFavorite: existing.isFavorite,
        lastUsedAt: DateTime.now(),
      );
    } else {
      currentList.insert(0, connection.copyWith(lastUsedAt: DateTime.now()));
    }

    final rawList = currentList.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_connectionsKey, rawList);
    await setLastUsedConnection(connection);
  }

  Future<void> updateConnection(ServerConnection connection) async {
    final currentList = getConnections();
    final index = currentList.indexWhere((c) => c.id == connection.id);

    if (index >= 0) {
      currentList[index] = connection;
      final rawList = currentList.map((c) => jsonEncode(c.toJson())).toList();
      await _prefs.setStringList(_connectionsKey, rawList);
    }
  }

  Future<void> deleteConnection(String id) async {
    final currentList = getConnections();
    currentList.removeWhere((c) => c.id == id);
    final rawList = currentList.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_connectionsKey, rawList);

    final lastUsed = getLastUsedConnection();
    if (lastUsed?.id == id) {
      if (currentList.isNotEmpty) {
        await setLastUsedConnection(currentList.first);
      } else {
        await _prefs.remove(_lastUsedKey);
      }
    }
  }

  ServerConnection? getLastUsedConnection() {
    final raw = _prefs.getString(_lastUsedKey);
    if (raw == null || raw.isEmpty) {
      final connections = getConnections();
      return connections.isNotEmpty ? connections.first : null;
    }

    try {
      return ServerConnection.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setLastUsedConnection(ServerConnection connection) async {
    await _prefs.setString(_lastUsedKey, jsonEncode(connection.toJson()));
  }

  ThemeMode getThemeMode() {
    final modeStr = _prefs.getString(_themeModeKey);
    if (modeStr == 'light') return ThemeMode.light;
    if (modeStr == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.light) {
      await _prefs.setString(_themeModeKey, 'light');
    } else if (mode == ThemeMode.dark) {
      await _prefs.setString(_themeModeKey, 'dark');
    } else {
      await _prefs.remove(_themeModeKey);
    }
  }
}
