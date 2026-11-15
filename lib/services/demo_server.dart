import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

typedef DemoAssetLoader = Future<String> Function(String assetPath);

/// A tiny HTTP server that serves the bundled demo page from the phone itself,
/// so DevMirror can be tried without a dev server on the network.
///
/// It binds to the loopback interface only, so nothing on the Wi-Fi can reach it.
class DemoServer {
  static const String indexAsset = 'assets/demo/index.html';
  static const String host = '127.0.0.1';

  final DemoAssetLoader _loadAsset;

  HttpServer? _server;
  Future<HttpServer>? _starting;
  String? _indexHtml;
  DateTime _startedAt = DateTime.now();
  int _pingCount = 0;

  DemoServer({DemoAssetLoader? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.loadString;

  bool get isRunning => _server != null;

  /// The port the server listens on, or null while it is stopped.
  int? get port => _server?.port;

  /// Starts the server if needed and returns its port. Safe to call repeatedly.
  Future<int> start() async {
    final running = _server;
    if (running != null) return running.port;

    final server = await (_starting ??= _bind());
    return server.port;
  }

  Future<HttpServer> _bind() async {
    try {
      _indexHtml = await _loadAsset(indexAsset);
      // Port 0 lets the OS pick a free port, so it never clashes with
      // `adb reverse` ports or anything else already listening on loopback.
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _startedAt = DateTime.now();
      _pingCount = 0;
      // A browser that drops a connection mid-response must not surface as an
      // uncaught error, so failures are swallowed per request.
      server.listen(
        (request) => _handle(request).catchError((Object _) {}),
        onError: (Object _) {},
      );
      _server = server;
      return server;
    } finally {
      _starting = null;
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');

    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        response.headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
        response.headers.contentType = ContentType.text;
        response.write('Method not allowed');
        return;
      }

      switch (request.uri.path) {
        case '/':
        case '/index.html':
          response.headers.contentType = ContentType.html;
          response.write(_indexHtml ?? '');
        case '/api/ping':
          _pingCount++;
          response.headers.contentType = ContentType.json;
          response.write(jsonEncode({
            'ok': true,
            'requests': _pingCount,
            'uptimeMs': DateTime.now().difference(_startedAt).inMilliseconds,
          }));
        default:
          response.statusCode = HttpStatus.notFound;
          response.headers.contentType = ContentType.text;
          response.write('Not found');
      }
    } finally {
      await response.close();
    }
  }
}
