import 'package:dio/dio.dart' show Options;
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundle_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/shared/data/option_label.dart';

/// The buyer's bundle calls (contract §B6, §B8). Every call 404s bare until
/// the backend is deployed; the bundle UI then hides itself.
abstract class BundlesApi {
  /// `GET /v1/public/bundles/{id}` — 404 unless Live or Paused.
  Future<Either<BundleFailure, BundleDetail>> getBundle(String bundleId);

  /// `GET /v1/public/bundles?vendorAccountId=|creatorAccountId=` (Live only).
  Future<Either<BundleFailure, List<BundleCard>>> list(BundleListKey key);

  /// `GET /v1/public/reels/{reelId}/tagged-bundles`.
  Future<Either<BundleFailure, List<ReelTaggedBundle>>> reelBundles(
    String reelId,
  );

  /// `POST /v1/cart/bundles` — every item at once, at the bundle price.
  /// Answers with the cart.
  Future<Either<BundleFailure, Cart>> addToCart({
    required String bundleId,
    required int termsVersion,
    required Map<String, String> variants,
    required String idempotencyKey,
    int quantity = 1,
    String? taggedBundleId,
    String? affiliateCode,
  });
}

class BundlesApiImpl implements BundlesApi {
  BundlesApiImpl(this._api);

  final ApiClient _api;

  static String _id(String id) => Uri.encodeComponent(id);

  @override
  Future<Either<BundleFailure, BundleDetail>> getBundle(String bundleId) =>
      guardedBundleCall(
        () async => readBundleDetail(
          readJsonObject(await _api.get('/v1/public/bundles/${_id(bundleId)}')),
        ),
      );

  @override
  Future<Either<BundleFailure, List<BundleCard>>> list(BundleListKey key) =>
      guardedBundleCall(
        () async => readBundleList(
          await _api.get(
            '/v1/public/bundles',
            queryParameters: <String, dynamic>{
              'vendorAccountId': ?key.vendorAccountId,
              'creatorAccountId': ?key.creatorAccountId,
            },
          ),
          readBundleCard,
        ),
      );

  @override
  Future<Either<BundleFailure, List<ReelTaggedBundle>>> reelBundles(
    String reelId,
  ) => guardedBundleCall(
    () async => readReelTaggedBundles(
      await _api.get('/v1/public/reels/${_id(reelId)}/tagged-bundles'),
    ),
  );

  @override
  Future<Either<BundleFailure, Cart>> addToCart({
    required String bundleId,
    required int termsVersion,
    required Map<String, String> variants,
    required String idempotencyKey,
    int quantity = 1,
    String? taggedBundleId,
    String? affiliateCode,
  }) => guardedBundleCall(() async {
    final response = await _api.post(
      '/v1/cart/bundles',
      data: <String, dynamic>{
        'bundleId': bundleId,
        'termsVersion': termsVersion,
        'quantity': quantity,
        'taggedBundleId': ?taggedBundleId,
        'affiliateCode': ?affiliateCode,
        'variants': [
          for (final e in variants.entries)
            {'bundleItemId': e.key, 'productVariantId': e.value},
        ],
      },
      options: Options(
        headers: <String, dynamic>{
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return CartDto.fromJson(
      withOptionLabels(readJsonObject(response)),
    ).toDomain();
  });
}
