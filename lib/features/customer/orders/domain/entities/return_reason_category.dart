import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// What is wrong with a returned item (return pickup contract §4). Decides
/// who pays the rider: the seller for everything but [changedMind].
///
/// [unspecified] is what an older return (or an older app) carries; it is
/// never offered in the picker.
enum ReturnReasonCategory {
  damaged('Damaged', 'Damaged'),
  wrongItem('WrongItem', 'Wrong item'),
  defective('Defective', "Doesn't work"),
  notAsDescribed('NotAsDescribed', 'Not as described'),
  changedMind('ChangedMind', 'Changed my mind'),
  unspecified('Unspecified', 'Other');

  const ReturnReasonCategory(this.wire, this.label);

  final String wire;
  final String label;

  /// The choices a buyer is shown, in this order.
  static const List<ReturnReasonCategory> choices = [
    damaged,
    wrongItem,
    defective,
    notAsDescribed,
    changedMind,
  ];

  /// Null when absent; [unspecified] for a value this app does not know.
  static ReturnReasonCategory? fromWire(Object? value) {
    final raw = value?.toString().trim().toLowerCase().replaceAll('_', '');
    if (raw == null || raw.isEmpty) return null;
    for (final category in values) {
      if (category.wire.toLowerCase() == raw) return category;
    }
    return unspecified;
  }

  /// The buyer pays the pickup fare (out of the refund) only here.
  bool get buyerPaysPickup => this == changedMind;
}

/// `GET /v1/orders/{orderNumber}/returns/pickup-quote` — what a "changed my
/// mind" pickup will cost, shown before the buyer submits.
class ReturnPickupQuote {
  const ReturnPickupQuote({
    required this.estimate,
    required this.upTo,
    this.itemTotal,
    this.refundIfChangedMind,
    this.method,
    this.distanceKm,
  });

  factory ReturnPickupQuote.fromJson(Map<String, dynamic> json) {
    final estimate = moneyFromJson(json['estimate']);
    final upTo = moneyFromJson(json['upTo']) ?? estimate;
    return ReturnPickupQuote(
      estimate: estimate ?? upTo ?? const Money(amount: 0, currency: 'NPR'),
      upTo: upTo ?? const Money(amount: 0, currency: 'NPR'),
      itemTotal: moneyFromJson(json['itemTotal']),
      refundIfChangedMind: moneyFromJson(json['refundIfChangedMind']),
      method: json['method']?.toString(),
      distanceKm: switch (json['distanceKm']) {
        final num v => v.toDouble(),
        _ => null,
      },
    );
  }

  final Money estimate;

  /// The cap: the buyer never pays more than this (contract D2).
  final Money upTo;
  final Money? itemTotal;
  final Money? refundIfChangedMind;
  final String? method;
  final double? distanceKm;
}
