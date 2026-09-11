import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio_extras.dart';
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
    SocialPlatform? platform,
  });

  Future<Either<NetworkExceptions, List<ReelDraft>>> getDrafts();

  Future<Either<NetworkExceptions, Unit>> deleteDraft(String draftId);

  Future<Either<NetworkExceptions, CoachingFeedback>> requestCoaching(
    String draftId,
  );

  // ── Studio insight reads ────────────────────────────────────────────────
  // Read-only AI-derived surfaces. They go through the repository like every
  // other call so they get the same connectivity guard and typed failures.

  Future<Either<NetworkExceptions, List<CoachingTip>>> getCoachingTips(
    String draftId,
  );

  Future<Either<NetworkExceptions, List<CollabSuggestion>>>
      getCollabSuggestions();

  Future<Either<NetworkExceptions, DropPartyPrompt>> getDropPartyPrompt();

  Future<Either<NetworkExceptions, List<TagNudge>>> getTagNudges();
}
