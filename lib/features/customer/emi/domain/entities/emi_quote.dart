import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// One monthly payment of a quote — `number` is the month after delivery.
class EmiInstallment {
  const EmiInstallment({required this.number, required this.amount});

  final int number;
  final Money amount;
}

/// The bounds the server applied to a quote.
class EmiQuoteConstraints {
  const EmiQuoteConstraints({
    required this.minDownPaymentPercent,
    required this.maxDownPaymentPercent,
    required this.tenures,
  });

  final int minDownPaymentPercent;
  final int maxDownPaymentPercent;
  final List<int> tenures;
}

/// Backend `EmiQuoteDto` from `GET /v1/emi/quote`. The server's word on a
/// plan: the calculator shows its own arithmetic at once and replaces it with
/// this when it arrives.
class EmiQuote {
  const EmiQuote({
    required this.variantId,
    required this.productId,
    required this.price,
    required this.downPaymentPercent,
    required this.downPayment,
    required this.financedAmount,
    required this.tenureMonths,
    required this.monthlyInstallment,
    required this.lastInstallment,
    required this.interestTotal,
    required this.totalPayable,
    this.schedule = const <EmiInstallment>[],
    this.constraints,
  });

  final String variantId;
  final String productId;
  final Money price;
  final int downPaymentPercent;
  final Money downPayment;
  final Money financedAmount;
  final int tenureMonths;
  final Money monthlyInstallment;
  final Money lastInstallment;
  final Money interestTotal;
  final Money totalPayable;
  final List<EmiInstallment> schedule;
  final EmiQuoteConstraints? constraints;

  /// Whether this quote answers the selection the buyer has on screen now.
  bool matches({
    required String variantId,
    required int downPaymentPercent,
    required int tenureMonths,
  }) =>
      this.variantId == variantId &&
      this.downPaymentPercent == downPaymentPercent &&
      this.tenureMonths == tenureMonths;
}
