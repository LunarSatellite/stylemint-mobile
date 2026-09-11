import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/datasources/reel_studio_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/models/reel_studio_extras_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio_extras.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/repositories/reel_studio_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:uuid/uuid.dart';

class ReelStudioRepositoryImpl implements ReelStudioRepository {
  ReelStudioRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ReelStudioRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<ReelRecipe>>> getRecipes({
    SocialPlatform? platform,
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getRecipes(
          platform: platform?.name,
          limit: limit,
          cursor: cursor,
        );
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
  Future<Either<NetworkExceptions, CoachingFeedback>> getCoachingFeedback(
    String draftId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getCoachingFeedback(draftId);
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
  Future<Either<NetworkExceptions, ReelDraft>> createDraft({
    required String caption,
    required List<String> hashtags,
    required List<String> taggedProductIds,
    required SocialPlatform platform,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.createDraft(
          caption: caption,
          hashtags: hashtags,
          taggedProductIds: taggedProductIds,
          platform: platform.name,
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
  Future<Either<NetworkExceptions, ReelDraft>> updateDraft({
    required String draftId,
    String? caption,
    List<String>? hashtags,
    List<String>? taggedProductIds,
    SocialPlatform? platform,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.updateDraft(
          draftId: draftId,
          caption: caption,
          hashtags: hashtags,
          taggedProductIds: taggedProductIds,
          platform: platform?.name,
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
  Future<Either<NetworkExceptions, List<ReelDraft>>> getDrafts() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getDrafts();
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
  Future<Either<NetworkExceptions, Unit>> deleteDraft(String draftId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteDraft(draftId, const Uuid().v4());
        return right(unit);
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
  Future<Either<NetworkExceptions, CoachingFeedback>> requestCoaching(
    String draftId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.requestCoaching(
          draftId,
          const Uuid().v4(),
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
  Future<Either<NetworkExceptions, List<CoachingTip>>> getCoachingTips(
    String draftId,
  ) =>
      _guard(() async {
        final dtos = await remoteDataSource.getCoachingTips(draftId);
        return dtos.map((d) => d.toDomain()).toList(growable: false);
      });

  @override
  Future<Either<NetworkExceptions, List<CollabSuggestion>>>
      getCollabSuggestions() => _guard(() async {
            final dtos = await remoteDataSource.getCollabSuggestions();
            return dtos.map((d) => d.toDomain()).toList(growable: false);
          });

  @override
  Future<Either<NetworkExceptions, DropPartyPrompt>> getDropPartyPrompt() =>
      _guard(() async {
        final dto = await remoteDataSource.getDropPartyPrompt();
        return dto.toDomain();
      });

  @override
  Future<Either<NetworkExceptions, List<TagNudge>>> getTagNudges() =>
      _guard(() async {
        final dtos = await remoteDataSource.getTagNudges();
        return dtos.map((d) => d.toDomain()).toList(growable: false);
      });

  /// Connectivity check + exception mapping shared by the insight reads.
  Future<Either<NetworkExceptions, T>> _guard<T>(
    Future<T> Function() call,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await call());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
