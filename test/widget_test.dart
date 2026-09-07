import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dev_mirror/main.dart';
import 'package:dev_mirror/services/connection_storage_service.dart';

void main() {
  testWidgets('DevMirrorApp loads connect screen with form fields and presets', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await ConnectionStorageService.init();

    await tester.pumpWidget(DevMirrorApp(storageService: storageService));
    await tester.pumpAndSettle();

    // Verify app title and main cards
    expect(find.text('DevMirror'), findsOneWidget);
    expect(find.text('SERVER TARGET'), findsOneWidget);
    expect(find.text('PC IP Address (IPv4)'), findsOneWidget);
    expect(find.text('Port Number'), findsOneWidget);
    expect(find.text('Connect & Preview'), findsOneWidget);

    // Verify preset port ActionChips
    expect(find.widgetWithText(ActionChip, '3000'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '5173'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '8080'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '5500'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '8000'), findsOneWidget);

    // Tap preset chip 3000 and verify it updates the port text field
    await tester.tap(find.widgetWithText(ActionChip, '3000'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '3000'), findsOneWidget);

    // Tap Connect without IP and verify validation error appears
    await tester.tap(find.text('Connect & Preview'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your computer\'s local IP'), findsOneWidget);
  });
}
