import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/entities/live_session.dart';

/// Wraps the SignalR connection to `LiveCommerceHub` at
/// `/hubs/live/{sessionId}`. Unlike [MessagingRealtimeService] (one
/// connection for the whole app session), a Live Commerce connection is
/// scoped to a single room visit — created when the live room screen
/// opens, torn down when it closes.
class LiveCommerceRealtimeService {
  HubConnection? _connection;
  String? _sessionId;

  final _eventController = StreamController<LiveRoomEvent>.broadcast();

  Stream<LiveRoomEvent> get events => _eventController.stream;

  bool get isConnected => _connection != null;

  Future<void> join({
    required String hubBaseUrl,
    required String sessionId,
    String? accessToken,
  }) async {
    if (_connection != null) return;
    _sessionId = sessionId;
    final base = _normaliseBase(hubBaseUrl);

    final conn = HubConnectionBuilder()
        .withUrl(
          '$base/hubs/live/$sessionId',
          options: HttpConnectionOptions(
            accessTokenFactory: () async => accessToken ?? '',
            skipNegotiation: false,
            transport: HttpTransportType.WebSockets,
          ),
        )
        .build();

    conn.on('ViewerCountUpdated', (args) {
      final count = _asInt(args?.firstOrNull);
      if (count != null) _eventController.add(ViewerCountUpdated(count));
    });
    conn.on('ReactionBurst', (args) {
      if (args == null || args.isEmpty) return;
      final type = args.first as String?;
      if (type != null) _eventController.add(ReactionBurst(type));
    });
    conn.on('ProductPinned', (args) {
      final map = _asMap(args?.firstOrNull);
      final productId = map?['ProductId'] as String? ?? map?['productId'] as String?;
      if (productId != null) _eventController.add(ProductPinned(productId));
    });
    conn.on('ProductReserved', (args) {
      final map = _asMap(args?.firstOrNull);
      if (map == null) return;
      final reservationId = map['ReservationId'] as String? ?? map['reservationId'] as String?;
      final productId = map['ProductId'] as String? ?? map['productId'] as String?;
      final expiresIn = map['ExpiresIn'] ?? map['expiresIn'];
      if (reservationId != null && productId != null) {
        _eventController.add(ProductReserved(
          reservationId,
          productId,
          expiresIn is int ? expiresIn : 0,
        ));
      }
    });
    conn.on('ReserveFailed', (args) {
      final map = _asMap(args?.firstOrNull);
      final productId = map?['ProductId'] as String? ?? map?['productId'] as String?;
      if (productId != null) _eventController.add(ReserveFailed(productId));
    });
    conn.on('PurchaseConfirmed', (args) {
      final map = _asMap(args?.firstOrNull);
      final reservationId = map?['ReservationId'] as String? ?? map?['reservationId'] as String?;
      if (reservationId != null) _eventController.add(PurchaseConfirmed(reservationId));
    });
    conn.on('PurchaseFailed', (args) {
      final reason = args?.firstOrNull;
      if (reason is String) _eventController.add(PurchaseFailed(reason));
    });
    conn.on('ChatMessage', (args) {
      final map = _asMap(args?.firstOrNull);
      if (map == null) return;
      final userId = map['UserId'] as String? ?? map['userId'] as String?;
      final message = map['Message'] as String? ?? map['message'] as String?;
      final sentAtRaw = map['SentAt'] ?? map['sentAt'];
      if (userId == null || message == null) return;
      final sentAt = sentAtRaw is String
          ? (DateTime.tryParse(sentAtRaw) ?? DateTime.now())
          : DateTime.now();
      _eventController.add(LiveChatMessage(userId, message, sentAt));
    });

    try {
      await conn.start();
      await conn.invoke('JoinStream', args: [sessionId]);
      _connection = conn;
    } catch (_) {
      // Best-effort real-time layer — the room still renders from the
      // REST-fetched session snapshot without it.
      _connection = null;
    }
  }

  Future<void> sendReaction(String reactionType) =>
      _invoke('SendReaction', [_sessionId, reactionType]);

  Future<void> sendMessage(String message) =>
      _invoke('SendMessage', [_sessionId, message]);

  Future<void> pinProduct(String productId) =>
      _invoke('PinProduct', [_sessionId, productId]);

  Future<void> reserveProduct(String productId, String variantId) =>
      _invoke('ReserveProduct', [_sessionId, productId, variantId]);

  Future<void> confirmPurchase(String reservationId) =>
      _invoke('ConfirmPurchase', [_sessionId, reservationId]);

  Future<void> _invoke(String method, List<Object?> args) async {
    final conn = _connection;
    if (conn == null || _sessionId == null) return;
    try {
      await conn.invoke(method, args: args.map((a) => a as Object).toList());
    } catch (_) {
      // Fire-and-forget — the caller sees no ack either way beyond the
      // server-pushed events already wired above.
    }
  }

  Future<void> leave() async {
    final conn = _connection;
    final sessionId = _sessionId;
    _connection = null;
    _sessionId = null;
    if (conn == null) return;
    try {
      if (sessionId != null) {
        await conn.invoke('LeaveStream', args: [sessionId]);
      }
      await conn.stop();
    } catch (_) {
      // Ignore — connection may already be closed.
    }
  }

  Future<void> dispose() async {
    await leave();
    await _eventController.close();
  }

  String _normaliseBase(String url) {
    var base = url.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (base.endsWith('/api')) base = base.substring(0, base.length - 4);
    return base;
  }

  int? _asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : null);

  Map<String, dynamic>? _asMap(Object? v) => v is Map ? v.cast<String, dynamic>() : null;
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
