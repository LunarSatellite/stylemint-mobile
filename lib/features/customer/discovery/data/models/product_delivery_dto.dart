import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_delivery.dart';

/// Delivery fields of `GET /v1/public/products/{id}` (backend `ProductDto`):
/// `processingTimeDays` and `shippingOptions[] { kind, feeAmount, feeCurrency,
/// estimatedDaysMin, estimatedDaysMax, isEnabled }`. Read by hand next to the
/// freezed product DTO, so that DTO needs no regeneration.
abstract final class ProductDeliveryDto {
  static ProductDelivery fromJson(Map<String, dynamic> json) {
    final options = json['shippingOptions'];
    return ProductDelivery(
      processingTimeDays: readInt(json['processingTimeDays']),
      shippingOptions: [
        if (options is List)
          for (final option in options)
            if (option is Map<String, dynamic>) _option(option),
      ],
    );
  }

  static ProductShippingOption _option(Map<String, dynamic> json) {
    final enabled = json['isEnabled'];
    return ProductShippingOption(
      kind: parseKind(json['kind']),
      feeAmount: readOptionalDouble(json['feeAmount']) ?? 0,
      feeCurrency: readString(json['feeCurrency']),
      estimatedDaysMin: readInt(json['estimatedDaysMin']),
      estimatedDaysMax: readInt(json['estimatedDaysMax']),
      isEnabled: enabled is! bool || enabled,
    );
  }

  /// Accepts the enum as its number (1 Standard, 2 Express, 3 Pickup) or name.
  static ShippingOptionKind parseKind(Object? raw) {
    final value = raw is String ? raw.trim().toLowerCase() : raw;
    return switch (value) {
      1 || '1' || 'standard' => ShippingOptionKind.standard,
      2 || '2' || 'express' => ShippingOptionKind.express,
      3 || '3' || 'pickup' => ShippingOptionKind.pickup,
      _ => ShippingOptionKind.unknown,
    };
  }
}
