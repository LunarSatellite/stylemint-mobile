class WalletBalance {
  const WalletBalance({
    required this.id,
    required this.accountId,
    required this.currency,
    required this.available,
    required this.pending,
    required this.status,
    required this.updatedUtc,
  });

  final String id;
  final String accountId;
  final String currency;
  final double available;
  final double pending;
  final String status; // Active | Frozen | Closed
  final DateTime updatedUtc;
}
