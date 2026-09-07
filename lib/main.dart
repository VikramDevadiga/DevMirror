import 'package:flutter/material.dart';
import 'screens/connect_screen.dart';
import 'services/connection_storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await ConnectionStorageService.init();
  runApp(DevMirrorApp(storageService: storageService));
}

class DevMirrorApp extends StatefulWidget {
  final ConnectionStorageService storageService;

  const DevMirrorApp({
    super.key,
    required this.storageService,
  });

  @override
  State<DevMirrorApp> createState() => _DevMirrorAppState();
}

class _DevMirrorAppState extends State<DevMirrorApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.storageService.getThemeMode();
  }

  void _updateThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    widget.storageService.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevMirror',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: ConnectScreen(
        storageService: widget.storageService,
        onThemeModeChanged: _updateThemeMode,
        currentThemeMode: _themeMode,
      ),
    );
  }
}
