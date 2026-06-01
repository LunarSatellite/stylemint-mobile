import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

abstract interface class DropPartyRepository {
  Future<Either<NetworkExceptions, List<DropParty>>> getActiveDropParties();

  Future<Either<NetworkExceptions, DropParty>> getDropParty(String partyId);

  Future<Either<NetworkExceptions, DropParty>> createDropParty({
    required String title,
    required String description,
    required String productId,
    required Money dropPrice,
    required int maxParticipants,
    required DateTime startsAt,
    required DateTime endsAt,
  });

  Future<Either<NetworkExceptions, DropParty>> joinDropParty(String partyId);

  Future<Either<NetworkExceptions, Unit>> inviteToParty(
    String partyId,
    List<String> userIds,
  );

  Future<Either<NetworkExceptions, DropParty>> scanInviteQr(String qrCode);
}
