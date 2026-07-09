import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_earnings_dto.freezed.dart';
part 'vendor_earnings_dto.g.dart';

@freezed
abstract class VendorEarningsSummaryDto with _$VendorEarningsSummaryDto {
  const factory VendorEarningsSummaryDto({
    required double totalRevenueAmount,
    @Default('NPR') String totalRevenueCurrency,
    required double pendingPayoutAmount,
    @Default('NPR') String pendingPayoutCurrency,
    required double availableBalanceAmount,
    @Default('NPR') String availableBalanceCurrency,
    required double thisMonthAmount,
    @Default('NPR') String thisMonthCurrency,
    required double lastMonthAmount,
    @Default('NPR') String lastMonthCurrency,
    required int totalOrders,
    required double platformFeesAmount,
    @Default('NPR') String platformFeesCurrency,
    DateTime? nextPayoutDate,
  }) = _VendorEarningsSummaryDto;

  const VendorEarningsSummaryDto._();

  factory VendorEarningsSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$VendorEarningsSummaryDtoFromJson(json);

  VendorEarningsSummary toDomain() => VendorEarningsSummary(
    totalRevenue: Money(
      amount: totalRevenueAmount,
      currency: totalRevenueCurrency,
    ),
    pendingPayout: Money(
      amount: pendingPayoutAmount,
      currency: pendingPayoutCurrency,
    ),
    availableBalance: Money(
      amount: availableBalanceAmount,
      currency: availableBalanceCurrency,
    ),
    thisMonth: Money(
      amount: thisMonthAmount,
      currency: thisMonthCurrency,
    ),
    lastMonth: Money(
      amount: lastMonthAmount,
      currency: lastMonthCurrency,
    ),
    totalOrders: totalOrders,
    platformFees: Money(
      amount: platformFeesAmount,
      currency: platformFeesCurrency,
    ),
    nextPayoutDate: nextPayoutDate,
  );
}

/// Mirrors `GET /v1/earnings/balance`.
@freezed
abstract class VendorEarningsBalanceDto with _$VendorEarningsBalanceDto {
  const factory VendorEarningsBalanceDto({
    @Default(0) double availableValue,
    @Default(0) double pendingValue,
    @Default(0) double lifetimeValue,
    @Default('NPR') String currency,
  }) = _VendorEarningsBalanceDto;

  const VendorEarningsBalanceDto._();

  factory VendorEarningsBalanceDto.fromJson(Map<String, dynamic> json) =>
      _$VendorEarningsBalanceDtoFromJson(json);

  VendorEarningsBalance toDomain() => VendorEarningsBalance(
    available: Money(amount: availableValue, currency: currency),
    pending: Money(amount: pendingValue, currency: currency),
    lifetime: Money(amount: lifetimeValue, currency: currency),
  );
}

/// Mirrors an item of `GET /v1/earnings/entries` — `kind` is the backend's
/// int-valued `LedgerEntryKind` (1=Commission, 2=VendorNet, 3=Reversal,
/// 4=PayoutDebit, 5=FeeDebit, 6=BoostFeeDebit), not a string.
@freezed
abstract class VendorEarningsLedgerDto with _$VendorEarningsLedgerDto {
  const factory VendorEarningsLedgerDto({
    required String id,
    required int kind,
    String? orderId,
    String? note,
    @Default(0) double amountValue,
    @Default('NPR') String amountCurrency,
    required DateTime occurredUtc,
  }) = _VendorEarningsLedgerDto;

  const VendorEarningsLedgerDto._();

  factory VendorEarningsLedgerDto.fromJson(Map<String, dynamic> json) =>
      _$VendorEarningsLedgerDtoFromJson(json);

  VendorEarningsLedger toDomain() => VendorEarningsLedger(
    id: id,
    type: switch (kind) {
      3 => VendorLedgerType.refund,
      4 => VendorLedgerType.payout,
      5 || 6 => VendorLedgerType.fee,
      _ => VendorLedgerType.sale,
    },
    orderId: orderId,
    note: note,
    amount: Money(amount: amountValue, currency: amountCurrency),
    occurredAt: occurredUtc,
  );
}

