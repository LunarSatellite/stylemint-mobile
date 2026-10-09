import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_quote.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/product_emi_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Hand-written readers for the EMI payloads of the phase 1 contract. Every
/// reader is tolerant: a missing field reads as absent, never as a throw, so
/// an older server (no `emi` at all) leaves the page exactly as it was.

/// `{ "amount": 100000, "currency": "NPR" }`, or null when it is not one.
Money? readMoney(Object? raw) {
  if (raw is! Map) return null;
  final amount = readOptionalDouble(raw['amount']);
  if (amount == null) return null;
  final currency = readOptionalString(raw['currency']) ?? 'NPR';
  return Money(amount: amount, currency: currency);
}

/// A money value that must be there; zero NPR when it is not.
Money readMoneyOrZero(Object? raw, {String currency = 'NPR'}) =>
    readMoney(raw) ?? Money(amount: 0, currency: currency);

/// Tenures as the contract allows them: 3, 6, 9 or 12, ascending, no repeats.
List<int> readTenures(Object? raw) {
  if (raw is! List) return const <int>[];
  final tenures =
      raw.map(readInt).where(emiAllowedTenures.contains).toSet().toList()
        ..sort();
  return List.unmodifiable(tenures);
}

/// The product detail payload's `emi` block and the variants'
/// `emiEligible`, or null when there is no usable offer.
///
/// No offer when `emi` is absent (an older backend), `null` (EMI off or no
/// variant qualifies), says `available: false`, offers no tenure, or no
/// variant is eligible. In every one of those the page draws nothing.
///
/// A variant whose payload has no `emiEligible` at all is judged by price
/// against `minimumPrice` (NPR 20,000) — the same rule the server applies —
/// rather than being read as ineligible, so a partially rolled-out backend
/// does not hide EMI on products that qualify.
ProductEmiOffer? readProductEmiOffer(Map<String, dynamic> product) {
  final emi = product['emi'];
  if (emi is! Map) return null;
  if (emi['available'] != null && !readBool(emi['available'])) return null;

  final tenures = readTenures(emi['tenures']);
  if (tenures.isEmpty) return null;

  final minimumPrice = readMoney(emi['minimumPrice']);
  final floor = minimumPrice?.amount ?? emiMinimumPriceAmount;
  final variants = <String, EmiVariantTerms>{};
  for (final raw
      in product['variants'] is List
          ? product['variants'] as List
          : const <dynamic>[]) {
    if (raw is! Map) continue;
    final id = readString(raw['id']);
    if (id.isEmpty) continue;
    final price = Money(
      amount: readOptionalDouble(raw['priceAmount']) ?? 0,
      currency: readOptionalString(raw['priceCurrency']) ?? 'NPR',
    );
    final eligible = raw.containsKey('emiEligible')
        ? readBool(raw['emiEligible'])
        : price.amount >= floor;
    variants[id] = EmiVariantTerms(price: price, eligible: eligible);
  }
  if (!variants.values.any((v) => v.eligible)) return null;

  final minDown = readInt(emi['minDownPaymentPercent']);
  return ProductEmiOffer(
    minDownPaymentPercent: minDown <= 0 ? emiMinDownPaymentPercent : minDown,
    tenures: tenures,
    fromMonthly: readMoney(emi['fromMonthly']),
    interestRatePercentMonthly:
        readOptionalDouble(emi['interestRatePercentMonthly']) ?? 0,
    minimumPrice: minimumPrice,
    variants: Map.unmodifiable(variants),
  );
}

/// `EmiQuoteDto`.
EmiQuote readEmiQuote(Map<String, dynamic> json) {
  final price = readMoneyOrZero(json['price']);
  final currency = price.currency;
  Money money(String key) => readMoneyOrZero(json[key], currency: currency);

  final schedule = <EmiInstallment>[
    for (final raw
        in json['schedule'] is List
            ? json['schedule'] as List
            : const <dynamic>[])
      if (raw is Map)
        EmiInstallment(
          number: readInt(raw['number']),
          amount: readMoneyOrZero(raw['amount'], currency: currency),
        ),
  ]..sort((a, b) => a.number.compareTo(b.number));

  final rawConstraints = json['constraints'];
  return EmiQuote(
    variantId: readString(json['variantId']),
    productId: readString(json['productId']),
    price: price,
    downPaymentPercent: readInt(json['downPaymentPercent']),
    downPayment: money('downPayment'),
    financedAmount: money('financedAmount'),
    tenureMonths: readInt(json['tenureMonths']),
    monthlyInstallment: money('monthlyInstallment'),
    lastInstallment: money('lastInstallment'),
    interestTotal: money('interestTotal'),
    totalPayable: money('totalPayable'),
    schedule: List.unmodifiable(schedule),
    constraints: rawConstraints is Map
        ? EmiQuoteConstraints(
            minDownPaymentPercent: readInt(
              rawConstraints['minDownPaymentPercent'],
            ),
            maxDownPaymentPercent: readInt(
              rawConstraints['maxDownPaymentPercent'],
            ),
            tenures: readTenures(rawConstraints['tenures']),
          )
        : null,
  );
}

/// `GET /v1/customer/emi/eligibility`.
EmiEligibility readEmiEligibility(Map<String, dynamic> json) => EmiEligibility(
  kycTier: readInt(json['kycTier']),
  kycStatus: KycStatus.fromWire(json['kycStatus']),
  eligible: readBool(json['eligible']),
  reasons: json['reasons'] is List
      ? List.unmodifiable(
          (json['reasons'] as List).whereType<String>().map(
            (r) => r.trim().toLowerCase(),
          ),
        )
      : const <String>[],
  band: readOptionalString(json['band']),
);
