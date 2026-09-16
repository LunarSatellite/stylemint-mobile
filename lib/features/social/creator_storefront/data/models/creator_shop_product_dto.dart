import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_shop_product.dart';
import 'package:stylemint_mobile_frontend/shared/data/product_reel_ref_json.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/product_reel_ref.dart';

/// Reels `CreatorShopProductDto`.
class CreatorShopProductDto {
  const CreatorShopProductDto({
    required this.productId,
    required this.name,
    required this.vendorAccountId,
    required this.vendorDisplayName,
    this.primaryImageUrl,
    this.priceAmount,
    this.priceCurrency,
    this.reelCount = 0,
    this.lastTaggedUtc,
    this.reel,
  });

  factory CreatorShopProductDto.fromJson(Map<String, dynamic> json) =>
      CreatorShopProductDto(
        productId: readString(json['productId']),
        name: readString(json['name']),
        primaryImageUrl: readOptionalString(json['primaryImageUrl']),
        priceAmount: readOptionalDouble(json['priceAmount']),
        priceCurrency: readOptionalString(json['priceCurrency']),
        vendorAccountId: readString(json['vendorAccountId']),
        vendorDisplayName: readString(json['vendorDisplayName']),
        reelCount: readInt(json['reelCount']),
        lastTaggedUtc: readDate(json['lastTaggedUtc']),
        // Nullable and not on the server yet.
        reel: readProductReelRef(json['reel']),
      );

  final String productId;
  final String name;
  final String? primaryImageUrl;

  /// Null when the product has no variant.
  final double? priceAmount;
  final String? priceCurrency;
  final String vendorAccountId;
  final String vendorDisplayName;
  final int reelCount;
  final DateTime? lastTaggedUtc;

  /// The reel this product is sold through, when the payload carries one.
  final ProductReelRef? reel;

  static const String defaultCurrency = 'NPR';

  /// Null when the product can't be shown as a card: no id, no name or no
  /// price (a product without a variant can't be bought).
  CreatorShopProduct? toDomain() {
    final amount = priceAmount;
    if (productId.isEmpty || name.isEmpty || amount == null || amount < 0) {
      return null;
    }
    return CreatorShopProduct(
      productId: productId,
      name: name,
      price: Money(amount: amount, currency: priceCurrency ?? defaultCurrency),
      vendorAccountId: vendorAccountId,
      vendorDisplayName: vendorDisplayName,
      imageUrl: primaryImageUrl,
      reelCount: reelCount < 0 ? 0 : reelCount,
      lastTaggedUtc: lastTaggedUtc,
      reel: reel,
    );
  }
}
