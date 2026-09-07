import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;
    final mutedFg = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Connect'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        children: [
          // ── OPTION 1: WIRELESS (RECOMMENDED) ──
          _buildMethodCard(
            context,
            isDark: isDark,
            fg: fg,
            mutedFg: mutedFg,
            cardBg: cardBg,
            borderColor: borderColor,
            tag: 'RECOMMENDED',
            tagColor: AppTheme.liveGreen,
            title: '1. Wireless (Same Wi-Fi)',
            subtitle: 'Auto-detected with zero manual setup',
            steps: [
              _buildStep(
                '1',
                'Connect Phone & PC to the Same Wi-Fi',
                'Ensure both devices are on the same local network.',
                isDark,
              ),
              _buildStep(
                '2',
                'Start your dev server with --host flag',
                'Ensure the dev server is accessible to local devices:',
                isDark,
                codeSnippets: [
                  {'label': 'Live Server (VS Code)', 'cmd': 'Click "Go Live" (works automatically)'},
                  {'label': 'Vite (React / Vue)', 'cmd': 'npx vite --host'},
                  {'label': 'Next.js', 'cmd': 'npm run dev -- -H 0.0.0.0'},
                  {'label': 'Django / Python', 'cmd': 'python manage.py runserver 0.0.0.0:8000'},
                ],
              ),
              _buildStep(
                '3',
                'Open DevMirror',
                'Your server will appear in "LIVE SERVERS" automatically. Just tap ">" to open!',
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── OPTION 2: USB CABLE ──
          _buildMethodCard(
            context,
            isDark: isDark,
            fg: fg,
            mutedFg: mutedFg,
            cardBg: cardBg,
            borderColor: borderColor,
            tag: 'ZERO IP NEEDED',
            tagColor: fg,
            title: '2. USB Cable (ADB Reverse)',
            subtitle: 'Ultra-fast & works without Wi-Fi',
            steps: [
              _buildStep(
                '1',
                'Connect phone to PC via USB',
                'Enable USB Debugging in Developer Options on your phone.',
                isDark,
              ),
              _buildStep(
                '2',
                'Run ADB reverse in PC terminal',
                'Forward your dev server port to your phone:',
                isDark,
                codeSnippets: [
                  {'label': 'Live Server (port 5500)', 'cmd': 'adb reverse tcp:5500 tcp:5500'},
                  {'label': 'Vite (port 5173)', 'cmd': 'adb reverse tcp:5173 tcp:5173'},
                  {'label': 'Next.js (port 3000)', 'cmd': 'adb reverse tcp:3000 tcp:3000'},
                ],
              ),
              _buildStep(
                '3',
                'In DevMirror Manual Connect',
                'Enter IP "127.0.0.1" and your port number -> Tap ">".',
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── OPTION 3: MANUAL IP LOOKUP ──
          _buildMethodCard(
            context,
            isDark: isDark,
            fg: fg,
            mutedFg: mutedFg,
            cardBg: cardBg,
            borderColor: borderColor,
            tag: 'MANUAL',
            tagColor: mutedFg,
            title: '3. Find PC IP Manually',
            subtitle: 'If auto-discovery is blocked by your router',
            steps: [
              _buildStep(
                '1',
                'Find your computer IP',
                'Open terminal on your PC and check your local IPv4 address:',
                isDark,
                codeSnippets: [
                  {'label': 'Windows (PowerShell / CMD)', 'cmd': 'ipconfig'},
                  {'label': 'Mac / Linux (Terminal)', 'cmd': 'ifconfig  or  ip a'},
                ],
              ),
              _buildStep(
                '2',
                'Look for your IPv4 Address',
                'Usually looks like 192.168.1.XX or 10.X.X.X.',
                isDark,
              ),
              _buildStep(
                '3',
                'Enter IP & Port in DevMirror',
                'Type your PC IP and Port into the manual input -> Tap ">".',
                isDark,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── FEEDBACK / SUGGESTIONS CARD ──
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF00FF66).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF66).withValues(alpha: 0.08),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF66).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00FF66),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'FEEDBACK',
                            style: TextStyle(
                              color: Color(0xFF00FF66),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Feedback & Suggestions',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'We would love to hear from you! Send us your ideas, bug reports, or suggestions at:',
                  style: TextStyle(fontSize: 12, color: mutedFg, height: 1.3),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'redropecompany@gmail.com',
                          style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: fg,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Copy Email',
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: 'redropecompany@gmail.com'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text('Email copied to clipboard: redropecompany@gmail.com'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required bool isDark,
    required Color fg,
    required Color mutedFg,
    required Color cardBg,
    required Color borderColor,
    required String tag,
    required Color tagColor,
    required String title,
    required String subtitle,
    required List<Widget> steps,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: tagColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: mutedFg,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...steps,
        ],
      ),
    );
  }

  Widget _buildStep(
    String stepNumber,
    String title,
    String description,
    bool isDark, {
    List<Map<String, String>>? codeSnippets,
  }) {
    final fg = isDark ? Colors.white : Colors.black;
    final mutedFg = isDark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
            child: Text(
              stepNumber,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.black : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedFg,
                    height: 1.3,
                  ),
                ),
                if (codeSnippets != null) ...[
                  const SizedBox(height: 8),
                  ...codeSnippets.map((item) {
                    return Builder(builder: (ctx) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF121212)
                                : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF27272A)
                                  : const Color(0xFFE4E4E7),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['label'] ?? '',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: mutedFg,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['cmd'] ?? '',
                                      style: TextStyle(
                                        fontFamily: AppTheme.monoFont,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: fg,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item['cmd'] != null &&
                                  !item['cmd']!.contains('automatically'))
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 15),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Copy command',
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: item['cmd']!));
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 1),
                                        content: Text('Copied: ${item['cmd']}'),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    });
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
