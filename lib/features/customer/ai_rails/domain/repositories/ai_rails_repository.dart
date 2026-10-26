import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/entities/ai_rail.dart';

/// The AI rails: collaborative filtering (AI features contract v1.0 §3) and
/// reel ↔ product matching by meaning (§4.2, §4.3).
///
/// Every method answers; none throws or fails. A rail is a nice-to-have on
/// a page that already works without it, so a 404 (not deployed), a network
/// failure or a malformed body all come back empty, marked
/// [AiRailStatus.notDeployed] / [ReelMatches.notDeployed], and the screen
/// draws what it drew before the rail existed.
abstract interface class AiRailsRepository {
  /// `GET v1/public/reels/{id}/also-watched` — "People also watched".
  Future<ReelRail> alsoWatched(String reelId, {int limit});

  /// `GET v1/public/products/{id}/bought-together`.
  Future<ProductRail> boughtTogether(String productId, {int limit});

  /// `GET v1/public/products/{id}/also-viewed`.
  Future<ProductRail> alsoViewed(String productId, {int limit});

  /// `GET v1/public/products/{id}/reels` — featuring, then like, a product.
  Future<ReelMatches> reelsForProduct(String productId, {int limit});

  /// `GET v1/public/reels/{id}/similar` — similar reels by meaning.
  Future<ReelMatches> similarReels(String reelId, {int limit});
}
