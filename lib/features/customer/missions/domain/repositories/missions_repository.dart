import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';

abstract class MissionsRepository {
  Future<Either<NetworkExceptions, MissionList>> list({
    MissionState? state,
    String? cursor,
  });

  Future<Either<NetworkExceptions, ShoppingMission>> get(String missionId);

  Future<Either<NetworkExceptions, ShoppingMission>> start({
    required String missionText,
    required int maxItems,
    double? budgetAmount,
  });

  Future<Either<NetworkExceptions, ShoppingMission>> replan(String missionId);

  Future<Either<NetworkExceptions, ShoppingMission>> setItemState({
    required String missionId,
    required String itemId,
    required MissionItemState state,
  });

  Future<Either<NetworkExceptions, ShoppingMission>> complete(String missionId);

  Future<Either<NetworkExceptions, ShoppingMission>> abandon(String missionId);
}
