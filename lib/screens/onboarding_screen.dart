import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Terminal palette (stays dark in both themes, matching ScanTerminal) ──
const Color _termBg = Color(0xFF09090B);
const Color _termChrome = Color(0xFF141416);
const Color _termText = Color(0xFFE4E4E7);
const Color _termMuted = Color(0xFFA1A1AA);
const Color _termDim = Color(0xFF71717A);
const Color _termFaint = Color(0xFF52525B);

/// First-run tour: what DevMirror is, how to expose a dev server, and how to
/// connect to it. Can be replayed later from the "How to Connect" screen.
class OnboardingScreen extends StatefulWidget {
  /// Called once, when the user finishes or skips the tour
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const int _pageCount = 5;

  final PageController _pageController = PageController();
  int _page = 0;
  bool _finished = false;

  // Drives the ambient motion in the illustrations (signal dots, tap ripple)
  late final AnimationController _signal;

  @override
  void initState() {
    super.initState();
    _signal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the system "remove animations" setting
    if (MediaQuery.disableAnimationsOf(context)) {
      _signal.stop();
      _signal.value = 0.3;
    } else if (!_signal.isAnimating) {
      _signal.repeat();
    }
  }

  @override
  void dispose() {
    _signal.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _goTo(_page + 1);
    } else {
      _finish();
    }
  }

  void _finish() {
    // The screen stays tappable during its exit transition; a second call
    // would pop the route underneath when the tour was opened from Help.
    if (_finished) return;
    _finished = true;
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _Palette.of(context);
    final isLast = _page == _pageCount - 1;

    final pages = [
      _buildWelcomePage(colors),
      _buildHostPage(colors),
      _buildDiscoverPage(colors),
      _buildFallbackPage(colors),
      _buildReadyPage(colors),
    ];
    assert(pages.length == _pageCount);

    return PopScope(
      // System back steps through the pages before leaving the tour
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  _buildTopBar(colors, isLast),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (page) => setState(() => _page = page),
                      children: pages,
                    ),
                  ),
                  _buildBottomBar(isLast, colors),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Chrome: progress + skip, back + next ──

  Widget _buildTopBar(_Palette colors, bool isLast) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Page ${_page + 1} of $_pageCount',
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    for (int i = 0; i < _pageCount; i++)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          height: 3,
                          margin: EdgeInsets.only(
                              right: i < _pageCount - 1 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: i <= _page ? colors.fg : colors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Keeps its space on the last page so the progress bar doesn't jump
          Visibility(
            visible: !isLast,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: TextButton(
              key: const ValueKey('onboarding-skip'),
              onPressed: _finish,
              style: TextButton.styleFrom(foregroundColor: colors.muted),
              child: const Text(
                'Skip',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isLast, _Palette colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          if (_page > 0) ...[
            OutlinedButton(
              key: const ValueKey('onboarding-back'),
              onPressed: () => _goTo(_page - 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.fg,
                minimumSize: const Size(0, 50),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                side: BorderSide(color: colors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: ElevatedButton(
              key: const ValueKey('onboarding-next'),
              onPressed: _next,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 50)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      isLast ? 'Get started' : 'Next',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shared page layout: illustration, eyebrow, title, body, extra content.
  /// Scrolls instead of overflowing on short screens or with large text.
  Widget _buildPage({
    required _Palette colors,
    Widget? hero,
    required String eyebrow,
    required String title,
    required String body,
    Widget? details,
  }) {
    const padding = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  math.max(0, constraints.maxHeight - padding.vertical),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hero != null) ...[
                  hero,
                  const SizedBox(height: 32),
                ],
                Text(
                  eyebrow,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.15,
                    color: colors.fg,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: colors.muted,
                  ),
                ),
                if (details != null) ...[
                  const SizedBox(height: 20),
                  details,
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Page 1: what DevMirror is ──

  Widget _buildWelcomePage(_Palette colors) {
    const logoSize = 72.0;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return _buildPage(
      colors: colors,
      hero: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/logo.png',
              width: logoSize,
              height: logoSize,
              cacheWidth: (logoSize * dpr).round(),
              semanticLabel: 'DevMirror logo',
            ),
          ),
          const SizedBox(height: 24),
          _DeviceLinkDiagram(signal: _signal, colors: colors),
        ],
      ),
      eyebrow: 'WELCOME TO DEVMIRROR',
      title: 'Your localhost, on your phone',
      body: 'DevMirror finds the dev server running on your computer and '
          'opens it on your phone, so you can test your site on a real '
          'mobile screen while you build it. No more hunting for IP '
          'addresses.',
    );
  }

  // ── Page 2: expose the dev server on the network ──

  Widget _buildHostPage(_Palette colors) {
    return _buildPage(
      colors: colors,
      hero: const _TerminalCard(
        title: 'terminal — your computer',
        lines: [
          _TermLine.comment('Vite (React, Vue, Svelte)'),
          _TermLine.command('npx vite --host'),
          _TermLine.comment('Next.js'),
          _TermLine.command('npm run dev -- -H 0.0.0.0'),
          _TermLine.comment('Django'),
          _TermLine.command('python manage.py runserver 0.0.0.0:8000'),
          _TermLine.comment('Live Server (VS Code)'),
          _TermLine('  ', 'Click "Go Live" — works as is', textColor: _termMuted),
        ],
      ),
      eyebrow: 'STEP 1 · ON YOUR COMPUTER',
      title: 'Start your dev server on the network',
      body: 'Most dev servers only listen on localhost, which your phone '
          "can't reach. Add the host option shown above so other devices "
          'on your network can open it.',
      details: _TipCard(
        icon: Icons.wifi_rounded,
        text: 'Keep your phone and computer on the same Wi-Fi. A phone '
            'hotspot or USB tethering works too.',
        colors: colors,
      ),
    );
  }

  // ── Page 3: auto-discovery and tap to open ──

  Widget _buildDiscoverPage(_Palette colors) {
    return _buildPage(
      colors: colors,
      hero: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _TerminalCard(
            title: 'devmirror — port scan',
            status: '1 found',
            lines: [
              _TermLine.command('devmirror scan --lan'),
              _TermLine('INFO  ', 'local ip 192.168.1.23/24',
                  prefixColor: _termText, textColor: _termMuted),
              _TermLine('OPEN  ', '192.168.1.5:5173  Vite App',
                  prefixColor: AppTheme.liveGreen, bold: true),
              _TermLine('TITLE ', ':5173 -> "My Portfolio"',
                  prefixColor: AppTheme.liveGreen, textColor: _termMuted),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.liveGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE SERVERS (1)',
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: colors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MockServerCard(signal: _signal, colors: colors),
        ],
      ),
      eyebrow: 'STEP 2 · ON YOUR PHONE',
      title: 'Tap the server DevMirror finds',
      body: 'DevMirror scans every network your phone is on for common dev '
          'ports like 3000, 5173, 5500 and 8080. Servers it finds appear '
          'under LIVE SERVERS with their page title. Tap one to open it in '
          'the in-app browser.',
      details: _TipCard(
        icon: Icons.history_rounded,
        text: 'Servers you open are saved under RECENT SERVERS for one-tap '
            'reconnects. Swipe one left to remove it.',
        colors: colors,
      ),
    );
  }

  // ── Page 4: what to do when nothing shows up ──

  Widget _buildFallbackPage(_Palette colors) {
    return _buildPage(
      colors: colors,
      eyebrow: 'NOT SHOWING UP?',
      title: 'Other ways to connect',
      body: 'Office and public Wi-Fi often stop devices from seeing each '
          'other, and firewalls can block your server. Try one of these:',
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OptionCard(
            icon: Icons.keyboard_alt_outlined,
            title: 'Enter the IP yourself',
            text: "Find your computer's IPv4 address with ipconfig (Windows) "
                'or ifconfig (Mac/Linux), then type it with the port under '
                'MANUAL IP & PORT.',
            colors: colors,
          ),
          const SizedBox(height: 10),
          _OptionCard(
            icon: Icons.usb_rounded,
            title: 'Connect over USB',
            text: 'With USB debugging on, run this on your computer, then '
                'connect to 127.0.0.1 and the same port:',
            code: 'adb reverse tcp:5173 tcp:5173',
            colors: colors,
          ),
          const SizedBox(height: 10),
          _OptionCard(
            icon: Icons.shield_outlined,
            title: 'Check your firewall',
            text: 'Allow your dev server (Node, Python…) through your '
                "computer's firewall on private networks.",
            colors: colors,
          ),
        ],
      ),
    );
  }

  // ── Page 5: demo + where things live on the home screen ──

  Widget _buildReadyPage(_Palette colors) {
    return _buildPage(
      colors: colors,
      hero: Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.fg,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 36, color: colors.onFg),
        ),
      ),
      eyebrow: "YOU'RE ALL SET",
      title: 'Ready when your server is',
      body: 'No server running right now? If the scan finds nothing, tap '
          'Try demo to open a built-in sample site and see how DevMirror '
          'works.',
      details: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ON THE HOME SCREEN',
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 10),
            _LegendRow(
              icon: Icons.refresh_rounded,
              text: 'Scan again (or pull down to refresh)',
              colors: colors,
            ),
            _LegendRow(
              icon: Icons.help_outline_rounded,
              text: 'Connection guides and this tour',
              colors: colors,
            ),
            _LegendRow(
              icon: colors.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              text: 'Switch between light and dark',
              colors: colors,
            ),
            _LegendRow(
              icon: Icons.chat_bubble_outline_rounded,
              text: 'Send feedback or report a bug',
              colors: colors,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Theme-aware colours, matching the rest of the app ──

class _Palette {
  final bool isDark;
  final Color fg;
  final Color onFg;
  final Color muted;
  final Color card;
  final Color surface;
  final Color border;

  const _Palette({
    required this.isDark,
    required this.fg,
    required this.onFg,
    required this.muted,
    required this.card,
    required this.surface,
    required this.border,
  });

  factory _Palette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _Palette(
      isDark: isDark,
      fg: isDark ? Colors.white : Colors.black,
      onFg: isDark ? Colors.black : Colors.white,
      muted: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
      card: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      surface: isDark ? AppTheme.darkSurface : Colors.white,
      border: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
    );
  }
}

