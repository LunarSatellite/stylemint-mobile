import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';

abstract interface class DropPartyRepository {
  Future<Either<NetworkExceptions, List<DropParty>>> getActiveDropParties();

  Future<Either<NetworkExceptions, DropParty>> getDropParty(String partyId);

  Future<Either<NetworkExceptions, void>> rsvp(String partyId);
  Future<Either<NetworkExceptions, void>> joinLive(String partyId);

  Future<Either<NetworkExceptions, DropParty>> scanInviteQr(String qrCode);
}
