import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/datasources/payout_destinations_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/payouts/presentation/notifiers/payout_destinations_controller.dart';

final payoutDestinationsDataSourceProvider =
    Provider<PayoutDestinationsRemoteDataSource>(
  (ref) => PayoutDestinationsRemoteDataSource(
      apiClient: ref.watch(apiClientProvider)),
);

/// Keyed by PayeeKind int value (1 = creator, 2 = vendor).
final payoutDestinationsControllerProvider = StateNotifierProvider.family
    .autoDispose<PayoutDestinationsController, PayoutDestinationsState, int>(
  (ref, role) => PayoutDestinationsController(
    ref.watch(payoutDestinationsDataSourceProvider),
    role,
  ),
);
