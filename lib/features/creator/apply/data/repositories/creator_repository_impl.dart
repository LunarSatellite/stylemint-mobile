import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/datasources/creator_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_repository.dart';
import 'package:uuid/uuid.dart';

class CreatorRepositoryImpl implements CreatorRepository {
  CreatorRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  /// Maps a declared platform id to the backend `SocialIdentityProvider`
  /// integer enum (1..4). Unsupported platforms (e.g. Snapchat, X) → null and
  /// are dropped from the payload.
  static int? _providerInt(String platformId) => const {
        'instagram': 1,
        'tiktok': 2,
        'youtube': 3,
        'facebook': 4,
      }[platformId];

  @override
  Future<Either<NetworkExceptions, List<CreatorContentCategory>>>
      getContentCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final raw = await remoteDataSource.getCreatorCategories();
        final active = raw
            .where((m) => (m['isActive'] as bool?) ?? true)
            .toList()
          ..sort((a, b) => ((a['displayOrder'] as int?) ?? 0)
              .compareTo((b['displayOrder'] as int?) ?? 0));
        final categories = active
            .map(
              (m) => CreatorContentCategory(
                id: m['id'] as String,
                name: (m['nameEn'] as String?) ?? (m['code'] as String?) ?? '',
                requiresOtherDescription:
                    (m['requiresOtherDescription'] as bool?) ?? false,
              ),
            )
            .toList(growable: false);
        return right(categories);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(const NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> activate({
    String? bio,
    String? expression,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.activate(
          bio: bio,
          expression: expression,
          idempotencyKey: _uuid.v4(),
        );
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(const NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, CreatorApplication>> getApplicationStatus() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getApplicationStatus();
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          // 404 = no application on file yet → let the UI show the apply form.
          if (e.response?.statusCode == 404) {
            return left(const NetworkExceptions.notFound());
          }
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(const NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, CreatorApplication>> submitApplication(
    CreatorApplicationForm form,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.submitApplication(
          // Map declared platforms → socials with the SocialIdentityProvider
          // integer enum; platforms outside the supported four are dropped.
          socials: form.platforms
              .map((p) => (provider: _providerInt(p.id), platform: p))
              .where((e) => e.provider != null)
              .map(
                (e) => <String, dynamic>{
                  'provider': e.provider,
                  'handle': e.platform.handle,
                  'followerCountSelfReported': e.platform.followerCount,
                },
              )
              .toList(growable: false),
          contentCategoryIds: form.contentCategoryIds,
          audienceBand: form.audienceBand,
          bio: form.bio,
          idempotencyKey: _uuid.v4(),
        );
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(const NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

}
