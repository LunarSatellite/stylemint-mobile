import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/data/datasources/customer_kyc_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/data/repositories/customer_kyc_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/repositories/customer_kyc_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/presentation/notifiers/customer_kyc_notifier.dart';

final customerKycRemoteDataSourceProvider =
    Provider<CustomerKycRemoteDataSource>(
      (ref) =>
          CustomerKycRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final customerKycRepositoryProvider = Provider<CustomerKycRepository>(
  (ref) => CustomerKycRepositoryImpl(
    remoteDataSource: ref.watch(customerKycRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// The buyer's KYC record and any submission in progress. Shared by the
/// status screen and the form above it, which stays alive while the form is
/// open; dropped when both are closed so the next visit reads it fresh.
final customerKycNotifierProvider =
    StateNotifierProvider.autoDispose<CustomerKycNotifier, CustomerKycState>(
      (ref) {
        final notifier = CustomerKycNotifier(
          ref.watch(customerKycRepositoryProvider),
        );
        unawaited(notifier.load());
        return notifier;
      },
    );
