import 'package:flutter/foundation.dart' show immutable;

/// How a shipping option reaches the buyer (backend `ShippingOptionKind`).
enum ShippingOptionKind { standard, express, pickup, unknown }

/// One way a product ships (backend `ProductShippingOptionDto`).
@immutable
class ProductShippingOption {
  const ProductShippingOption({
    required this.kind,
    this.feeAmount = 0,
    this.feeCurrency = '',
    this.estimatedDaysMin = 0,
    this.estimatedDaysMax = 0,
    this.isEnabled = true,
  });

  final ShippingOptionKind kind;
  final double feeAmount;
  final String feeCurrency;

  /// Transit days once the product has shipped.
  final int estimatedDaysMin;
  final int estimatedDaysMax;
  final bool isEnabled;

  /// An enabled option that travels to the buyer (not a store pickup).
  bool get isDelivery => isEnabled && kind != ShippingOptionKind.pickup;
}

/// What the product page can promise about delivery: the vendor's processing
/// time plus the transit time of the product's shipping options.
@immutable
class ProductDelivery {
  const ProductDelivery({
    this.processingTimeDays = 0,
    this.shippingOptions = const [],
  });

  final int processingTimeDays;
  final List<ProductShippingOption> shippingOptions;

  /// "Delivers in 3–5 days" when a delivery option carries transit days,
  /// "Ships in 2 days" from processing time alone, or null when neither is
  /// known (the line is then hidden).
  String? get estimateLabel {
    final processing = processingTimeDays < 0 ? 0 : processingTimeDays;
    final timed = [
      for (final option in shippingOptions)
        if (option.isDelivery && option.estimatedDaysMax > 0) option,
    ];
    if (timed.isNotEmpty) {
      var fastest = 1 << 30;
      var slowest = 0;
      for (final option in timed) {
        final min = option.estimatedDaysMin > 0
            ? option.estimatedDaysMin
            : option.estimatedDaysMax;
        if (min < fastest) fastest = min;
        if (option.estimatedDaysMax > slowest) {
          slowest = option.estimatedDaysMax;
        }
      }
      final from = processing + fastest;
      final to = processing + (slowest < fastest ? fastest : slowest);
      return from == to
          ? 'Delivers in ${_days(from)}'
          : 'Delivers in $from–$to days';
    }
    if (processing > 0) return 'Ships in ${_days(processing)}';
    return null;
  }

  /// True only when an enabled delivery option costs nothing.
  bool get hasFreeDelivery => shippingOptions.any(
    (option) => option.isDelivery && option.feeAmount <= 0,
  );

  static String _days(int days) => days == 1 ? '1 day' : '$days days';
}