VendorPayoutState _payoutStateFromWire(int state) => switch (state) {
  2 => VendorPayoutState.processing,
  3 => VendorPayoutState.paid,
  4 => VendorPayoutState.failed,
  5 => VendorPayoutState.held,
  _ => VendorPayoutState.requested,
};

/// Mirrors an item of `GET /v1/payouts` — `payeeKind` (1=Creator, 2=Vendor)
/// distinguishes rows on the shared payee/payout engine; callers filter to
/// vendor rows since the endpoint isn't role-scoped server-side.
@freezed
abstract class VendorPayoutDto with _$VendorPayoutDto {
  const factory VendorPayoutDto({
    required String id,
    @Default(1) int payeeKind,
    @Default(1) int destination,
    @Default('') String destinationRef,
    @Default(0) double requestedAmountValue,
    @Default('NPR') String requestedAmountCurrency,
    @Default(0) double feeAmountValue,
    @Default('NPR') String feeAmountCurrency,
    @Default(0) double netAmountValue,
    @Default('NPR') String netAmountCurrency,
    required DateTime requestedUtc,
    @Default(1) int state,
    DateTime? paidUtc,
    String? failureMessage,
  }) = _VendorPayoutDto;

  const VendorPayoutDto._();

  factory VendorPayoutDto.fromJson(Map<String, dynamic> json) =>
      _$VendorPayoutDtoFromJson(json);

  VendorPayout toDomain() => VendorPayout(
    id: id,
    destinationKind: destination,
    destinationRef: destinationRef,
    requestedAmount: Money(
      amount: requestedAmountValue,
      currency: requestedAmountCurrency,
    ),
    feeAmount: Money(amount: feeAmountValue, currency: feeAmountCurrency),
    netAmount: Money(amount: netAmountValue, currency: netAmountCurrency),
    requestedAt: requestedUtc,
    state: _payoutStateFromWire(state),
    paidAt: paidUtc,
    failureMessage: failureMessage,
  );
}

@freezed
abstract class VendorPayoutInvoiceLineDto with _$VendorPayoutInvoiceLineDto {
  const factory VendorPayoutInvoiceLineDto({
    @Default('') String description,
    @Default(0) double amount,
    @Default('NPR') String currency,
    required DateTime occurredUtc,
  }) = _VendorPayoutInvoiceLineDto;

  const VendorPayoutInvoiceLineDto._();

  factory VendorPayoutInvoiceLineDto.fromJson(Map<String, dynamic> json) =>
      _$VendorPayoutInvoiceLineDtoFromJson(json);

  VendorPayoutInvoiceLine toDomain() => VendorPayoutInvoiceLine(
    description: description,
    amount: Money(amount: amount, currency: currency),
    occurredAt: occurredUtc,
  );
}

/// Mirrors `GET /v1/payouts/{id}/invoice`.
@freezed
abstract class VendorPayoutInvoiceDto with _$VendorPayoutInvoiceDto {
  const factory VendorPayoutInvoiceDto({
    required String payoutId,
    @Default('') String invoiceNumber,
    @Default(1) int destination,
    @Default('') String destinationRef,
    @Default(0) double grossAmount,
    @Default(0) double feeAmount,
    @Default(0) double netAmount,
    @Default('NPR') String currency,
    required DateTime requestedUtc,
    @Default(1) int state,
    DateTime? paidUtc,
    String? providerPayoutId,
    @Default([]) List<VendorPayoutInvoiceLineDto> lines,
  }) = _VendorPayoutInvoiceDto;

  const VendorPayoutInvoiceDto._();

  factory VendorPayoutInvoiceDto.fromJson(Map<String, dynamic> json) =>
      _$VendorPayoutInvoiceDtoFromJson(json);

  VendorPayoutInvoice toDomain() => VendorPayoutInvoice(
    payoutId: payoutId,
    invoiceNumber: invoiceNumber,
    destinationKind: destination,
    destinationRef: destinationRef,
    grossAmount: Money(amount: grossAmount, currency: currency),
    feeAmount: Money(amount: feeAmount, currency: currency),
    netAmount: Money(amount: netAmount, currency: currency),
    requestedAt: requestedUtc,
    state: _payoutStateFromWire(state),
    paidAt: paidUtc,
    providerPayoutId: providerPayoutId,
    lines: lines.map((l) => l.toDomain()).toList(growable: false),
  );
}
