import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/data/datasources/payment_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/data/repositories/payment_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/repositories/payment_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/presentation/notifiers/payment_notifier.dart';

final paymentRemoteDataSourceProvider = Provider<PaymentRemoteDataSource>(
  (ref) => PaymentRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepositoryImpl(
    remoteDataSource: ref.watch(paymentRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final paymentNotifierProvider =
    StateNotifierProvider<PaymentNotifier, PaymentMethodsState>(
      (ref) => PaymentNotifier(ref.watch(paymentRepositoryProvider)),
    );
