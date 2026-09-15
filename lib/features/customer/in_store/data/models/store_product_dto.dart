import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// One product of `GET /v1/public/vendors/{vendorAccountId}/products` — the
/// backend's list `ProductDto`: `{ id, name, variants: [{ isDefault,
/// priceAmount, priceCurrency }], images: [{ cdnUrl, isPrimary, sortOrder }],
/// activeFlashSale?: { salePrice, currency } }`. List rows carry just the
/// default variant and the primary image.
class StoreProductDto {
  const StoreProductDto({
    required this.id,
    required this.name,
    required this.priceAmount,
    required this.currency,
    this.imagePath,
  });

  factory StoreProductDto.fromJson(Map<String, dynamic> json) {
    final variant = _preferred(json['variants'], 'isDefault');
    final image = _preferred(json['images'], 'isPrimary');
    final sale = json['activeFlashSale'];
    final salePrice = sale is Map
        ? readOptionalDouble(sale['salePrice'])
        : null;

    return StoreProductDto(
      id: readString(json['id']),
      name: readString(json['name']),
      priceAmount:
          salePrice ?? readOptionalDouble(variant?['priceAmount']) ?? 0,
      currency:
          readOptionalString(
            salePrice != null && sale is Map
                ? sale['currency']
                : variant?['priceCurrency'],
          ) ??
          'NPR',
      imagePath: readOptionalString(image?['cdnUrl']),
    );
  }

  /// The `items` of the page; products without an id can't be opened, so
  /// they are dropped.
  static List<StoreProductDto> listFromPage(Object? raw) => readPagedItems(raw)
      .map(StoreProductDto.fromJson)
      .where((product) => product.id.isNotEmpty)
      .toList(growable: false);

  final String id;
  final String name;
  final double priceAmount;
  final String currency;

  /// The CDN path or URL of the main photo, as the backend sent it.
  final String? imagePath;

  StoreProduct toDomain() => StoreProduct(
    id: id,
    name: name,
    price: Money(amount: priceAmount, currency: currency),
    imageUrl: absoluteMediaUrl(imagePath),
  );

  /// The entry of the [raw] list whose [flag] is true, else the first one.
  static Map<String, dynamic>? _preferred(Object? raw, String flag) {
    if (raw is! List) return null;
    final entries = raw.whereType<Map<String, dynamic>>();
    for (final entry in entries) {
      if (readBool(entry[flag])) return entry;
    }
    return entries.firstOrNull;
  }
}
