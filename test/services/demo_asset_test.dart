import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dev_mirror/services/demo_server.dart';

// Kept apart from demo_server_test.dart: initializing the test binding replaces
// HttpClient with a mock, which would break the real HTTP requests there.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo page is bundled as an app asset', () async {
    final html = await rootBundle.loadString(DemoServer.indexAsset);

    expect(html, contains('<title>DevMirror Demo</title>'));
    expect(html, contains('/api/ping'));
  });
}
