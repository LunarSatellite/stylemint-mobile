/// Mirrors backend `GroupBuyState` (1-based: Open=1 .. Cancelled=5).
enum GroupBuyState { unknown, open, committed, fulfilled, expired, cancelled }

/// A "buy together for a group discount" campaign for one product —
/// backend `StyleMint.Modules.SocialGraph.GroupBuyDto`.
class GroupBuy {
  const GroupBuy({
    required this.id,
    required this.productId,
    required this.initiatorAccountId,
    required this.targetBuyerCount,
    required this.discountPercent,
    required this.commitCount,
    required this.state,
    required this.expiresAt,
  });

  final String id;
  final String productId;
  final String initiatorAccountId;
  final int targetBuyerCount;
  final double discountPercent;
  final int commitCount;
  final GroupBuyState state;
  final DateTime expiresAt;

  bool get isOpen =>
      (state == GroupBuyState.open || state == GroupBuyState.committed) &&
      expiresAt.isAfter(DateTime.now());
  int get slotsRemaining => (targetBuyerCount - commitCount).clamp(0, targetBuyerCount);
  double get progress =>
      targetBuyerCount <= 0 ? 0 : (commitCount / targetBuyerCount).clamp(0, 1);
}
