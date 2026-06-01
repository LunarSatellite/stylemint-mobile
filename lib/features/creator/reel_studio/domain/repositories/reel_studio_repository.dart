import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class ReelStudioRepository {
  Future<Either<NetworkExceptions, List<ReelRecipe>>> getRecipes({
    SocialPlatform? platform,
    int limit = 20,
    String? cursor,
  });

  Future<Either<NetworkExceptions, CoachingFeedback>> getCoachingFeedback(
    String draftId,
  );

  Future<Either<NetworkExceptions, ReelDraft>> createDraft({
    required String caption,
    required List<String> hashtags,
    required List<String> taggedProductIds,
    required SocialPlatform platform,
  });

  Future<Either<NetworkExceptions, ReelDraft>> updateDraft({
    required String draftId,
    String? caption,
    List<String>? hashtags,
    List<String>? taggedProductIds,
  });

  Future<Either<NetworkExceptions, List<ReelDraft>>> getDrafts();

  Future<Either<NetworkExceptions, Unit>> deleteDraft(String draftId);

  Future<Either<NetworkExceptions, ReelDraft>> requestCoaching(String draftId);
}
