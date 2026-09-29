import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers the app's HTTP calls from [routes]. Anything not listed gets a 404
/// and is recorded in [unhandled], so the crawler can report screens that
/// asked for data the fake doesn't provide.
class FakeRiksaServer implements HttpClientAdapter {
  FakeRiksaServer(this.routes);

  /// `'GET /quests/today'` style keys. Path segments written as `*` match any
  /// single segment. The handler gets the request and returns the JSON body.
  final Map<String, Object? Function(RequestOptions request)> routes;

  final requests = <String>[];
  final unhandled = <String>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = Uri.parse(options.path).path;
    final key = '${options.method.toUpperCase()} $path';
    requests.add(key);
    final handler = _match(options.method.toUpperCase(), path);
    if (handler == null) {
      unhandled.add(key);
      return _json({'message': 'Not in the crawler fixtures: $key'}, 404);
    }
    final body = handler(options);
    if (body is FakeStatus) return _json(body.body, body.status);
    return _json(body, body == null ? 204 : 200);
  }

  Object? Function(RequestOptions)? _match(String method, String path) {
    final exact = routes['$method $path'];
    if (exact != null) return exact;
    final segments = path.split('/');
    for (final entry in routes.entries) {
      final space = entry.key.indexOf(' ');
      if (entry.key.substring(0, space) != method) continue;
      final pattern = entry.key.substring(space + 1).split('/');
      if (pattern.length != segments.length) continue;
      var ok = true;
      for (var i = 0; i < pattern.length && ok; i++) {
        ok = pattern[i] == '*' || pattern[i] == segments[i];
      }
      if (ok) return entry.value;
    }
    return null;
  }

  ResponseBody _json(Object? body, int status) => ResponseBody.fromString(
    body == null ? '' : jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

/// Returns [body] with a non-200 status.
class FakeStatus {
  const FakeStatus(this.status, [this.body]);
  final int status;
  final Object? body;
}
