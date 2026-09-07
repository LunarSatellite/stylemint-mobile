import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_terms.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/rate_card.dart';

abstract interface class PartnershipsRepository {
  Future<Either<NetworkExceptions, List<PartnershipInvite>>> getInvites();

  Future<Either<NetworkExceptions, PartnershipInvite>> acceptInvite(String inviteId);

  Future<Either<NetworkExceptions, Unit>> declineInvite(String inviteId);

  Future<Either<NetworkExceptions, List<ActivePartnership>>> getActivePartnerships();

  Future<Either<NetworkExceptions, List<EndedPartnership>>> getEndedPartnerships();

  Future<Either<NetworkExceptions, Unit>> requestPartnership({
    required String vendorProfileId,
    required double commissionMinPercent,
    required double commissionMaxPercent,
    required String message,
  });

  Future<Either<NetworkExceptions, CreatorRateCard>> getMyRateCard();

  Future<Either<NetworkExceptions, Unit>> publishRateCard({
    required double baseRate,
    required List<RateTier> rates,
    required double commissionPreference,
    required List<String> platformPreferences,
    String? notes,
  });

  Future<Either<NetworkExceptions, Unit>> deactivateRateCard();

  // ── Brief / terms reads ─────────────────────────────────────────────────
  // Routed through the repository so they share the connectivity guard and
  // typed failures with the rest of the partnership calls.

  Future<Either<NetworkExceptions, PartnershipTerms>> getPartnershipTerms(
    String partnershipId,
  );

  Future<Either<NetworkExceptions, List<PartnershipTerms>>> getTermsVersions(
    String partnershipId,
  );

  Future<Either<NetworkExceptions, PotentialEarnings>> getPotentialEarnings(
    String partnershipId, {
    String? variantId,
  });

  Future<Either<NetworkExceptions, List<RecipeAttachmentInfo>>>
      getPartnershipRecipes(String partnershipId);
}
