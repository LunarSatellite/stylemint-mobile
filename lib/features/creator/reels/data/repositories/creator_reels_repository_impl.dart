import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/datasources/creator_reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/post_publish_report.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/repositories/creator_reels_repository.dart';

class CreatorReelsRepositoryImpl implements CreatorReelsRepository {
  CreatorReelsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorReelsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<NetworkEither<CreatorReelDetail>> getReelDetail(
    String reelId,
  ) async {
    if (!await networkInfo.isConnected) {
      return left<NetworkExceptions, CreatorReelDetail>(
        const NetworkExceptions.noInternetConnection(),
      );
    }
    try {
      final dto = await remoteDataSource.getReelDetail(reelId);
      return right<NetworkExceptions, CreatorReelDetail>(dto.toDomain());
    } on DioException catch (e) {
      return left<NetworkExceptions, CreatorReelDetail>(
        NetworkExceptions.server(e.message ?? 'Server error'),
      );
    } on NetworkExceptions catch (e) {
      return left<NetworkExceptions, CreatorReelDetail>(e);
    } on Exception {
      return left<NetworkExceptions, CreatorReelDetail>(
        const NetworkExceptions.unexpectedError(),
      );
    }
  }

  @override
  Future<NetworkEither<List<CreatorReelSummary>>> listCreatorReels({
    String sortBy = 'publishedAt',
    String order = 'desc',
    int limit = 6,
  }) async {
    if (!await networkInfo.isConnected) {
      return left<NetworkExceptions, List<CreatorReelSummary>>(
        const NetworkExceptions.noInternetConnection(),
      );
    }
    try {
      final dtos = await remoteDataSource.listCreatorReels(
        sortBy: sortBy,
        order: order,
        limit: limit,
      );
      return right<NetworkExceptions, List<CreatorReelSummary>>(
        dtos.map((d) => d.toDomain()).toList(growable: false),
      );
    } on DioException catch (e) {
      return left<NetworkExceptions, List<CreatorReelSummary>>(
        NetworkExceptions.server(e.message ?? 'Server error'),
      );
    } on NetworkExceptions catch (e) {
      return left<NetworkExceptions, List<CreatorReelSummary>>(e);
    } on Exception {
      return left<NetworkExceptions, List<CreatorReelSummary>>(
        const NetworkExceptions.unexpectedError(),
      );
    }
  }

  @override
  Future<NetworkEither<PostPublishReport>> getPostPublishReport(
    String reelId,
  ) async {
    if (!await networkInfo.isConnected) {
      return left<NetworkExceptions, PostPublishReport>(
        const NetworkExceptions.noInternetConnection(),
      );
    }
    try {
      final response = await remoteDataSource.getPostPublishReport(reelId);
      final insights =
          (response['insights'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) {
        final m = e as Map<String, dynamic>;
        return PostPublishInsight(
          category: m['category'] as String? ?? '',
          body: m['body'] as String? ?? '',
        );
      }).toList(growable: false);
      final report = PostPublishReport(
        reelId: response['reelId'] as String? ?? reelId,
        generatedAtUtc: response['generatedAtUtc'] != null
            ? DateTime.parse(response['generatedAtUtc'] as String)
            : DateTime.now(),
        performanceScore:
            (response['performanceScore'] as num?)?.toDouble() ?? 0.0,
        headline: response['headline'] as String? ?? '',
        insights: insights,
        isAvailable: response['isAvailable'] as bool? ?? true,
      );
      return right<NetworkExceptions, PostPublishReport>(report);
    } on DioException catch (e) {
      return left<NetworkExceptions, PostPublishReport>(
        NetworkExceptions.server(e.message ?? 'Server error'),
      );
    } on NetworkExceptions catch (e) {
      return left<NetworkExceptions, PostPublishReport>(e);
    } on Exception {
      return left<NetworkExceptions, PostPublishReport>(
        const NetworkExceptions.unexpectedError(),
      );
    }
  }
}
