import 'package:freezed_annotation/freezed_annotation.dart';

part 'replenishment_rules_dto.freezed.dart';
part 'replenishment_rules_dto.g.dart';

/// How much the customer wants the platform to do once a refill looks due.
///
/// **There are exactly two values, and there is no third.** The platform never
/// places an order: §5.9 forbids it from setting a price, reserving stock or
/// moving money on a customer's behalf, so the ladder stops at a basket the
/// customer opens and approves. A backend test fails if a third value is
/// added; this client must never render, imply or offer one.
enum ReplenishmentAutomationLevel {
  /// Show the suggestion on a screen the customer opened. The default.
  remindOnly('remindOnly'),

  /// Also assemble a refill basket the customer can review. Still a proposal:
  /// no order, no hold, no charge.
  prepareBasket('prepareBasket');

  const ReplenishmentAutomationLevel(this.wire);

  final String wire;

  /// An unrecognised wire value reads as [remindOnly] — the quieter end, and
  /// the value every row written before this column existed reads back as.
  static ReplenishmentAutomationLevel fromWire(String? value) =>
      value == prepareBasket.wire ? prepareBasket : remindOnly;
}

/// How regular a buying pattern has to look before the customer wants to hear
/// about it.
///
/// This is the customer-legible form of an internal confidence threshold. The
/// number behind each option lives on the backend, is never serialised and is
/// never shown. The customer picks a steadiness, not a percentage.
enum ReplenishmentSteadiness {
  /// Anything the predictor already stands behind. The default.
  any('any'),

  /// Only patterns that repeat on a fairly even cycle.
  steady('steady'),

  /// Only patterns that repeat on a very even cycle.
  verySteady('verySteady');

  const ReplenishmentSteadiness(this.wire);

  final String wire;

  static ReplenishmentSteadiness fromWire(String? value) => switch (value) {
    'steady' => steady,
    'verySteady' => verySteady,
    _ => any,
  };
}

/// The rules this customer set — `GET /v1/customer/reorder-suggestions/
/// preference`, and the reply to both `PUT .../rules` and `PUT .../pause`.
///
/// Additive: `enabled` and `updatedUtc` keep their meanings, and every field
/// after them has a default that reproduces the behaviour before these rules
/// existed. There is **no confidence threshold** on this record.
@freezed
abstract class ReplenishmentPreferenceDto with _$ReplenishmentPreferenceDto {
  const factory ReplenishmentPreferenceDto({
    @Default(false) bool enabled,
    DateTime? updatedUtc,
    @Default('remindOnly') String automationLevel,
    @Default('any') String steadiness,
    @Default(7) int leadTimeDays,
    @Default(7) int minDaysBetweenPlans,
    double? maxPlanAmount,
    String? maxPlanCurrency,
    @Default(false) bool allowSubstitutions,
    DateTime? pausedUntilUtc,
    @Default(false) bool paused,
  }) = _ReplenishmentPreferenceDto;

  const ReplenishmentPreferenceDto._();

  factory ReplenishmentPreferenceDto.fromJson(Map<String, dynamic> json) =>
      _$ReplenishmentPreferenceDtoFromJson(json);

  ReplenishmentAutomationLevel get automation =>
      ReplenishmentAutomationLevel.fromWire(automationLevel);

  ReplenishmentSteadiness get steadinessRule =>
      ReplenishmentSteadiness.fromWire(steadiness);

  /// True when the customer asked for a basket to be prepared. A plan is only
  /// ever built at this level, so it is also what decides whether a link to
  /// the refill basket can honestly be offered.
  bool get prepares => automation == ReplenishmentAutomationLevel.prepareBasket;

  /// The rules as a request body, so an edit can change one field and send
  /// the whole set (the backend replaces them as one, so a half-applied rule
  /// set is never reachable).
  ReplenishmentRulesRequest toRequest() => ReplenishmentRulesRequest(
    automationLevel: automation,
    steadiness: steadinessRule,
    leadTimeDays: leadTimeDays,
    minDaysBetweenPlans: minDaysBetweenPlans,
    maxPlanAmount: maxPlanAmount,
    maxPlanCurrency: maxPlanCurrency,
    allowSubstitutions: allowSubstitutions,
  );
}

