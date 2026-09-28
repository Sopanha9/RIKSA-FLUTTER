import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../network/api_config.dart';
import '../network/dio_client.dart';

/// A "this changed" message from the server. It names what changed; screens
/// refetch the content itself through the REST API.
class RealtimeEvent {
  const RealtimeEvent(this.type, [this.data = const {}]);

  /// Sent by the client itself after a reconnect: anything may have changed
  /// while the connection was down.
  static const resync = 'resync';

  final String type;
  final Map<String, dynamic> data;

  String? get postId => data['postId']?.toString();
  String? get authorId => data['authorId']?.toString();
}

/// Names the server sends; keep in step with `RealtimeTypes` in the API.
abstract final class RealtimeTypes {
  static const postChanged = 'post.changed';
  static const postCreated = 'post.created';
  static const postDeleted = 'post.deleted';
  static const questsChanged = 'quests.changed';
}

/// One WebSocket to the API for the signed-in learner.
///
/// It reconnects on its own with a growing delay, refreshes an expired token
/// before retrying, and reconnects at once when the app comes back to the
/// foreground. After any reconnect it emits [RealtimeEvent.resync].
class RealtimeClient with WidgetsBindingObserver {
  RealtimeClient(this._client, {Uri Function(String token)? uriFor})
    : _uriFor = uriFor ?? _defaultUri;

  static const _pingInterval = Duration(seconds: 25);
  static const _maxBackoff = Duration(seconds: 30);

  final DioClient _client;
  final Uri Function(String token) _uriFor;
  final _events = StreamController<RealtimeEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  Timer? _retryTimer;
  int _attempt = 0;
  bool _running = false;
  bool _connected = false;
  bool _hasConnectedBefore = false;

  Stream<RealtimeEvent> get events => _events.stream;
  bool get isConnected => _connected;

  void start() {
    if (_running) return;
    _running = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_connect());
  }

  void dispose() {
    _running = false;
    WidgetsBinding.instance.removeObserver(this);
    _teardown();
    _retryTimer?.cancel();
    unawaited(_events.close());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Phones drop idle sockets in the background; reconnect straight away on
    // return rather than waiting out the backoff.
    if (state == AppLifecycleState.resumed && _running && !_connected) {
      _retryTimer?.cancel();
      _attempt = 0;
      unawaited(_connect());
    }
  }

  Future<void> _connect() async {
    if (!_running) return;
    _teardown();
    final token = await _client.getAccessToken();
    if (!_running) return;
    if (token == null || token.isEmpty) return;

    final channel = WebSocketChannel.connect(_uriFor(token));
    _channel = channel;
    try {
      await channel.ready;
    } catch (_) {
      if (!identical(_channel, channel)) return;
      // A refused handshake is most often an expired access token.
      await _client.refreshAccessToken().catchError((_) => false);
      _scheduleRetry();
      return;
    }
    if (!_running || !identical(_channel, channel)) {
      unawaited(channel.sink.close());
      return;
    }

    _connected = true;
    _attempt = 0;
    if (_hasConnectedBefore) {
      _events.add(const RealtimeEvent(RealtimeEvent.resync));
    }
    _hasConnectedBefore = true;
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      try {
        channel.sink.add('ping');
      } catch (_) {}
    });
    _subscription = channel.stream.listen(
      _onMessage,
      onError: (_) => _onClosed(channel),
      onDone: () => _onClosed(channel),
      cancelOnError: true,
    );
  }

  void _onMessage(dynamic message) {
    if (message is! String) return;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map) return;
      final type = decoded['type'];
      if (type is! String) return;
      final data = decoded['data'];
      _events.add(
        RealtimeEvent(
          type,
          data is Map ? Map<String, dynamic>.from(data) : const {},
        ),
      );
    } catch (error) {
      debugPrint('Ignoring realtime message: $error');
    }
  }

  void _onClosed(WebSocketChannel channel) {
    if (!identical(_channel, channel)) return;
    _teardown();
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (!_running) return;
    _retryTimer?.cancel();
    final seconds = math.min(_maxBackoff.inSeconds, 1 << _attempt);
    _attempt = math.min(_attempt + 1, 6);
    _retryTimer = Timer(Duration(seconds: seconds), () => _connect());
  }

  void _teardown() {
    _connected = false;
    _pingTimer?.cancel();
    _pingTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(channel.sink.close().catchError((_) {}));
  }

  static Uri _defaultUri(String token) {
    final base = Uri.parse(ApiConfig.baseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${ApiConfig.apiPrefix}/realtime',
      queryParameters: {'token': token},
    );
  }
}
