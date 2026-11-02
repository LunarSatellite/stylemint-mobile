import 'package:dio/dio.dart' show Options;
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundle_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:uuid/uuid.dart';

/// A reel holds at most this many bundle tags (contract §B9).
const int maxReelBundleTags = 3;

/// The creator's bundle-tag calls (shop bundles contract §B9). Bundles are
/// made in Creator Studio; the app only tags a Live one on a reel.
abstract class ReelBundleTagsApi {
  /// `GET /v1/bundles/mine?as=owner&state=Live` — the creator's own Live
  /// bundles, the ones they can tag.
  Future<Either<BundleFailure, List<BundleCard>>> myLiveBundles();

  /// `POST /v1/reels/{reelId}/tagged-bundles`.
  Future<Either<BundleFailure, Unit>> tag(
    String reelId, {
    required String bundleId,
    double x = 0.5,
    double y = 0.8,
  });

  /// `DELETE /v1/reels/{reelId}/tagged-bundles/{taggedBundleId}`.
  Future<Either<BundleFailure, Unit>> untag(
    String reelId,
    String taggedBundleId,
  );
}

class ReelBundleTagsApiImpl implements ReelBundleTagsApi {
  ReelBundleTagsApiImpl(this._api);

  final ApiClient _api;

  static String _id(String id) => Uri.encodeComponent(id);

  Options _write() => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': const Uuid().v4(),
    },
  );

  @override
  Future<Either<BundleFailure, List<BundleCard>>> myLiveBundles() =>
      guardedBundleCall(
        () async => readBundleList(
          await _api.get(
            '/v1/bundles/mine',
            queryParameters: <String, dynamic>{'as': 'owner', 'state': 'Live'},
          ),
          readBundleCard,
        ),
      );

  @override
  Future<Either<BundleFailure, Unit>> tag(
    String reelId, {
    required String bundleId,
    double x = 0.5,
    double y = 0.8,
  }) => guardedBundleCall(() async {
    await _api.post(
      '/v1/reels/${_id(reelId)}/tagged-bundles',
      data: <String, dynamic>{'bundleId': bundleId, 'x': x, 'y': y},
      options: _write(),
    );
    return unit;
  });

  @override
  Future<Either<BundleFailure, Unit>> untag(
    String reelId,
    String taggedBundleId,
  ) => guardedBundleCall(() async {
    await _api.authDelete(
      '/v1/reels/${_id(reelId)}/tagged-bundles/${_id(taggedBundleId)}',
      options: _write(),
    );
    return unit;
  });
}
