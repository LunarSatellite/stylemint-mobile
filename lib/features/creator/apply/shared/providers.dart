import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/datasources/creator_documents_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/datasources/creator_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/repositories/creator_documents_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/repositories/creator_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_documents_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_activate_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_documents_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_apply_notifier.dart';

export 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_activate_notifier.dart';
export 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_apply_notifier.dart';

// ============================================================================
// DEPENDENCY INJECTION — creator apply feature
// ============================================================================

final creatorApplyRemoteDataSourceProvider = Provider<CreatorRemoteDataSource>(
  (ref) => CreatorRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final creatorRepositoryProvider = Provider<CreatorRepository>(
  (ref) => CreatorRepositoryImpl(
    remoteDataSource: ref.watch(creatorApplyRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final creatorApplyNotifierProvider =
    StateNotifierProvider<CreatorApplyNotifier, ApplicationStatusState>(
      (ref) => CreatorApplyNotifier(ref.watch(creatorRepositoryProvider)),
    );

/// Single-step creator activation (replaces the old multi-step apply flow).
final creatorActivateNotifierProvider =
    StateNotifierProvider<CreatorActivateNotifier, CreatorActivateState>(
      (ref) => CreatorActivateNotifier(ref.watch(creatorRepositoryProvider), ref),
    );

/// Active creator content categories for the apply form, fetched live from
/// `GET /v1/public/creator-categories`. Exposed as an AsyncValue so the UI can
/// show loading/error/retry; the value list drives the category chips.
final creatorContentCategoriesProvider =
    FutureProvider<List<CreatorContentCategory>>((ref) async {
  final either =
      await ref.watch(creatorRepositoryProvider).getContentCategories();
  return either.fold((failure) => throw failure, (categories) => categories);
});

// ── Identity documents (KYC) ─────────────────────────────────────────────────
// Backed by the Identity module's account-scoped verification-document and
// kyc-session endpoints — the same pipeline vendors use. There is no
// creator-scoped document API and one should not be added.

final creatorDocumentsRemoteDataSourceProvider =
    Provider<CreatorDocumentsRemoteDataSource>(
  (ref) => CreatorDocumentsRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final creatorDocumentsRepositoryProvider = Provider<CreatorDocumentsRepository>(
  (ref) => CreatorDocumentsRepositoryImpl(
    remoteDataSource: ref.watch(creatorDocumentsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final creatorDocumentsNotifierProvider = StateNotifierProvider<
    CreatorDocumentsNotifier, CreatorDocumentsState>(
  (ref) => CreatorDocumentsNotifier(
    ref.watch(creatorDocumentsRepositoryProvider),
  ),
);
