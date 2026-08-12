import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/data/datasources/inquiries_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/data/repositories/inquiries_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/repositories/inquiries_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/presentation/notifiers/inquiries_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/inquiries/presentation/notifiers/inquiries_notifier.dart';

final inquiriesRemoteDataSourceProvider = Provider<InquiriesRemoteDataSource>(
  (ref) =>
      InquiriesRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final inquiriesRepositoryProvider = Provider<InquiriesRepository>(
  (ref) => InquiriesRepositoryImpl(
    remoteDataSource: ref.watch(inquiriesRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final inquiriesNotifierProvider =
    StateNotifierProvider.autoDispose<InquiriesNotifier, InquiriesState>(
  (ref) => InquiriesNotifier(ref.watch(inquiriesRepositoryProvider)),
);
