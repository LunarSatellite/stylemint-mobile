import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/domain/entities/invite_link.dart';

abstract interface class ReferralsRepository {
  /// The caller's own invite link — creates one on first use if none
  /// exists yet, since every account gets exactly one active referral
  /// link in the UI (renew/revoke are still separate explicit actions).
  Future<Either<NetworkExceptions, InviteLink>> getOrCreateMyLink();

  Future<Either<NetworkExceptions, List<InviteRedemption>>> getRedemptions(
    String linkId,
  );

  Future<Either<NetworkExceptions, Unit>> redeem(String code);
}
