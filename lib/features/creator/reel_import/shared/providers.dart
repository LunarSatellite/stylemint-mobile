import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/datasources/reel_import_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/repositories/reel_import_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/reel_import_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';

final reelImportRemoteDataSourceProvider =
    Provider<ReelImportRemoteDataSource>(
      (ref) => ReelImportRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final reelImportRepositoryProvider = Provider<ReelImportRepository>(
  (ref) => ReelImportRepositoryImpl(
    remoteDataSource: ref.watch(reelImportRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final reelImportNotifierProvider =
    StateNotifierProvider<ReelImportNotifier, ReelImportState>(
      (ref) => ReelImportNotifier(ref.watch(reelImportRepositoryProvider)),
    );

final importHistoryNotifierProvider =
    StateNotifierProvider<ImportHistoryNotifier, ImportHistoryState>(
      (ref) => ImportHistoryNotifier(ref.watch(reelImportRepositoryProvider)),
    );

final productSearchNotifierProvider =
    StateNotifierProvider<ProductSearchNotifier, ProductSearchState>(
      (ref) => ProductSearchNotifier(ref.watch(reelImportRepositoryProvider)),
    );
