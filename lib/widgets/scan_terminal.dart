import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/network_discovery_service.dart';
import '../theme/app_theme.dart';

// ── Terminal palette (stays dark in both themes, like a real shell window) ──
const Color _termBg = Color(0xFF09090B);
const Color _termChrome = Color(0xFF141416);
const Color _termText = Color(0xFFE4E4E7);
const Color _termMuted = Color(0xFFA1A1AA);
const Color _termDim = Color(0xFF71717A);
const Color _termFaint = Color(0xFF52525B);
const Color _termAmber = Color(0xFFF59E0B);

const TextStyle _termMono = TextStyle(
  fontFamily: AppTheme.monoFont,
  fontSize: 11,
  height: 1.3,
  color: _termText,
);

/// Live, terminal-style log of the LAN port scan
class ScanTerminal extends StatefulWidget {
  final ValueListenable<List<ScanLogEntry>> logs;
  final ValueListenable<double> progress;
  final bool isScanning;
  final int foundCount;

  const ScanTerminal({
    super.key,
    required this.logs,
    required this.progress,
    required this.isScanning,
    required this.foundCount,
  });

  @override
  State<ScanTerminal> createState() => _ScanTerminalState();
}

class _ScanTerminalState extends State<ScanTerminal>
    with SingleTickerProviderStateMixin {
  static const int _visibleLines = 7;
  static const double _lineHeight = 17;
  static const int _barWidth = 16;
  static const List<String> _spinnerFrames = ['|', '/', '-', r'\'];

  // Drives the spinner (8 frames/s) and the cursor blink (1 Hz)
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lines have a fixed height, so cap font scaling to keep them from clipping
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _termBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTitleBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: _visibleLines * _lineHeight,
                    child: ClipRect(
                      child: ValueListenableBuilder<List<ScanLogEntry>>(
                        valueListenable: widget.logs,
                        builder: (context, logs, _) {
                          final visible = logs.length > _visibleLines
                              ? logs.sublist(logs.length - _visibleLines)
                              : logs;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final entry in visible)
                                SizedBox(
                                  key: ObjectKey(entry),
                                  height: _lineHeight,
                                  child: _LogLine(entry: entry),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(height: _lineHeight, child: _buildStatusLine()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
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
              'devmirror — port scan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _termMono.copyWith(fontSize: 10.5, color: _termDim),
            ),
          ),
          Text(
            widget.isScanning ? '${widget.foundCount} found' : 'exit 0',
            style: _termMono.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: widget.foundCount > 0 ? AppTheme.liveGreen : _termDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLine() {
    return AnimatedBuilder(
      animation: Listenable.merge([_ticker, widget.progress]),
      builder: (context, _) {
        final cursorOn = _ticker.value < 0.5;

        if (!widget.isScanning) {
          return Row(
            children: [
              Text(
                r'$ ',
                style: _termMono.copyWith(
                  color: AppTheme.liveGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Opacity(
                opacity: cursorOn ? 1 : 0,
                child: Container(width: 7, height: 13, color: _termText),
              ),
            ],
          );
        }

        // ASCII progress bar, e.g. "/ scanning [=======>        ]  45%"
        final progress = widget.progress.value.clamp(0.0, 1.0);
        final filled = (progress * _barWidth).floor();
        final bar = '=' * filled +
            (filled < _barWidth ? '>' : '') +
            ' ' * math.max(0, _barWidth - filled - 1);
        final frame = _spinnerFrames[
            (_ticker.value * 8).floor() % _spinnerFrames.length];

        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$frame ',
                style: const TextStyle(
                  color: AppTheme.liveGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: 'scanning ',
                style: TextStyle(color: _termDim),
              ),
              const TextSpan(text: '[', style: TextStyle(color: _termFaint)),
              TextSpan(text: bar),
              const TextSpan(text: ']', style: TextStyle(color: _termFaint)),
              TextSpan(
                text: '${(progress * 100).floor()}%'.padLeft(5),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          style: _termMono,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
        );
      },
    );
  }
}

/// One log line: probe noise fades in, everything else is typed out
class _LogLine extends StatelessWidget {
  final ScanLogEntry entry;

  const _LogLine({required this.entry});

  static String _timestamp(Duration elapsed) =>
      (elapsed.inMilliseconds / 1000).toStringAsFixed(2).padLeft(5, '0');

  @override
  Widget build(BuildContext context) {
    final (tag, tagColor, textColor) = switch (entry.level) {
      ScanLogLevel.command => (r'$ ', AppTheme.liveGreen, _termText),
      ScanLogLevel.info => ('INFO  ', _termText, _termMuted),
      ScanLogLevel.probe => ('PROBE ', _termFaint, _termDim),
      ScanLogLevel.open => ('OPEN  ', AppTheme.liveGreen, _termText),
      ScanLogLevel.title => ('TITLE ', AppTheme.liveGreen, _termMuted),
      ScanLogLevel.warn => ('WARN  ', _termAmber, _termText),
      ScanLogLevel.done => ('DONE  ', AppTheme.liveGreen, _termText),
    };
    final isProbe = entry.level == ScanLogLevel.probe;
    final isOpen = entry.level == ScanLogLevel.open;
    final isBold = isOpen || entry.level == ScanLogLevel.done;
    final message = entry.message;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: isProbe ? 160 : (isOpen ? 900 : 320)),
      builder: (context, t, _) {
        // Typing finishes early on OPEN lines so the green flash can linger
        final typed = isProbe ? 1.0 : (t / (isOpen ? 0.4 : 1.0)).clamp(0.0, 1.0);

        return Container(
          alignment: Alignment.centerLeft,
          decoration: isOpen
              ? BoxDecoration(
                  color: AppTheme.liveGreen.withValues(alpha: 0.2 * (1 - t)),
                  borderRadius: BorderRadius.circular(3),
                )
              : null,
          child: Opacity(
            opacity: isProbe ? t : 1,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${_timestamp(entry.elapsed)} ',
                    style: const TextStyle(color: _termFaint),
                  ),
                  TextSpan(
                    text: tag,
                    style: TextStyle(
                      color: tagColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: message.substring(0, (message.length * typed).round()),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              style: _termMono,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}
