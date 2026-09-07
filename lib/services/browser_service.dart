import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../models/server_connection.dart';
import '../screens/webview_screen.dart';
import '../theme/app_theme.dart';

class BrowserService {
  /// Ensures valid HTTP URL with trailing slash for host:port roots
  static Uri formatTargetUri(String rawUrl) {
    String formatted = rawUrl.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    final uri = Uri.parse(formatted);
    // Ensure path has at least '/' for host roots so browsers parse properly
    if (uri.path.isEmpty) {
      return uri.replace(path: '/');
    }
    return uri;
  }

  /// Opens a URL using the best available browser method:
  /// 1. Native Chrome Custom Tabs (in-app external browser)
  /// 2. url_launcher externalApplication (opens in installed Chrome/browser)
  /// 3. In-App WebView fallback
  static Future<void> openInAppBrowser(
    BuildContext context, {
    required ServerConnection connection,
    required bool isDark,
  }) async {
    final uri = formatTargetUri(connection.url);
    final themeColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;

    bool openedSuccessfully = false;

    // 1. Try Custom Tabs (In-app Chrome Custom Tab)
    try {
      await custom_tabs.launchUrl(
        uri,
        customTabsOptions: custom_tabs.CustomTabsOptions(
          colorSchemes: custom_tabs.CustomTabsColorSchemes.defaults(
            toolbarColor: themeColor,
            navigationBarColor: themeColor,
          ),
          shareState: custom_tabs.CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,
          closeButton: custom_tabs.CustomTabsCloseButton(
            icon: custom_tabs.CustomTabsCloseButtonIcons.back,
          ),
        ),
      );
      openedSuccessfully = true;
    } catch (_) {
      openedSuccessfully = false;
    }

    if (openedSuccessfully) return;

    // 2. Try url_launcher in-app browser view or external application
    try {
      if (await launcher.canLaunchUrl(uri)) {
        final launched = await launcher.launchUrl(
          uri,
          mode: launcher.LaunchMode.inAppBrowserView,
        );
        if (launched) return;

        final launchedExt = await launcher.launchUrl(
          uri,
          mode: launcher.LaunchMode.externalApplication,
        );
        if (launchedExt) return;
      }
    } catch (_) {}

    // 3. Fallback: Built-in WebView Screen
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WebViewScreen(connection: connection),
        ),
      );
    }
  }
}
