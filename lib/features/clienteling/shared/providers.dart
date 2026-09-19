import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/data/datasources/clienteling_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/data/repositories/clienteling_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/repositories/clienteling_repository.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/notifiers/client_book_notifier.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/notifiers/client_brief_notifier.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/presentation/notifiers/my_clienteling_notifier.dart';

export 'package:stylemint_mobile_frontend/features/clienteling/presentation/notifiers/client_book_notifier.dart';
export 'package:stylemint_mobile_frontend/features/clienteling/presentation/notifiers/client_brief_notifier.dart';
export 'package:stylemint_mobile_frontend/features/clienteling/presentation/notifiers/my_clienteling_notifier.dart';

final clientelingRemoteDataSourceProvider =
    Provider<ClientelingRemoteDataSource>(
      (ref) =>
          ClientelingRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final associateClientelingRepositoryProvider =
    Provider<AssociateClientelingRepository>(
      (ref) => AssociateClientelingRepositoryImpl(
        remoteDataSource: ref.watch(clientelingRemoteDataSourceProvider),
        networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
      ),
    );

final customerClientelingRepositoryProvider =
    Provider<CustomerClientelingRepository>(
      (ref) => CustomerClientelingRepositoryImpl(
        remoteDataSource: ref.watch(clientelingRemoteDataSourceProvider),
        networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
      ),
    );

/// The associate's client book.
final StateNotifierProvider<ClientBookNotifier, ClientBookState>
clientBookNotifierProvider =
    StateNotifierProvider.autoDispose<ClientBookNotifier, ClientBookState>(
      (ref) =>
          ClientBookNotifier(ref.watch(associateClientelingRepositoryProvider)),
    );

/// One client's workspace. Keyed by customer account id; auto-disposed so
/// leaving the screen does not keep a customer's brief in memory.
final StateNotifierProviderFamily<ClientBriefNotifier, ClientBriefState, String>
clientBriefNotifierProvider = StateNotifierProvider.autoDispose
    .family<ClientBriefNotifier, ClientBriefState, String>(
      (ref, customerAccountId) => ClientBriefNotifier(
        ref.watch(associateClientelingRepositoryProvider),
        customerAccountId,
      ),
    );

/// The shopper's own clienteling record.
final StateNotifierProvider<MyClientelingNotifier, MyClientelingState>
myClientelingNotifierProvider =
    StateNotifierProvider.autoDispose<
      MyClientelingNotifier,
      MyClientelingState
    >(
      (ref) => MyClientelingNotifier(
        ref.watch(customerClientelingRepositoryProvider),
      ),
    );
