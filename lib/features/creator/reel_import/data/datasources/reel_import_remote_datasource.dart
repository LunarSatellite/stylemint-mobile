import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/models/imported_reel_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

class ReelImportRemoteDataSource {
  ReelImportRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  // Backend sourcePlatform int mapping (REEL_IMPORT_PICKER_API.md)
  static int _platformInt(SocialPlatform platform) => switch (platform) {
        SocialPlatform.instagram => 1,
        SocialPlatform.tiktok => 2,
        SocialPlatform.youtube => 3,
        SocialPlatform.facebook => 4,
      };

  static String _platformName(int value) => switch (value) {
        1 => 'instagram',
        2 => 'tiktok',
        3 => 'youtube',
        4 => 'facebook',
        _ => 'instagram',
      };

  // GET /v1/social/accounts/{provider}/content?limit=25
  // Lists recent posts from the creator's connected social account.
  Future<List<ImportableReelDto>> getImportableReels(
    SocialPlatform platform,
  ) async {
    final response = await apiClient.get(
      '/v1/social/accounts/${platform.name}/content',
      queryParameters: {'limit': 25},
    );
    final items = response as List<dynamic>? ?? const <dynamic>[];
    return items.map((e) {
      final m = e as Map<String, dynamic>;
      return ImportableReelDto(
        id: m['externalId'] as String? ?? '',
        platform: platform.name,
        platformPostId: m['externalId'] as String? ?? '',
        sourceUrl: m['permalink'] as String? ?? '',
        thumbnailUrl: m['thumbnailUrl'] as String? ?? '',
        caption: m['caption'] as String? ?? '',
        createdAt: m['publishedUtc'] != null
            ? DateTime.parse(m['publishedUtc'] as String)
            : DateTime.now(),
        videoDuration: 30,
      );
    }).toList(growable: false);
  }

  // POST /v1/creator/reels/import
  // Imports a single reel. Product tagging is a separate step.
  Future<ImportedReelDto> importReel({
    required SocialPlatform platform,
    required String sourceUrl,
    required String externalId,
    required int durationSeconds,
    required String idempotencyKey,
    String? caption,
    String? thumbnailCdnUrl,
  }) async {
    final response = await apiClient.post(
      '/v1/creator/reels/import',
      data: {
        'sourcePlatform': _platformInt(platform),
        'sourceUrl': sourceUrl,
        'externalId': externalId,
        'durationSeconds': durationSeconds > 0 ? durationSeconds : 30,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
        if (thumbnailCdnUrl != null &&
            thumbnailCdnUrl.isNotEmpty &&
            thumbnailCdnUrl.length <= 2048)
          'thumbnailCdnUrl': thumbnailCdnUrl,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return _parseReelDto(response as Map<String, dynamic>, platform);
  }

  // GET /api/v1/customer/search?type=products&q=...&limit=20
  // Searches the product catalog for tagging candidates.
  Future<List<TaggedProductForImportDto>> searchProducts(String query) async {
    final response = await apiClient.get(
      '/api/v1/customer/search',
      queryParameters: {'q': query, 'type': 'products', 'limit': 20},
    );
    final m = response as Map<String, dynamic>;
    final products = m['products'] as List<dynamic>? ?? const <dynamic>[];
    return products.map((e) {
      final p = e as Map<String, dynamic>;
      return TaggedProductForImportDto(
        productId: p['productId'] as String? ?? '',
        productName: p['name'] as String? ?? '',
        imageUrl: p['heroImageUrl'] as String? ?? '',
        amount: (p['price'] as num?)?.toDouble() ?? 0.0,
        currency: p['currency'] as String? ?? 'NPR',
        vendorName: p['brandName'] as String? ?? '',
      );
    }).toList(growable: false);
  }

  // POST /v1/creator/reels/{reelId}/publish
  Future<void> publishReel({
    required String reelId,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/creator/reels/$reelId/publish',
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  // POST /v1/creator/reels/{reelId}/tagged-products
  Future<void> tagProduct({
    required String reelId,
    required String productId,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/creator/reels/$reelId/tagged-products',
      data: {
        'productId': productId,
        'overlayPositionX': 0.5,
        'overlayPositionY': 0.5,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  // GET /v1/creator/reels?pageSize=...&cursor=...
  // Returns the creator's imported reels (paginated).
  Future<List<ImportedReelDto>> getImportHistory({
    int pageSize = 20,
    String? cursor,
  }) async {
    final params = <String, dynamic>{'pageSize': pageSize};
    if (cursor != null) params['cursor'] = cursor;
    final response = await apiClient.get(
      '/v1/creator/reels',
      queryParameters: params,
    );
    final m = response as Map<String, dynamic>;
    final items = m['items'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .map((e) => _parseReelDto(e as Map<String, dynamic>, null))
        .toList(growable: false);
  }

  // Maps backend ReelDto JSON → ImportedReelDto.
  static ImportedReelDto _parseReelDto(
    Map<String, dynamic> m,
    SocialPlatform? platformHint,
  ) {
    final platformInt = m['sourcePlatform'] as int? ?? 0;
    final platformName = platformInt > 0
        ? _platformName(platformInt)
        : (platformHint?.name ?? 'instagram');

    // ReelState enum: Draft=1, Processing=2, Published=3, Unpublished=4, ExternalDeleted=5
    final stateInt = m['state'] as int? ?? 0;
    final statusName = switch (stateInt) {
      3 => 'live',
      2 => 'processing',
      5 => 'flagged',
      _ => 'pending',
    };

    final taggedProducts =
        (m['taggedProducts'] as List<dynamic>? ?? const <dynamic>[]).map((t) {
      final tp = t as Map<String, dynamic>;
      return TaggedProductForImportDto(
        productId: tp['productId'] as String? ?? '',
        productName: tp['productName'] as String? ?? '',
        imageUrl: tp['productPrimaryImageUrl'] as String? ?? '',
        amount:
            (tp['productPriceSnapshotAmount'] as num?)?.toDouble() ?? 0.0,
        currency: tp['productPriceSnapshotCurrency'] as String? ?? 'NPR',
        vendorName: tp['vendorDisplayName'] as String? ?? '',
      );
    }).toList(growable: false);

    return ImportedReelDto(
      id: m['id'] as String? ?? '',
      status: statusName,
      reelReelId: m['id'] as String? ?? '',
      tags: taggedProducts,
      importedAt: m['createdUtc'] != null
          ? DateTime.parse(m['createdUtc'] as String)
          : DateTime.now(),
      caption: m['caption'] as String? ?? '',
      thumbnailUrl: m['thumbnailCdnUrl'] as String? ?? '',
      sourceUrl: m['sourceUrl'] as String? ?? '',
      platform: platformName,
      platformPostId: m['externalId'] as String? ?? '',
    );
  }
}
