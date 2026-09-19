import 'package:stylemint_mobile_frontend/shared/data/product_reel_ref_json.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/product_reel_vm.dart';

/// Reads `GET /v1/public/products/{id}` into the Mall's product view model.
///
/// Only the fields a Mall tile draws are taken. A payload with no usable name
/// returns null, and the caller omits that suggestion entirely — a tile whose
/// subject is an empty string is a placeholder implying a product exists.
///
/// The product photo is read but is never drawn by a tile: the Mall is
/// video-first and photos live on the product details page only (owner
/// directive, 2026-09-16). It rides on the view model because that page uses
/// it.
MallProductVm? suggestedProductFromJson(
  Map<String, dynamic> json, {
  required String fallbackId,
}) {
  final name = (json['name'] as String? ?? '').trim();
  if (name.isEmpty) return null;

  final id = (json['id'] as String? ?? '').trim();
  final variants = (json['variants'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  final chosen = variants.isEmpty
      ? null
      : variants.firstWhere(
          (v) => v['isDefault'] == true,
          orElse: () => variants.first,
        );

  // Price lives per-SKU on this payload; there is no top-level price. With no
  // variant at all we still have a real product, just no figure to show.
  final amount = _amount(chosen?['priceAmount']);
  final currency = (chosen?['priceCurrency'] as String? ?? 'NPR').trim();

  final images =
      (json['images'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false)
        ..sort(
          (a, b) => _amount(a['sortOrder']).compareTo(_amount(b['sortOrder'])),
        );

  final quantity = _amount(chosen?['quantityOnHand']).toInt();
  final tracks = chosen?['trackInventory'] != false;

  return MallProductVm(
    id: id.isEmpty ? fallbackId : id,
    name: name,
    price: Money(amount: amount, currency: currency.isEmpty ? 'NPR' : currency),
    brandName: (json['vendorDisplayName'] as String?)?.trim().isEmpty ?? true
        ? null
        : (json['vendorDisplayName'] as String).trim(),
    imageUrl: images.isEmpty ? null : images.first['url'] as String?,
    rating: _amount(json['averageRating']) > 0
        ? _amount(json['averageRating'])
        : null,
    reviewCount: _amount(json['reviewCount']).toInt(),
    reel: readProductReelRef(json['reel'])?.toVm(),
    // More than one SKU means a size or colour still has to be chosen, so the
    // tile sends the shopper to the product page rather than guessing.
    requiresOptionSelection: variants.length > 1,
    defaultVariantId: chosen?['id'] as String?,
    isInStock: !tracks || quantity > 0,
  );
}

double _amount(Object? raw) => switch (raw) {
  final num value => value.toDouble(),
  final String value => double.tryParse(value) ?? 0,
  _ => 0,
};
