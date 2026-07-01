import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:stylemint_mobile_frontend/features/wallet/presentation/notifiers/wallet_notifier.dart';

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>(
  (ref) => WalletRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepositoryImpl(
    remoteDataSource: ref.watch(walletRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    connectivity: Connectivity(),
  ),
);

final walletNotifierProvider =
    StateNotifierProvider.autoDispose<WalletNotifier, WalletState>(
  (ref) => WalletNotifier(ref.watch(walletRepositoryProvider)),
);
