/// Pure Dart — no JSON, no Dio.
/// All money values from the API are { amount: double, currency: "NPR" }.
/// Never multiply by 100 — backend stores decimal NPR, not paisa.
class Money {
  const Money({required this.amount, required this.currency});

  final double amount;
  final String currency; // ISO 4217 — e.g. "NPR"

  @override
  String toString() => '$currency $amount';

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);
}
