import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_option.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/product_reel_ref.dart';

/// Full product detail returned by GET /v1/products/{id}.
class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.price,
    this.compareAtPrice,
    required this.rating,
    required this.reviewCount,
    required this.vendorId,
    required this.vendorName,
    required this.vendorAvatarUrl,
    required this.isInStock,
    this.stockCount,
    required this.variants,
    required this.specifications,
    required this.shippingInfo,
    required this.isSaved,
    required this.isInCart,
    this.defaultVariantId,
    this.flashSaleEndsAt,
    this.delivery,
    this.options = const <ProductOption>[],
    this.optionVariants = const <ProductVariantOption>[],
  });

  final String id;
  final String name;
  final String description;
  final List<String> images;
  final Money price;
  final Money? compareAtPrice;
  final double rating;
  final int reviewCount;
  final String vendorId;
  final String vendorName;
  final String vendorAvatarUrl;
  final bool isInStock;
  final int? stockCount;
  final List<ProductVariant> variants;
  final Map<String, String> specifications;
  final String shippingInfo;
  final bool isSaved;
  final bool isInCart;

  /// Backend SKU to use where the product has no customer choice to make.
  final String? defaultVariantId;

  /// When set, [price] is a flash-sale price and [compareAtPrice] holds the
  /// original price — the sale ends at this instant.
  final DateTime? flashSaleEndsAt;

  /// Processing time and shipping options, for the delivery estimate.
  final ProductDelivery? delivery;

  /// Size / colour / material chooser rows, in `sortOrder`. Empty for a
  /// product that defines no options — the page then behaves as it always has.
  final List<ProductOption> options;

  /// Every variant seen through its option values, for resolving a choice.
  final List<ProductVariantOption> optionVariants;

  ProductDetail copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? images,
    Money? price,
    Money? compareAtPrice,
    double? rating,
    int? reviewCount,
    String? vendorId,
    String? vendorName,
    String? vendorAvatarUrl,
    bool? isInStock,
    int? stockCount,
    List<ProductVariant>? variants,
    Map<String, String>? specifications,
    String? shippingInfo,
    bool? isSaved,
    bool? isInCart,
    String? defaultVariantId,
    DateTime? flashSaleEndsAt,
    ProductDelivery? delivery,
    List<ProductOption>? options,
    List<ProductVariantOption>? optionVariants,
    bool clearCompareAtPrice = false,
    bool clearStockCount = false,
  }) {
    return ProductDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      images: images ?? this.images,
      price: price ?? this.price,
      compareAtPrice: clearCompareAtPrice
          ? null
          : (compareAtPrice ?? this.compareAtPrice),
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorAvatarUrl: vendorAvatarUrl ?? this.vendorAvatarUrl,
      isInStock: isInStock ?? this.isInStock,
      stockCount: clearStockCount ? null : (stockCount ?? this.stockCount),
      variants: variants ?? this.variants,
      specifications: specifications ?? this.specifications,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      isSaved: isSaved ?? this.isSaved,
      isInCart: isInCart ?? this.isInCart,
      defaultVariantId: defaultVariantId ?? this.defaultVariantId,
      flashSaleEndsAt: flashSaleEndsAt ?? this.flashSaleEndsAt,
      delivery: delivery ?? this.delivery,
      options: options ?? this.options,
      optionVariants: optionVariants ?? this.optionVariants,
    );
  }
}

/// A variant option group — e.g. "Size" with values ["S", "M", "L"].
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.name,
    required this.values,
    required this.type,
    this.optionVariantIds = const {},
  });

  final String id;
  final String name;
  final List<String> values;
  final String type;

  /// Display option → backend ProductVariant ID. Empty for legacy mock groups.
  final Map<String, String> optionVariantIds;

  ProductVariant copyWith({
    String? id,
    String? name,
    List<String>? values,
    String? type,
    Map<String, String>? optionVariantIds,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      values: values ?? this.values,
      type: type ?? this.type,
      optionVariantIds: optionVariantIds ?? this.optionVariantIds,
    );
  }
}

