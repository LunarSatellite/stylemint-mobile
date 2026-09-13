import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/datasources/memory_vault_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/repositories/memory_vault_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/settings_repository.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/memory_vault_notifier.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/settings_notifier.dart';

// ============================================================================
// DEPENDENCY INJECTION — settings feature
// ============================================================================

final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>(
  (ref) => SettingsRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(
    remoteDataSource: ref.watch(settingsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, NotificationPrefsState>(
      (ref) => SettingsNotifier(ref.watch(settingsRepositoryProvider)),
    );

final languageChangeNotifierProvider =
    StateNotifierProvider<LanguageChangeNotifier, LanguageChangeState>(
      (ref) => LanguageChangeNotifier(ref.watch(settingsRepositoryProvider)),
    );

final deleteAccountNotifierProvider =
    StateNotifierProvider<DeleteAccountNotifier, DeleteAccountState>(
      (ref) => DeleteAccountNotifier(ref.watch(settingsRepositoryProvider)),
    );

final logoutNotifierProvider =
    StateNotifierProvider<LogoutNotifier, LogoutState>(
      (ref) => LogoutNotifier(ref.watch(settingsRepositoryProvider)),
    );

final memoryVaultRemoteDataSourceProvider =
    Provider<MemoryVaultRemoteDataSource>(
      (ref) =>
          MemoryVaultRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final memoryVaultRepositoryProvider = Provider<MemoryVaultRepository>(
  (ref) => MemoryVaultRepositoryImpl(
    remoteDataSource: ref.watch(memoryVaultRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final memoryVaultNotifierProvider =
    StateNotifierProvider.autoDispose<MemoryVaultNotifier, MemoryVaultState>(
      (ref) => MemoryVaultNotifier(ref.watch(memoryVaultRepositoryProvider)),
    );

final pendingDeletionNotifierProvider =
    StateNotifierProvider<PendingDeletionNotifier, PendingDeletionState>(
      (ref) => PendingDeletionNotifier(ref.watch(settingsRepositoryProvider)),
    );