// ── Illustrations ──

/// Computer ── signal ── phone, with dots travelling across the link
class _DeviceLinkDiagram extends StatelessWidget {
  final Animation<double> signal;
  final _Palette colors;

  const _DeviceLinkDiagram({required this.signal, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DeviceTile(
            icon: Icons.laptop_mac_rounded,
            label: 'Computer',
            caption: 'localhost:5173',
            colors: colors,
          ),
          Expanded(
            child: SizedBox(
              height: _DeviceTile.iconBoxSize,
              child: ExcludeSemantics(
                child: _SignalLine(signal: signal, colors: colors),
              ),
            ),
          ),
          _DeviceTile(
            icon: Icons.phone_android_rounded,
            label: 'Phone',
            caption: 'DevMirror',
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  static const double iconBoxSize = 52;

  final IconData icon;
  final String label;
  final String caption;
  final _Palette colors;

  const _DeviceTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: colors.fg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: colors.onFg),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 10.5,
              color: colors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalLine extends StatelessWidget {
  static const int _dotCount = 3;
  static const double _dotSize = 6;

  final Animation<double> signal;
  final _Palette colors;

  const _SignalLine({required this.signal, required this.colors});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final midY = constraints.maxHeight / 2;

        return AnimatedBuilder(
          animation: signal,
          builder: (context, _) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: midY - 1,
                  child: Container(height: 2, color: colors.border),
                ),
                for (int i = 0; i < _dotCount; i++)
                  _buildDot(((signal.value + i / _dotCount) % 1.0), width, midY),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(
                      Icons.wifi_rounded,
                      size: 15,
                      color: colors.muted,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDot(double t, double width, double midY) {
    return Positioned(
      left: t * math.max(0, width - _dotSize),
      top: midY - _dotSize / 2,
      child: Opacity(
        // Fade in and out at the ends of the line
        opacity: math.sin(t * math.pi).clamp(0.0, 1.0),
        child: Container(
          width: _dotSize,
          height: _dotSize,
          decoration: const BoxDecoration(
            color: AppTheme.liveGreen,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Mirrors the LIVE SERVERS card on the home screen, with a tap hint
class _MockServerCard extends StatelessWidget {
  final Animation<double> signal;
  final _Palette colors;

  const _MockServerCard({required this.signal, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Portfolio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: colors.fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '192.168.1.5:5173',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontSize: 12,
                    color: colors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Expanding ring that suggests a tap
                AnimatedBuilder(
                  animation: signal,
                  builder: (context, _) {
                    final t = signal.value;
                    return Transform.scale(
                      scale: 1 + t * 0.7,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colors.fg.withValues(alpha: 0.5 * (1 - t)),
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colors.fg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onFg,
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  right: -12,
                  bottom: -16,
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: 24,
                    color: colors.fg,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

/// One line in a mock terminal: a coloured prefix followed by text
class _TermLine {
  final String prefix;
  final String text;
  final Color prefixColor;
  final Color textColor;
  final bool bold;

  const _TermLine(
    this.prefix,
    this.text, {
    this.prefixColor = _termFaint,
    this.textColor = _termText,
    this.bold = false,
  });

  const _TermLine.comment(String text)
      : this('# ', text, prefixColor: _termFaint, textColor: _termDim);

  const _TermLine.command(String text)
      : this(r'$ ', text, prefixColor: AppTheme.liveGreen, bold: true);
}

/// Static terminal window, styled like the live ScanTerminal
class _TerminalCard extends StatelessWidget {
  final String title;
  final String? status;
  final List<_TermLine> lines;

  const _TerminalCard({required this.title, this.status, required this.lines});

  static const TextStyle _mono = TextStyle(
    fontFamily: AppTheme.monoFont,
    fontSize: 11.5,
    height: 1.45,
    color: _termText,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _termBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: _termChrome,
              border: Border(bottom: BorderSide(color: AppTheme.darkBorder)),
            ),
            child: Row(
              children: [
                for (int i = 0; i < 3; i++) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3F3F46),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _mono.copyWith(fontSize: 10.5, color: _termDim),
                  ),
                ),
                if (status != null)
                  Text(
                    status!,
                    style: _mono.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.liveGreen,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final line in lines)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: line.prefix,
                          style: TextStyle(
                            color: line.prefixColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: line.text,
                          style: TextStyle(
                            color: line.textColor,
                            fontWeight:
                                line.bold ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    style: _mono,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small building blocks ──

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final _Palette colors;

  const _TipCard({required this.icon, required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, height: 1.4, color: colors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? code;
  final _Palette colors;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.text,
    this.code,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.fg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: colors.onFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.fg,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: colors.muted,
                  ),
                ),
                if (code != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      code!,
                      style: TextStyle(
                        fontFamily: AppTheme.monoFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.fg,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final _Palette colors;

  const _LegendRow({required this.icon, required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Icon(icon, size: 17, color: colors.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.5, color: colors.fg),
            ),
          ),
        ],
      ),
    );
  }
}
