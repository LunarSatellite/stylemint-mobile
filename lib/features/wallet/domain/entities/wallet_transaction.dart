class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.currency,
    required this.type,
    required this.source,
    required this.amount,
    required this.balanceAfter,
    this.correlationId,
    this.correlationType,
    this.reversalOf,
    this.description,
    required this.occurredUtc,
  });

  final String id;
  final String walletId;
  final String currency;
  final String type;   // Credit | Debit | PendingCredit | PendingClear | Reversal | Reservation…
  final String source; // Refund | AdminAdjustment | Payout | Other
  final double amount;
  final double balanceAfter;
  final String? correlationId;
  final String? correlationType;
  final String? reversalOf;
  final String? description;
  final DateTime occurredUtc;

  static const _hidden = {'Reservation', 'ReservationCommit', 'ReservationRelease'};
  bool get isVisible => !_hidden.contains(type);
}
