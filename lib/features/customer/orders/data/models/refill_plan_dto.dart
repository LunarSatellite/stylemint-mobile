import 'package:freezed_annotation/freezed_annotation.dart';

part 'refill_plan_dto.freezed.dart';
part 'refill_plan_dto.g.dart';

/// Mirrors the Orders module's `RefillPlanDto` —
/// `GET|POST /v1/customer/refill-plans`.
///
/// A prepared refill basket is a **proposal**. Nothing on the backend's
/// controller places an order, reserves stock or moves money, and nothing on
/// this client may imply otherwise.
///
/// There is deliberately **no score, confidence, risk, trust or rank** on this
/// record or on [RefillPlanLineDto]; a reflection test on the backend enforces
/// that, and a widget test here enforces that no such figure is reconstructed
/// or displayed. The steadiness rule the customer sets is the customer-legible
/// form of that gate — the number behind it is never serialised.
///
/// [headline] and [caveat] are the server's own words and are rendered
/// verbatim. The caveat is the reason this surface is allowed to exist: these
/// are estimates, and the platform cannot see what the customer has at home.
@freezed
abstract class RefillPlanDto with _$RefillPlanDto {
  const factory RefillPlanDto({
    required String planId,
    required String state,
    required DateTime preparedUtc,
    required DateTime expiresUtc,
    required String currency,
    required double includedSubtotal,
    required int includedLineCount,
    required String headline,
    required String caveat,
    @Default(<RefillPlanLineDto>[]) List<RefillPlanLineDto> lines,
    @Default(<RefillPlanGroupDto>[]) List<RefillPlanGroupDto> deliveryGroups,
  }) = _RefillPlanDto;

  factory RefillPlanDto.fromJson(Map<String, dynamic> json) =>
      _$RefillPlanDtoFromJson(json);
}

/// One line of a prepared basket.
///
/// [currentPrice] is nullable **on purpose**: when the item could not be
/// checked the backend sends null rather than backfilling what the customer
/// last paid. A null price is rendered as missing — never as a number, never
/// as zero.
///
/// [included] is the only thing that decides whether a line is in the basket.
/// An excluded line still appears (the customer is owed the explanation) but
/// it is never counted, never pre-selected and never quietly added.
@freezed
abstract class RefillPlanLineDto with _$RefillPlanLineDto {
  const factory RefillPlanLineDto({
    required String productId,
    required String productVariantId,
    required String productName,
    required int quantity,
    required double lastPaidPrice,
    required String lastPaidCurrency,
    required String check,
    required bool included,
    required DateTime lastPurchasedUtc,
    required int typicalIntervalDays,
    required int daysUntilExpected,
    required String reason,
    String? variantLabel,

    /// Carried so the DTO mirrors the contract. **Never drawn**: product
    /// photographs belong to product detail and nowhere else (owner
    /// directive, 2026-09-16), and a URL on the payload does not override
    /// that.
    String? thumbnailUrl,

    /// Null when the item could not be checked. Never backfilled and never
    /// rendered as a number.
    double? currentPrice,
    String? currentCurrency,
    String? excludedReason,
    @Default(<RefillAlternativeDto>[]) List<RefillAlternativeDto> alternatives,
  }) = _RefillPlanLineDto;

  const RefillPlanLineDto._();

  factory RefillPlanLineDto.fromJson(Map<String, dynamic> json) =>
      _$RefillPlanLineDtoFromJson(json);

  /// The Verify stage's verdict, as one of the five values the contract
  /// names. An unrecognised wire value reads as [RefillLineCheck.notVerified]
  /// — the conservative end, which excludes rather than assumes.
  RefillLineCheck get checkKind => switch (check) {
    'ready' => RefillLineCheck.ready,
    'priceChanged' => RefillLineCheck.priceChanged,
    'outOfStock' => RefillLineCheck.outOfStock,
    'variantUnavailable' => RefillLineCheck.variantUnavailable,
    _ => RefillLineCheck.notVerified,
  };

  /// True only when the server sent both prices and they differ. The client
  /// never infers a price change from one figure.
  bool get showsBothPrices =>
      checkKind == RefillLineCheck.priceChanged && currentPrice != null;
}

/// An alternative variant the customer may pick **themselves**.
///
/// Offered only where the customer set `allowSubstitutions`, which defaults to
/// false. Nothing here is pre-selected and nothing swaps itself: silence is a
/// no.
@freezed
abstract class RefillAlternativeDto with _$RefillAlternativeDto {
  const factory RefillAlternativeDto({
    required String productVariantId,
    required String sku,
    required double price,
    required String currency,
  }) = _RefillAlternativeDto;

  factory RefillAlternativeDto.fromJson(Map<String, dynamic> json) =>
      _$RefillAlternativeDtoFromJson(json);
}

/// Which included lines come from the same seller and would travel together.
/// Consolidation of what Orders already knows — not a delivery quote, not a
/// carrier choice and not an ETA.
@freezed
abstract class RefillPlanGroupDto with _$RefillPlanGroupDto {
  const factory RefillPlanGroupDto({
    required String vendorAccountId,
    required String vendorName,
    required int lineCount,
    required double subtotal,
    required String currency,
  }) = _RefillPlanGroupDto;

  factory RefillPlanGroupDto.fromJson(Map<String, dynamic> json) =>
      _$RefillPlanGroupDtoFromJson(json);
}

/// What comes back from `POST {planId}/confirm`: the customer's recorded yes
/// and the lines, so their own cart can pick them up.
///
/// [note] states the boundary in the payload itself and is rendered verbatim.
/// Nothing was ordered, reserved or charged.
@freezed
abstract class RefillPlanHandoffDto with _$RefillPlanHandoffDto {
  const factory RefillPlanHandoffDto({
    required String planId,
    required DateTime confirmedUtc,
    required String currency,
    required double subtotal,
    required String note,
    @Default(<RefillHandoffLineDto>[]) List<RefillHandoffLineDto> lines,
  }) = _RefillPlanHandoffDto;

  factory RefillPlanHandoffDto.fromJson(Map<String, dynamic> json) =>
      _$RefillPlanHandoffDtoFromJson(json);
}

@freezed
abstract class RefillHandoffLineDto with _$RefillHandoffLineDto {
  const factory RefillHandoffLineDto({
    required String productId,
    required String productVariantId,
    required int quantity,
  }) = _RefillHandoffLineDto;

  factory RefillHandoffLineDto.fromJson(Map<String, dynamic> json) =>
      _$RefillHandoffLineDtoFromJson(json);
}

/// The outcome of the Verify stage for one line, as the contract names it.
enum RefillLineCheck {
  /// Could not be checked. **Excluded, not assumed fine** — and its current
  /// price is null.
  notVerified,

  /// Still sold, in stock, at the price this customer last paid.
  ready,

  /// Still sold and in stock, at a different price. Both figures are shown.
  priceChanged,

  /// Not enough in stock for the usual quantity.
  outOfStock,

  /// The exact variant bought is no longer purchasable.
  variantUnavailable,
}
