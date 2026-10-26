import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/entities/ai_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

/// Reads one `ReelDto` (the public detail projection).
typedef ReelJsonReader = Reel Function(Map<String, dynamic> json);

/// Reads one public `ProductDto` card.
typedef ProductJsonReader =
    RelatedProductDto Function(Map<String, dynamic> json);

/// The AI rails endpoints (AI features contract v1.0 §3 and §4.2–4.3).
/// Throws on transport failure; the repository turns every failure into an
/// empty rail.
///
/// The reel and product cards are the same `ReelDto` / `ProductDto` the
/// existing public reads return, so they are mapped by those data sources'
/// own readers rather than by a second copy of the mapping.
class AiRailsRemoteDataSource {
  AiRailsRemoteDataSource({
    required this.apiClient,
    required this.readReel,
    required this.readProduct,
  });

  final ApiClient apiClient;
  final ReelJsonReader readReel;
  final ProductJsonReader readProduct;

  static String alsoWatchedPath(String reelId) =>
      '/v1/public/reels/${Uri.encodeComponent(reelId)}/also-watched';
  static String boughtTogetherPath(String productId) =>
      '/v1/public/products/${Uri.encodeComponent(productId)}/bought-together';
  static String alsoViewedPath(String productId) =>
      '/v1/public/products/${Uri.encodeComponent(productId)}/also-viewed';
  static String productReelsPath(String productId) =>
      '/v1/public/products/${Uri.encodeComponent(productId)}/reels';
  static String similarReelsPath(String reelId) =>
      '/v1/public/reels/${Uri.encodeComponent(reelId)}/similar';

  Future<ReelRail> alsoWatched(String reelId, {required int limit}) async {
    final body = await _get(alsoWatchedPath(reelId), limit);
    return AiRail(
      status: AiRailStatus.parse(body['status']),
      items: [
        for (final row in _rows(body['items']))
          if (_reel(row['reel']) case final reel?)
            if (reel.id != reelId) reel,
      ],
    );
  }

  Future<ProductRail> boughtTogether(String productId, {required int limit}) =>
      _productRail(boughtTogetherPath(productId), productId, limit);

  Future<ProductRail> alsoViewed(String productId, {required int limit}) =>
      _productRail(alsoViewedPath(productId), productId, limit);

  Future<ReelMatches> reelsForProduct(
    String productId, {
    required int limit,
  }) async => _matches(await _get(productReelsPath(productId), limit), null);

  Future<ReelMatches> similarReels(String reelId, {required int limit}) async =>
      _matches(await _get(similarReelsPath(reelId), limit), reelId);

  Future<ProductRail> _productRail(
    String path,
    String anchorId,
    int limit,
  ) async {
    final body = await _get(path, limit);
    return AiRail(
      status: AiRailStatus.parse(body['status']),
      items: [
        for (final row in _rows(body['items']))
          if (_product(row['product']) case final product?)
            if (product.id != anchorId) product,
      ],
    );
  }

  ReelMatches _matches(Map<String, dynamic> body, String? excludeReelId) {
    final items = <MatchedReel>[];
    for (final row in _rows(body['items'])) {
      final reel = _reel(row['reel']);
      if (reel == null || reel.id == excludeReelId) continue;
      final score = row['score'];
      final reason = row['reason'];
      items.add(
        MatchedReel(
          reel: reel,
          kind: ReelMatchKind.parse(row['matchType']),
          score: score is num ? score.toDouble() : null,
          reason: reason is String && reason.trim().isNotEmpty
              ? reason.trim()
              : null,
        ),
      );
    }
    return ReelMatches(items: items, aiApplied: body['aiApplied'] == true);
  }

  Future<Map<String, dynamic>> _get(String path, int limit) async {
    final response = await apiClient.get(
      path,
      queryParameters: {'limit': limit},
    );
    return response is Map<String, dynamic> ? response : const {};
  }

  static Iterable<Map<String, dynamic>> _rows(Object? raw) =>
      (raw is List ? raw : const <dynamic>[]).whereType<Map<String, dynamic>>();

  /// A card that does not map (no id, a wrong type) is skipped, not fatal.
  Reel? _reel(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      final reel = readReel(raw);
      return reel.id.isEmpty ? null : reel;
    } on Object catch (_) {
      return null;
    }
  }

  RelatedProduct? _product(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    try {
      final product = readProduct(raw).toDomain();
      return product.id.isEmpty ? null : product;
    } on Object catch (_) {
      return null;
    }
  }
}
