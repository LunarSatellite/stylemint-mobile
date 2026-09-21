import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/datasources/creator_reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/models/creator_reel_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/post_publish_report.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/reel_product_tag.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/repositories/creator_reels_repository.dart';
import 'package:uuid/uuid.dart';

class CreatorReelsRepositoryImpl implements CreatorReelsRepository {
  CreatorReelsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorReelsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<NetworkEither<CreatorReelDetail>> getReelDetail(String reelId) =>
      _guard(() async {
        final dto = await remoteDataSource.getReelDetail(reelId);
        return dto.toDomain();
      });

  @override
  Future<NetworkEither<List<CreatorReelSummary>>> listCreatorReels({
    String sortBy = 'publishedAt',
    String order = 'desc',
    int limit = 6,
  }) => _guard(() async {
    final dtos = await remoteDataSource.listCreatorReels(
      sortBy: sortBy,
      order: order,
      limit: limit,
    );
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  });

  @override
  Future<NetworkEither<Unit>> publishReel(String reelId) => _guard(() async {
    await remoteDataSource.publishReel(reelId, const Uuid().v4());
    return unit;
  });

  @override
  Future<NetworkEither<Unit>> unpublishReel(String reelId) => _guard(() async {
    await remoteDataSource.unpublishReel(reelId, const Uuid().v4());
    return unit;
  });

  @override
  Future<NetworkEither<Unit>> updateCaption(String reelId, String? caption) =>
      _guard(() async {
        await remoteDataSource.updateCaption(
          reelId,
          caption,
          const Uuid().v4(),
        );
        return unit;
      });

  @override
  Future<NetworkEither<List<ReelProductTag>>> listTaggedProducts(
    String reelId,
  ) => _guard(() async {
    final dtos = await remoteDataSource.listTaggedProducts(reelId);
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  });

  @override
  Future<NetworkEither<ReelProductTag>> tagProduct(
    String reelId, {
    required String productId,
    required double overlayPositionX,
    required double overlayPositionY,
  }) => _guard(() async {
    final dto = await remoteDataSource.tagProduct(
      reelId,
      productId: productId,
      overlayPositionX: overlayPositionX,
      overlayPositionY: overlayPositionY,
      idempotencyKey: const Uuid().v4(),
    );
    return dto.toDomain();
  });

  @override
  Future<NetworkEither<Unit>> untagProduct(
    String reelId,
    String taggedProductId,
  ) => _guard(() async {
    await remoteDataSource.untagProduct(
      reelId,
      taggedProductId,
      const Uuid().v4(),
    );
    return unit;
  });

  @override
  Future<NetworkEither<PostPublishReport>> getPostPublishReport(
    String reelId,
  ) => _guard(() async {
    final response = await remoteDataSource.getPostPublishReport(reelId);
    final insights =
        (response['insights'] as List<dynamic>? ?? const <dynamic>[])
            .map((entry) {
              final item = entry as Map<String, dynamic>;
              return PostPublishInsight(
                category: item['category'] as String? ?? '',
                body: item['body'] as String? ?? '',
              );
            })
            .toList(growable: false);
    return PostPublishReport(
      reelId: response['reelId'] as String? ?? reelId,
      generatedAtUtc: response['generatedAtUtc'] != null
          ? DateTime.parse(response['generatedAtUtc'] as String)
          : DateTime.now(),
      performanceScore: (response['performanceScore'] as num?)?.toDouble() ?? 0,
      headline: response['headline'] as String? ?? '',
      insights: insights,
      isAvailable: response['isAvailable'] as bool? ?? true,
    );
  });

  @override
  Future<NetworkEither<Unit>> deleteReel(String reelId) => _guard(() async {
    await remoteDataSource.deleteReel(reelId, const Uuid().v4());
    return unit;
  });

  /// Every call shares the same connectivity precondition and exception
  /// mapping, so it lives here rather than being repeated per method.
  Future<NetworkEither<T>> _guard<T>(Future<T> Function() call) async {
    if (!await networkInfo.isConnected) {
      return networkLeft<T>(const NetworkExceptions.noInternetConnection());
    }
    try {
      return networkRight<T>(await call());
    } on DioException catch (e) {
      // The shared mapper, not `NetworkExceptions.server(e.message)`. Dio's
      // `.message` is developer prose — it names RequestOptions.validateStatus
      // and links to MDN — and this value is rendered straight to the user.
      // The mapper reads the status code instead: 403 becomes `.auth()`, 404
      // `.notFound()`, 5xx `.serverUnavailable()`, each with a sentence a
      // person can act on.
      return networkLeft<T>(mapDioExceptionToNetworkException(e));
    } on NetworkExceptions catch (e) {
      return networkLeft<T>(e);
    } on Exception {
      return networkLeft<T>(const NetworkExceptions.unexpectedError());
    }
  }
}
