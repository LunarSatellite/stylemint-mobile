import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/data/datasources/missions_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/data/models/shopping_mission_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/repositories/missions_repository.dart';
import 'package:uuid/uuid.dart';

class MissionsRepositoryImpl implements MissionsRepository {
  MissionsRepositoryImpl({required this.remoteDataSource});

  final MissionsRemoteDataSource remoteDataSource;

  static const _uuid = Uuid();

  /// The errorCode a terminal mission answers any change with.
  static const String invalidTransitionCode = 'state.invalid_transition';

  @override
  Future<Either<NetworkExceptions, MissionList>> list({
    MissionState? state,
    String? cursor,
  }) => _call(
    () async => missionListFromJson(
      await remoteDataSource.list(state: state, cursor: cursor),
    ),
  );

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> get(String missionId) =>
      _call(
        () async =>
            shoppingMissionFromJson(await remoteDataSource.get(missionId)),
      );

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> start({
    required String missionText,
    required int maxItems,
    double? budgetAmount,
  }) => _call(
    () async => shoppingMissionFromJson(
      await remoteDataSource.start(
        missionText: missionText,
        maxItems: maxItems.clamp(1, 8),
        budgetAmount: budgetAmount,
        idempotencyKey: _uuid.v4(),
      ),
    ),
  );

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> replan(String missionId) =>
      _call(
        () async => shoppingMissionFromJson(
          await remoteDataSource.replan(missionId, _uuid.v4()),
        ),
      );

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> setItemState({
    required String missionId,
    required String itemId,
    required MissionItemState state,
  }) => _call(
    () async => shoppingMissionFromJson(
      await remoteDataSource.setItemState(
        missionId: missionId,
        itemId: itemId,
        state: state,
        idempotencyKey: _uuid.v4(),
      ),
    ),
  );

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> complete(
    String missionId,
  ) => _call(
    () async => shoppingMissionFromJson(
      await remoteDataSource.complete(missionId, _uuid.v4()),
    ),
  );

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> abandon(
    String missionId,
  ) => _call(
    () async => shoppingMissionFromJson(
      await remoteDataSource.abandon(missionId, _uuid.v4()),
    ),
  );

  Future<Either<NetworkExceptions, T>> _call<T>(
    Future<T> Function() body,
  ) async {
    try {
      return right(await body());
    } on DioException catch (e) {
      return left(mapDioExceptionToNetworkException(e));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