/// A single review shown in the preview section.
class ProductReviewPreview {
  const ProductReviewPreview({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String userName;
  final String userAvatarUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;
}

/// Listing-level provenance record — backend `ProductPassport`.
class ProductPassport {
  const ProductPassport({
    required this.vendorBusinessName,
    required this.vendorIdentityVerified,
    required this.vendorOnPlatformSince,
    required this.authenticityStatement,
    this.schemaVersion = 1,
    this.revision = '',
    this.generatedAt,
    this.provenance = const <ProductProvenanceFact>[],
  });

  final String vendorBusinessName;
  final bool vendorIdentityVerified;
  final DateTime? vendorOnPlatformSince;
  final String authenticityStatement;
  final int schemaVersion;
  final String revision;
  final DateTime? generatedAt;
  final List<ProductProvenanceFact> provenance;
}

class ProductProvenanceFact {
  const ProductProvenanceFact({
    required this.key,
    required this.label,
    required this.value,
    required this.verified,
    required this.observedAt,
  });

  final String key;
  final String label;
  final String value;
  final bool verified;
  final DateTime? observedAt;
}

/// Structured "which one should I buy" guidance — backend
/// `ProductComparisonSummary`.
class ProductComparison {
  const ProductComparison({
    required this.bestForTag,
    required this.alternatives,
    required this.recommendation,
  });

  final String bestForTag;
  final List<ProductComparisonPoint> alternatives;
  final String recommendation;
}

class ProductComparisonPoint {
  const ProductComparisonPoint({
    required this.productId,
    required this.productName,
    required this.howItDiffers,
  });

  final String productId;
  final String productName;
  final String howItDiffers;
}

/// A product-page FAQ entry — backend `ProductSeoContent.Faq`.
class ProductFaqEntry {
  const ProductFaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;
}

/// A curated in-stock shopping list generated from a free-text goal —
/// backend `MissionShoppingPlan`.
class MissionShoppingPlan {
  const MissionShoppingPlan({
    required this.missionSummary,
    required this.items,
    required this.totalEstimatedCost,
    required this.currency,
    required this.budgetAmount,
    required this.withinBudget,
  });

  final String missionSummary;
  final List<MissionShoppingItem> items;
  final double totalEstimatedCost;
  final String currency;
  final double? budgetAmount;
  final bool withinBudget;
}

class MissionShoppingItem {
  const MissionShoppingItem({
    required this.productId,
    required this.name,
    required this.thumbnailUrl,
    required this.priceAmount,
    required this.reason,
  });

  final String productId;
  final String name;
  final String? thumbnailUrl;
  final double priceAmount;
  final String reason;
}

/// PDP urgency signals — backend `UrgencyDto` from
/// `GET /api/v1/customer/discover/products/{id}/urgency`.
///
/// Every field is nullable and null means **"not measured"**, never zero and
/// never false. Callers must not fill a gap with a default: a missing figure
/// draws nothing at all.
///
/// It used to carry `stockRemaining` and `cartAddsLast10Min`, both a
/// `Random` on the server. `cartAddsLast10Min` is gone outright — nothing
/// records cart-adds per product. `stockRemaining` is gone in favour of the
/// coarse [isInStock] / [isLowStock] pair: an exact remaining count is a
/// vendor's inventory position and, on a product page, a pressure tactic.
/// **Do not reconstruct a number, a countdown or an "N left" line from these
/// booleans** — the whole point of the pair is that there is no N.
class ProductUrgency {
  const ProductUrgency({
    this.isInStock,
    this.isLowStock,
    this.viewersRightNow,
    this.flashSaleEndsAt,
    this.flashSalePrice,
  });

  /// Whether the product can be bought right now. Null when the product has
  /// no public listing, so stock is genuinely unknown.
  final bool? isInStock;

  /// True when the listing is at or under the platform low-stock threshold
  /// and above zero — the same rule the Mall product cards apply, so the two
  /// surfaces cannot disagree. Null when stock is unknown.
  final bool? isLowStock;

  /// Shoppers on this product right now, from a Redis presence counter.
  ///
  /// **Null is the normal case in production**: nothing writes that key yet,
  /// so treat a value as the exception and never render a placeholder.
  final int? viewersRightNow;

  /// End of a running flash sale. Null when no sale runs.
  final DateTime? flashSaleEndsAt;

  /// The sale price *with its own currency*, built only when the payload
  /// carried both `flashSalePrice` and `flashSaleCurrency`. The currency is
  /// never assumed: a price without one is not rendered at all.
  final Money? flashSalePrice;
}

/// Measured trust signals for one product — backend `SocialProofDto` from
/// `GET /api/v1/customer/discover/products/social-proof`.
///
/// Every figure here traces to something the platform recorded. Where it
/// records nothing the field is null, and null renders as nothing: a zero
/// would read as "nobody bought this", which is its own false claim.
///
/// It used to carry `recentPurchases`, `addedToCartToday`, `friendNames`,
/// `trendingLabel` and `isBackInStock`, all generated server-side by a
/// `Random`. They are removed, not zeroed. **Do not add a field here without
/// a recorded source behind it.**
class ProductSocialProof {
  const ProductSocialProof({
    required this.reviewCount,
    this.unitsSoldLast30Days,
    this.viewersRightNow,
    this.averageRating,
  });

  /// Visible reviews. Zero is a recorded fact and means "no reviews yet" —
  /// it is a count of reviews, not a claim about the product.
  final int reviewCount;

  /// Paid units sold in the last 30 days. Null when the product sold nothing
  /// in the window or sales could not be read — "no recorded activity",
  /// never "zero bought".
  final int? unitsSoldLast30Days;

  /// Shoppers on this product right now. Null whenever nothing is counting,
  /// which is every call in production today.
  final int? viewersRightNow;

  /// Mean star rating. **Null whenever there are no reviews** — never a
  /// generated or defaulted average. A null here must never become a star
  /// row or a "0.0".
  final double? averageRating;

  /// True only when there is a real rating to draw a star against.
  bool get hasRating => averageRating != null && reviewCount > 0;
}

/// A related / "You may also like" product card.
class RelatedProduct {
  const RelatedProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.rating,
    this.reel,
  });

  final String id;
  final String name;
  final String imageUrl;
  final Money price;
  final double rating;
  final ProductReelRef? reel;
}
