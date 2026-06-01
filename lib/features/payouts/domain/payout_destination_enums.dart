/// Who the payout destination belongs to. Wire value matches backend `PayeeKind`.
enum PayeeKind {
  creator(1),
  vendor(2);

  const PayeeKind(this.value);
  final int value;
}

/// Payout destination types. Wire value matches backend `PayoutDestinationKind`.
/// Bank kinds require a branch/IFSC; PayPal/eSewa must omit it.
enum PayoutDestinationKind {
  nimbBank(1, 'NIMB Bank', 'Account number', requiresBranch: true),
  laxmiBank(2, 'Laxmi Bank', 'Account number', requiresBranch: true),
  payPal(3, 'PayPal', 'PayPal email'),
  esewa(4, 'eSewa', 'eSewa ID / mobile');

  const PayoutDestinationKind(
    this.value,
    this.label,
    this.identifierHint, {
    this.requiresBranch = false,
  });

  final int value;
  final String label;
  final String identifierHint;
  final bool requiresBranch;

  static PayoutDestinationKind fromValue(int v) =>
      values.firstWhere((e) => e.value == v,
          orElse: () => PayoutDestinationKind.nimbBank);
}
