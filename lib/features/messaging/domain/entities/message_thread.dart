/// Scope of a direct message thread. Mirrors the backend
/// `MessageThreadScope` enum (1=VendorCreatorPartnership, 2=CreatorBrandPartnership).
enum MessageThreadScope {
  vendorCreatorPartnership,
  creatorBrandPartnership;

  static MessageThreadScope fromInt(int value) {
    switch (value) {
      case 1:
        return MessageThreadScope.vendorCreatorPartnership;
      case 2:
        return MessageThreadScope.creatorBrandPartnership;
      default:
        return MessageThreadScope.vendorCreatorPartnership;
    }
  }

  int toInt() {
    switch (this) {
      case MessageThreadScope.vendorCreatorPartnership:
        return 1;
      case MessageThreadScope.creatorBrandPartnership:
        return 2;
    }
  }
}

/// A direct message thread between two accounts (vendor + creator).
/// `participantAId` / `participantBId` are the two account ids; the
/// caller is whichever the JWT `sub` claim resolves to.
class MessageThread {
  const MessageThread({
    required this.id,
    required this.scope,
    required this.participantAId,
    required this.participantBId,
    this.contextId,
    this.lastMessageUtc,
    required this.createdUtc,
  });

  final String id;
  final MessageThreadScope scope;
  final String participantAId;
  final String participantBId;
  final String? contextId;
  final DateTime? lastMessageUtc;
  final DateTime createdUtc;
}