/// The customer's rules, sent complete. The client validates the same ranges
/// the backend does, so an out-of-range value is refused here rather than
/// making a round trip to be refused there.
@immutable
class ReplenishmentRulesRequest {
  const ReplenishmentRulesRequest({
    required this.automationLevel,
    required this.steadiness,
    required this.leadTimeDays,
    required this.minDaysBetweenPlans,
    required this.maxPlanAmount,
    required this.maxPlanCurrency,
    required this.allowSubstitutions,
  });

  /// `ReplenishmentPreference.MinLeadTimeDays` / `MaxLeadTimeDays`.
  static const int minLeadTimeDays = 1;
  static const int maxLeadTimeDays = 30;

  /// `MinDaysBetweenPlansFloor` / `MinDaysBetweenPlansCeiling`.
  static const int minFrequencyDays = 1;
  static const int maxFrequencyDays = 90;

  final ReplenishmentAutomationLevel automationLevel;
  final ReplenishmentSteadiness steadiness;
  final int leadTimeDays;
  final int minDaysBetweenPlans;
  final double? maxPlanAmount;
  final String? maxPlanCurrency;
  final bool allowSubstitutions;

  /// Why these rules cannot be sent, or null when they can. The wording is
  /// the customer's, not the field's.
  String? get validationError {
    if (leadTimeDays < minLeadTimeDays || leadTimeDays > maxLeadTimeDays) {
      return 'Lead time has to be between $minLeadTimeDays and '
          '$maxLeadTimeDays days.';
    }
    if (minDaysBetweenPlans < minFrequencyDays ||
        minDaysBetweenPlans > maxFrequencyDays) {
      return 'Leave at least $minFrequencyDays day and at most '
          '$maxFrequencyDays days between baskets.';
    }
    final limit = maxPlanAmount;
    if (limit != null) {
      if (limit <= 0) return 'A spending limit has to be more than zero.';
      if ((maxPlanCurrency ?? '').trim().isEmpty) {
        return 'A spending limit needs a currency.';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'automationLevel': automationLevel.wire,
    'steadiness': steadiness.wire,
    'leadTimeDays': leadTimeDays,
    'minDaysBetweenPlans': minDaysBetweenPlans,
    'maxPlanAmount': maxPlanAmount,
    'maxPlanCurrency': maxPlanAmount == null ? null : maxPlanCurrency,
    'allowSubstitutions': allowSubstitutions,
  };

  ReplenishmentRulesRequest copyWith({
    ReplenishmentAutomationLevel? automationLevel,
    ReplenishmentSteadiness? steadiness,
    int? leadTimeDays,
    int? minDaysBetweenPlans,
    Object? maxPlanAmount = _unset,
    Object? maxPlanCurrency = _unset,
    bool? allowSubstitutions,
  }) => ReplenishmentRulesRequest(
    automationLevel: automationLevel ?? this.automationLevel,
    steadiness: steadiness ?? this.steadiness,
    leadTimeDays: leadTimeDays ?? this.leadTimeDays,
    minDaysBetweenPlans: minDaysBetweenPlans ?? this.minDaysBetweenPlans,
    maxPlanAmount: maxPlanAmount == _unset
        ? this.maxPlanAmount
        : (maxPlanAmount as num?)?.toDouble(),
    maxPlanCurrency: maxPlanCurrency == _unset
        ? this.maxPlanCurrency
        : maxPlanCurrency as String?,
    allowSubstitutions: allowSubstitutions ?? this.allowSubstitutions,
  );

  static const Object _unset = Object();

  @override
  bool operator ==(Object other) =>
      other is ReplenishmentRulesRequest &&
      other.automationLevel == automationLevel &&
      other.steadiness == steadiness &&
      other.leadTimeDays == leadTimeDays &&
      other.minDaysBetweenPlans == minDaysBetweenPlans &&
      other.maxPlanAmount == maxPlanAmount &&
      other.maxPlanCurrency == maxPlanCurrency &&
      other.allowSubstitutions == allowSubstitutions;

  @override
  int get hashCode => Object.hash(
    automationLevel,
    steadiness,
    leadTimeDays,
    minDaysBetweenPlans,
    maxPlanAmount,
    maxPlanCurrency,
    allowSubstitutions,
  );
}
