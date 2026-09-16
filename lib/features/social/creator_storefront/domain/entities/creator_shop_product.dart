import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/product_reel_ref.dart';

/// A publicly listed product a creator tagged on their public reels.
class CreatorShopProduct {
  const CreatorShopProduct({
    required this.productId,
    required this.name,
    required this.price,
    required this.vendorAccountId,
    required this.vendorDisplayName,
    this.imageUrl,
    this.reelCount = 0,
    this.lastTaggedUtc,
    this.reel,
    this.requiresOptionSelection = true,
    this.defaultVariantId,
    this.isInStock = false,
  });

  /// The reel this product is sold through. Null for most products.
  final ProductReelRef? reel;

  /// Whether the buyer has to choose a size or a colour before this can go in
  /// a cart. Defaults to `true`: a card that did not say is never quick-added.
  final bool requiresOptionSelection;

  /// The variant a quick add sends. Null when the server sent none.
  final String? defaultVariantId;

  /// Whether the server proved the default variant can currently be bought.
  final bool isInStock;

  final String productId;
  final String name;

  /// The default variant's current price.
  final Money price;
  final String vendorAccountId;
  final String vendorDisplayName;
  final String? imageUrl;

  /// Public reels of this creator that tag the product ("most loved").
  final int reelCount;
  final DateTime? lastTaggedUtc;
}
