import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/data/datasources/referrals_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/data/repositories/referrals_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/domain/repositories/referrals_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/presentation/notifiers/referrals_notifier.dart';

export 'package:stylemint_mobile_frontend/features/social/referrals/domain/entities/invite_link.dart';
export 'package:stylemint_mobile_frontend/features/social/referrals/presentation/notifiers/referrals_notifier.dart';

final referralsRemoteDataSourceProvider = Provider<ReferralsRemoteDataSource>(
  (ref) => ReferralsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final referralsRepositoryProvider = Provider<ReferralsRepository>(
  (ref) => ReferralsRepositoryImpl(
    remoteDataSource: ref.watch(referralsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final referralsNotifierProvider =
    StateNotifierProvider.autoDispose<ReferralsNotifier, ReferralsState>(
  (ref) => ReferralsNotifier(ref.watch(referralsRepositoryProvider)),
);
