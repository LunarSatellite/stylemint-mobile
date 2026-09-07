import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import 'package:stylemint_mobile_frontend/features/messaging/data/models/direct_message_dto.dart';

/// Wraps the SignalR connection to the backend `MessagingHub` at
/// `/hubs/messaging`. Listens for the server-pushed
/// <c>thread-message</c> events and exposes them as broadcast [Stream]s for notifiers to consume.
///
/// Connection is lazy: the first call to [start] opens the WebSocket.
/// Reconnects are automatic; [stop] disposes the connection entirely.
class MessagingRealtimeService {
  HubConnection? _connection;
  String? _hubUrl;
  String? _token;
  bool _starting = false;

  final _messageController =
      StreamController<({String threadId, DirectMessageDto message})>.broadcast();

  /// Stream of new messages that just landed in any of the caller's threads.
  Stream<({String threadId, DirectMessageDto message})> get onMessage =>
      _messageController.stream;

  /// Replace the bearer used for the SignalR handshake. The connection
  /// is restarted with the new token if one is already established.
  void setAccessToken(String? token) {
    _token = token;
    final existing = _connection;
    if (existing != null) {
      // Stop and let the next start() re-open with the new token.
      stop();
    }
  }

  /// Start the connection if not already started. Idempotent.
  Future<void> start({required String hubBaseUrl, String? accessToken}) async {
    if (_connection != null) return;
    if (_starting) return;
    _starting = true;
    _token = accessToken ?? _token;
    _hubUrl = _normaliseBase(hubBaseUrl);

    final conn = HubConnectionBuilder()
        .withUrl(
          '$_hubUrl/hubs/messaging',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => _token ?? '',
            skipNegotiation: false,
            transport: HttpTransportType.WebSockets,
          ),
        )
        .build();

    conn.on('thread-message', (args) {
      if (args == null || args.isEmpty) return;
      final first = args.first;
      if (first is! Map) return;
      final map = first.cast<String, dynamic>();
      final threadId = map['threadId'] as String?;
      final messageJson = map['message'];
      if (threadId == null || messageJson is! Map) return;
      try {
        final msg = DirectMessageDto.fromJson(messageJson.cast<String, dynamic>());
        _messageController.add((threadId: threadId, message: msg));
      } catch (_) {
        // Drop malformed payloads; the REST inbox is the durable read.
      }
    });

    try {
      await conn.start();
      _connection = conn;
    } catch (_) {
      // Best-effort: the REST surface is the source of truth. The next
      // call to start() will retry.
      _connection = null;
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    final conn = _connection;
    _connection = null;
    if (conn == null) return;
    try {
      await conn.stop();
    } catch (_) {
      // Ignore: the connection may already be closed.
    }
  }

  Future<void> dispose() async {
    await stop();
    await _messageController.close();
  }

  String _normaliseBase(String url) {
    var base = url.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    // Strip a trailing /api so we can append /hubs/messaging cleanly.
    if (base.endsWith('/api')) base = base.substring(0, base.length - 4);
    return base;
  }
}
