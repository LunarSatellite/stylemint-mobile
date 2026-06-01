import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/datasources/reel_import_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/models/imported_reel_dto.dart';
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
  Future<Either<NetworkExceptions, List<ImportableReel>>> getImportableReels(
    SocialPlatform platform,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getImportableReels(platform.name);
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, ImportedReel>> importReel(
    String platformPostId,
    String caption,
    List<String> taggedProductIds,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.importReel(
          platformPostId: platformPostId,
          caption: caption,
          taggedProductIds: taggedProductIds,
          platform: 'instagram',
          idempotencyKey: const Uuid().v4(),
        );
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<TaggedProductForImport>>> searchProducts(
    String query,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.searchProducts(query);
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<ImportedReel>>> getImportHistory({
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getImportHistory(
          limit: limit,
          cursor: cursor,
        );
        final items =
            (response['items'] as List<dynamic>? ?? const <dynamic>[])
                .map(
                  (e) =>
                      ImportedReelDto.fromJson(e as Map<String, dynamic>),
                )
                .toList(growable: false);
        return right(
          items.map((dto) => dto.toDomain()).toList(growable: false),
        );
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }
}
