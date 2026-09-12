enum LiveSessionStatus { scheduled, live, ended, unknown }

/// A Live Commerce stream — backend `LiveCommerceService.LiveSessionDto`.
class LiveSession {
  const LiveSession({
    required this.id,
    required this.creatorAccountId,
    required this.title,
    required this.status,
    required this.scheduledStartUtc,
    required this.currentViewerCount,
    required this.featuredProductIds,
  });

  final String id;
  final String creatorAccountId;
  final String title;
  final LiveSessionStatus status;
  final DateTime scheduledStartUtc;
  final int currentViewerCount;
  final List<String> featuredProductIds;
}

/// One live-room event pushed over the LiveCommerceHub SignalR connection.
sealed class LiveRoomEvent {
  const LiveRoomEvent();
}

class ViewerCountUpdated extends LiveRoomEvent {
  const ViewerCountUpdated(this.count);
  final int count;
}

class ReactionBurst extends LiveRoomEvent {
  const ReactionBurst(this.reactionType);
  final String reactionType;
}

class ProductPinned extends LiveRoomEvent {
  const ProductPinned(this.productId);
  final String productId;
}

class ProductReserved extends LiveRoomEvent {
  const ProductReserved(this.reservationId, this.productId, this.expiresInSeconds);
  final String reservationId;
  final String productId;
  final int expiresInSeconds;
}

class ReserveFailed extends LiveRoomEvent {
  const ReserveFailed(this.productId);
  final String productId;
}

class PurchaseConfirmed extends LiveRoomEvent {
  const PurchaseConfirmed(this.reservationId);
  final String reservationId;
}

class PurchaseFailed extends LiveRoomEvent {
  const PurchaseFailed(this.reason);
  final String reason;
}

class LiveChatMessage extends LiveRoomEvent {
  const LiveChatMessage(this.userId, this.message, this.sentAt);
  final String userId;
  final String message;
  final DateTime sentAt;
}
