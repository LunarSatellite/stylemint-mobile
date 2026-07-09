import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/support/data/datasources/support_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/support/data/repositories/support_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/repositories/support_repository.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/notifiers/support_notifier.dart';

// ============================================================================
// DEPENDENCY INJECTION — support feature
// ============================================================================

final supportRemoteDataSourceProvider = Provider<SupportRemoteDataSource>(
  (ref) => SupportRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepositoryImpl(
    remoteDataSource: ref.watch(supportRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final supportNotifierProvider =
    StateNotifierProvider<SupportNotifier, TicketsState>(
      (ref) => SupportNotifier(ref.watch(supportRepositoryProvider)),
    );

final categoriesNotifierProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>(
      (ref) => CategoriesNotifier(ref.watch(supportRepositoryProvider)),
    );

final createTicketNotifierProvider =
    StateNotifierProvider<CreateTicketNotifier, CreateTicketState>(
      (ref) => CreateTicketNotifier(ref.watch(supportRepositoryProvider)),
    );
