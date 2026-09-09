import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'earnings_dto.freezed.dart';
part 'earnings_dto.g.dart';

// Response shape: { availableValue, pendingValue, lifetimeValue, currency }
// thisMonthEarnings, totalCommission, totalPayouts are not provided by this
// endpoint — they default to zero until a confirmed source is wired.
@freezed
abstract class EarningsSummaryDto with _$EarningsSummaryDto {
  const factory EarningsSummaryDto({
    @Default(0.0) double availableValue,
    @Default(0.0) double pendingValue,
    @Default(0.0) double lifetimeValue,
    @Default('NPR') String currency,
  }) = _EarningsSummaryDto;

  const EarningsSummaryDto._();

  factory EarningsSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$EarningsSummaryDtoFromJson(json);

  EarningsSummary toDomain() => EarningsSummary(
    totalEarnings: Money(amount: lifetimeValue, currency: currency),
    availableBalance: Money(amount: availableValue, currency: currency),
    pendingBalance: Money(amount: pendingValue, currency: currency),
    totalCommission: 0,
    thisMonthEarnings: Money(amount: 0, currency: currency),
    totalPayouts: Money(amount: 0, currency: currency),
  );
}

@freezed
abstract class EarningsLedgerEntryDto with _$EarningsLedgerEntryDto {
  const factory EarningsLedgerEntryDto({
    required String id,
    required String type,
    required String description,
    required double amountAmount,
    @Default('NPR') String amountCurrency,
    required DateTime createdAt,
    String? reference,
  }) = _EarningsLedgerEntryDto;

  const EarningsLedgerEntryDto._();

  factory EarningsLedgerEntryDto.fromJson(Map<String, dynamic> json) =>
      _$EarningsLedgerEntryDtoFromJson(json);

  EarningsLedgerEntry toDomain() {
    final typeEnum = LedgerEntryType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => LedgerEntryType.commission,
    );
    return EarningsLedgerEntry(
      id: id,
      type: typeEnum,
      description: description,
      amount: Money(amount: amountAmount, currency: amountCurrency),
      createdAt: createdAt,
      reference: reference,
    );
  }
}

// Backend `PayoutDestinationKind`: NIMB=1, Laxmi=2, PayPal=3, eSewa=4.
const int _kindNimbBank = 1;
const int _kindLaxmiBank = 2;
const int _kindPayPal = 3;
const int _kindEsewa = 4;

@freezed
abstract class PayoutMethodDto with _$PayoutMethodDto {
  const factory PayoutMethodDto({
    @Default('') String id,
    @Default(1) int kind,
    @Default('') String label,
    @JsonKey(name: 'isDefault') @Default(false) bool isPrimary,
    @Default(0) int status,
  }) = _PayoutMethodDto;

  const PayoutMethodDto._();

  factory PayoutMethodDto.fromJson(Map<String, dynamic> json) =>
      _$PayoutMethodDtoFromJson(json);

  PayoutMethod toDomain() {
    final type = switch (kind) {
      _kindNimbBank => PayoutMethodType.nimbBank,
      _kindLaxmiBank => PayoutMethodType.laxmiBank,
      _kindEsewa => PayoutMethodType.esewa,
      _kindPayPal => PayoutMethodType.paypal,
      _ => PayoutMethodType.nimbBank,
    };
    return PayoutMethod(id: id, type: type, label: label, isPrimary: isPrimary);
  }
}

// ignore_for_file: invalid_annotation_target

// PayoutDestinationKind: 1=NIMB Bank, 2=Laxmi Bank, 3=PayPal, 4=eSewa
String _destinationLabel(int dest) => switch (dest) {
  1 => 'NIMB Bank',
  2 => 'Laxmi Bank',
  3 => 'PayPal',
  4 => 'eSewa',
  _ => 'Bank',
};

