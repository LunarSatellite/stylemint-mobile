import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/data/datasources/missions_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/data/repositories/missions_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/repositories/missions_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/notifiers/mission_detail_notifier.dart';

final missionsRemoteDataSourceProvider = Provider<MissionsRemoteDataSource>(
  (ref) => MissionsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final missionsRepositoryProvider = Provider<MissionsRepository>(
  (ref) => MissionsRepositoryImpl(
    remoteDataSource: ref.watch(missionsRemoteDataSourceProvider),
  ),
);

/// The shopper's missions. `null` state means every state.
// ignore: specify_nonobvious_property_types — Riverpod's own inferred type.
final missionListProvider = FutureProvider.autoDispose
    .family<MissionList, MissionState?>((ref, state) async {
      final result = await ref
          .watch(missionsRepositoryProvider)
          .list(state: state);
      return result.fold(
        Future<MissionList>.error,
        (list) => list,
      );
    });

// ignore: specify_nonobvious_property_types — Riverpod's own inferred type.
final missionDetailProvider = StateNotifierProvider.autoDispose
    .family<MissionDetailNotifier, MissionDetailState, String>(
      (ref, missionId) => MissionDetailNotifier(
        ref.watch(missionsRepositoryProvider),
        missionId,
      ),
    );
