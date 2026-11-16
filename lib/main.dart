import 'package:flutter/material.dart';
import 'screens/connect_screen.dart';
import 'screens/onboarding_screen.dart';
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
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.storageService.getThemeMode();
    _showOnboarding = !widget.storageService.hasCompletedOnboarding();
  }

  void _completeOnboarding() {
    setState(() {
      _showOnboarding = false;
    });
    widget.storageService.setOnboardingCompleted();
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
      // First launch shows the tour; the connect screen (and its network
      // scan) only starts once the tour is finished or skipped.
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _showOnboarding
            ? OnboardingScreen(
                key: const ValueKey('onboarding'),
                onFinish: _completeOnboarding,
              )
            : ConnectScreen(
                key: const ValueKey('connect'),
                storageService: widget.storageService,
                onThemeModeChanged: _updateThemeMode,
                currentThemeMode: _themeMode,
              ),
      ),
    );
  }
}