@freezed
abstract class PayoutDto with _$PayoutDto {
  const factory PayoutDto({
    required DateTime requestedUtc,
    @Default('') String id,
    @Default(0.0) double requestedAmountValue,
    @Default('NPR') String requestedAmountCurrency,
    @Default(0.0) double feeAmountValue,
    @Default('NPR') String feeAmountCurrency,
    @Default(0.0) double netAmountValue,
    @Default('NPR') String netAmountCurrency,
    @Default(1) int state,
    @Default(1) int mode,
    @Default(1) int destination,
    String? destinationRef,
    String? providerPayoutId,
    String? failureCode,
    String? failureMessage,
    DateTime? paidUtc,
  }) = _PayoutDto;

  const PayoutDto._();

  factory PayoutDto.fromJson(Map<String, dynamic> json) =>
      _$PayoutDtoFromJson(json);

  PayoutRecord toDomain() {
    final stateEnum = switch (state) {
      1 => PayoutState.requested,
      2 => PayoutState.processing,
      3 => PayoutState.paid,
      4 => PayoutState.failed,
      5 => PayoutState.held,
      _ => PayoutState.requested,
    };
    return PayoutRecord(
      id: id,
      requestedAmount: Money(
        amount: requestedAmountValue,
        currency: requestedAmountCurrency,
      ),
      feeAmount: Money(
        amount: feeAmountValue,
        currency: feeAmountCurrency,
      ),
      netAmount: Money(
        amount: netAmountValue,
        currency: netAmountCurrency,
      ),
      state: stateEnum,
      mode: mode == 2 ? PayoutMode.onDemand : PayoutMode.automaticWeekly,
      destinationLabel: _destinationLabel(destination),
      destinationRef: destinationRef,
      requestedAt: requestedUtc,
      paidAt: paidUtc,
    );
  }
}

@freezed
abstract class PayoutInvoiceLineDto with _$PayoutInvoiceLineDto {
  const factory PayoutInvoiceLineDto({
    required String description,
    required double amount,
    required String currency,
    required DateTime occurredUtc,
  }) = _PayoutInvoiceLineDto;

  const PayoutInvoiceLineDto._();

  factory PayoutInvoiceLineDto.fromJson(Map<String, dynamic> json) =>
      _$PayoutInvoiceLineDtoFromJson(json);

  PayoutInvoiceLine toDomain() => PayoutInvoiceLine(
    description: description,
    amount: Money(amount: amount, currency: currency),
    occurredAt: occurredUtc,
  );
}

@freezed
abstract class PayoutInvoiceApiDto with _$PayoutInvoiceApiDto {
  const factory PayoutInvoiceApiDto({
    required String payoutId,
    @Default('') String invoiceNumber,
    @Default(1) int payeeKind,
    @Default(1) int mode,
    @Default(1) int destination,
    @Default('') String destinationRef,
    @Default(0.0) double grossAmount,
    @Default(0.0) double feeAmount,
    @Default(0.0) double netAmount,
    @Default('NPR') String currency,
    required DateTime requestedUtc,
    required DateTime pendingUntilUtc,
    DateTime? paidUtc,
    @Default(1) int state,
    String? providerPayoutId,
    @Default(<PayoutInvoiceLineDto>[]) List<PayoutInvoiceLineDto> lines,
  }) = _PayoutInvoiceApiDto;

  const PayoutInvoiceApiDto._();

  factory PayoutInvoiceApiDto.fromJson(Map<String, dynamic> json) =>
      _$PayoutInvoiceApiDtoFromJson(json);

  PayoutInvoice toDomain() {
    final stateEnum = switch (state) {
      1 => PayoutState.requested,
      2 => PayoutState.processing,
      3 => PayoutState.paid,
      4 => PayoutState.failed,
      5 => PayoutState.held,
      _ => PayoutState.requested,
    };
    return PayoutInvoice(
      payoutId: payoutId,
      invoiceNumber: invoiceNumber,
      destinationLabel: _destinationLabel(destination),
      destinationRef: destinationRef.isNotEmpty ? destinationRef : null,
      grossAmount: Money(amount: grossAmount, currency: currency),
      feeAmount: Money(amount: feeAmount, currency: currency),
      netAmount: Money(amount: netAmount, currency: currency),
      requestedAt: requestedUtc,
      paidAt: paidUtc,
      state: stateEnum,
      providerPayoutId: providerPayoutId,
      lines: lines.map((l) => l.toDomain()).toList(growable: false),
    );
  }
}
