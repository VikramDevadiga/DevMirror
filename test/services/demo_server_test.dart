import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dev_mirror/services/demo_server.dart';

void main() {
  late DemoServer server;
  late HttpClient client;

  setUp(() {
    server = DemoServer(
      loadAsset: (_) async => '<html><title>Demo</title></html>',
    );
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.stop();
  });

  Future<HttpClientResponse> send(String method, int port, String path) async {
    final request = await client.open(method, DemoServer.host, port, path);
    return request.close();
  }

  Future<String> body(HttpClientResponse response) =>
      response.transform(utf8.decoder).join();

  group('DemoServer', () {
    test('serves the demo page on loopback', () async {
      final port = await server.start();

      final response = await send('GET', port, '/');

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.contentType?.mimeType, 'text/html');
      expect(await body(response), contains('<title>Demo</title>'));
    });

    test('start returns the same port when called repeatedly or concurrently',
        () async {
      final ports = await Future.wait([server.start(), server.start()]);

      expect(ports[0], ports[1]);
      expect(await server.start(), ports[0]);
      expect(server.port, ports[0]);
    });

    test('/api/ping returns JSON and counts requests', () async {
      final port = await server.start();

      await body(await send('GET', port, '/api/ping'));
      final response = await send('GET', port, '/api/ping');
      final json = jsonDecode(await body(response)) as Map<String, dynamic>;

      expect(response.headers.contentType?.mimeType, 'application/json');
      expect(json['ok'], isTrue);
      expect(json['requests'], 2);
      expect(json['uptimeMs'], isA<int>());
    });

    test('returns 404 for unknown paths', () async {
      final port = await server.start();

      final response = await send('GET', port, '/missing.js');

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('rejects methods other than GET and HEAD', () async {
      final port = await server.start();

      final response = await send('POST', port, '/');

      expect(response.statusCode, HttpStatus.methodNotAllowed);
    });

    test('stop closes the server and it can be started again', () async {
      final firstPort = await server.start();
      await server.stop();

      expect(server.isRunning, isFalse);
      expect(server.port, isNull);
      await expectLater(
        Socket.connect(DemoServer.host, firstPort),
        throwsA(isA<SocketException>()),
      );

      final port = await server.start();
      final response = await send('GET', port, '/');
      expect(response.statusCode, HttpStatus.ok);
    });

    test('start fails and stays stopped when the page cannot be loaded',
        () async {
      final broken = DemoServer(
        loadAsset: (_) async => throw Exception('missing asset'),
      );

      await expectLater(broken.start(), throwsException);
      expect(broken.isRunning, isFalse);
    });
  });
}
