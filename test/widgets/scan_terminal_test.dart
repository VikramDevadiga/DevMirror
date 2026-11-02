import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_mirror/services/network_discovery_service.dart';
import 'package:dev_mirror/widgets/scan_terminal.dart';

void main() {
  Widget buildTerminal({
    required ValueNotifier<List<ScanLogEntry>> logs,
    required ValueNotifier<double> progress,
    required bool isScanning,
    int foundCount = 0,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 328, // 360dp phone minus the screen's 16px gutters
            child: ScanTerminal(
              logs: logs,
              progress: progress,
              isScanning: isScanning,
              foundCount: foundCount,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('streams log lines with a progress bar, then shows a prompt when done',
      (tester) async {
    final logs = ValueNotifier<List<ScanLogEntry>>(const []);
    final progress = ValueNotifier<double>(0.5);

    await tester.pumpWidget(buildTerminal(logs: logs, progress: progress, isScanning: true));
    logs.value = [
      const ScanLogEntry(ScanLogLevel.command, 'devmirror scan --lan --ports 28', Duration.zero),
      for (int i = 0; i < 12; i++)
        ScanLogEntry(ScanLogLevel.probe, '192.168.1.$i:5173', Duration(milliseconds: 80 * i)),
      const ScanLogEntry(
        ScanLogLevel.open,
        '192.168.100.200:5173  Webpack / Vue / Spring Boot',
        Duration(milliseconds: 1500),
      ),
    ];
    // First frame starts the typing animations, the second lets them finish
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('192.168.100.200:5173', findRichText: true), findsOneWidget);
    // Only the newest lines stay in view
    expect(find.textContaining('devmirror scan', findRichText: true), findsNothing);
    expect(find.textContaining('[========>', findRichText: true), findsOneWidget);
    expect(find.textContaining('50%', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(buildTerminal(
      logs: logs,
      progress: progress,
      isScanning: false,
      foundCount: 1,
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('exit 0'), findsOneWidget);
    expect(find.textContaining('scanning', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
