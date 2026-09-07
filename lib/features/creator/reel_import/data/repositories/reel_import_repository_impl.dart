import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/datasources/reel_import_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/reel_import_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:uuid/uuid.dart';

class ReelImportRepositoryImpl implements ReelImportRepository {
  ReelImportRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ReelImportRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, ImportableReelsResult>> getImportableReels(
    SocialPlatform platform, {
    String? cursor,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final page = await remoteDataSource.getImportableReels(
        platform,
        cursor: cursor,
      );
      return right(ImportableReelsResult(
        reels: page.reels.map((d) => d.toDomain()).toList(growable: false),
        nextCursor: page.nextCursor,
      ));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return left(const NetworkExceptions.notFound());
      }
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, ImportedReel>> importReel(
    ImportableReel reel,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.importReel(
        platform: reel.platform,
        sourceUrl: reel.sourceUrl,
        externalId: reel.platformPostId,
        durationSeconds: reel.videoDuration,
        idempotencyKey: const Uuid().v4(),
        caption: reel.caption,
        thumbnailCdnUrl: reel.thumbnailUrl,
        videoUrl: reel.videoUrl,
      );
      return right(dto.toDomain());
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return left(const NetworkExceptions.conflict());
      }
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<TaggedProductForImport>>>
      searchProducts(
    String query,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dtos = await remoteDataSource.searchProducts(query);
      return right(dtos.map((d) => d.toDomain()).toList(growable: false));
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<TaggedProductForImport>>>
      getSuggestedProducts({
    required SocialPlatform platform,
    required String externalId,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dtos = await remoteDataSource.getSuggestedProducts(
        platform: platform,
        externalId: externalId,
      );
      return right(dtos.map((d) => d.toDomain()).toList(growable: false));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return right(const []);
      }
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> publishReel({
    required String reelId,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      await remoteDataSource.publishReel(
        reelId: reelId,
        idempotencyKey: const Uuid().v4(),
      );
      return right(unit);
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> tagProduct({
    required String reelId,
    required String productId,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      await remoteDataSource.tagProduct(
        reelId: reelId,
        productId: productId,
        idempotencyKey: const Uuid().v4(),
      );
      return right(unit);
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<ImportedReel>>> getImportHistory({
    int pageSize = 20,
    String? cursor,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dtos = await remoteDataSource.getImportHistory(
        pageSize: pageSize,
        cursor: cursor,
      );
      return right(dtos.map((dto) => dto.toDomain()).toList(growable: false));
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, BulkImportResult>> importBulk(
    List<ImportableReel> reels,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      return right(
        await remoteDataSource.importBulk(reels, const Uuid().v4()),
      );
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, ReelIntent>> launchReelIntent(
    SocialPlatform platform,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final response = await remoteDataSource.launchReelIntent(
        platform: platform,
        idempotencyKey: const Uuid().v4(),
      );
      return right(_parseReelIntent(response));
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, ReelIntent>> completeReelIntent({
    required String intentId,
    required String resultingReelId,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final response = await remoteDataSource.completeReelIntent(
        intentId: intentId,
        resultingReelId: resultingReelId,
        idempotencyKey: const Uuid().v4(),
      );
      return right(_parseReelIntent(response));
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  static ReelIntent _parseReelIntent(Map<String, dynamic> body) {
    final state = switch (body['state'] as int? ?? 1) {
      2 => ReelIntentState.completed,
      3 => ReelIntentState.abandoned,
      _ => ReelIntentState.launched,
    };
    final platform = switch (body['targetPlatform'] as int? ?? 1) {
      2 => SocialPlatform.tiktok,
      3 => SocialPlatform.youtube,
      4 => SocialPlatform.facebook,
      _ => SocialPlatform.instagram,
    };
    return ReelIntent(
      id: body['id'] as String? ?? '',
      targetPlatform: platform,
      launchedAtUtc: body['launchedAtUtc'] != null
          ? DateTime.parse(body['launchedAtUtc'] as String)
          : DateTime.now(),
      expiresAtUtc: body['expiresAtUtc'] != null
          ? DateTime.parse(body['expiresAtUtc'] as String)
          : DateTime.now().add(const Duration(hours: 24)),
      state: state,
      resultingReelId: body['resultingReelId'] as String?,
    );
  }
}
