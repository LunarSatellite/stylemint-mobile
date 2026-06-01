import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';

abstract interface class PartnershipsRepository {
  Future<Either<NetworkExceptions, List<PartnershipInvite>>> getInvites();

  Future<Either<NetworkExceptions, PartnershipInvite>> acceptInvite(String inviteId);

  Future<Either<NetworkExceptions, Unit>> declineInvite(String inviteId);

  Future<Either<NetworkExceptions, List<ActivePartnership>>> getActivePartnerships();
}
