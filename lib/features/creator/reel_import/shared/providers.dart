import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/datasources/reel_import_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/repositories/reel_import_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/repositories/tag_product_commission_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/tag_product_commission.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/reel_import_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/tag_product_commission_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/last_import_platform_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

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

/// Last platform the creator imported from, persisted on the device.
final lastImportPlatformProvider =
    StateNotifierProvider<LastImportPlatformNotifier, SocialPlatform?>(
      (ref) => LastImportPlatformNotifier(),
    );

final importHistoryNotifierProvider =
    StateNotifierProvider<ImportHistoryNotifier, ImportHistoryState>(
      (ref) => ImportHistoryNotifier(ref.watch(reelImportRepositoryProvider)),
    );

final productSearchNotifierProvider =
    StateNotifierProvider<ProductSearchNotifier, ProductSearchState>(
      (ref) => ProductSearchNotifier(ref.watch(reelImportRepositoryProvider)),
    );

/// Search state owned exclusively by the tag-products search sheet so
/// results typed in the sheet never leak into the main screen's
/// suggested-products list (which has its own dedicated state).
final productSearchSheetNotifierProvider =
    StateNotifierProvider.autoDispose<ProductSearchNotifier, ProductSearchState>(
      (ref) => ProductSearchNotifier(ref.watch(reelImportRepositoryProvider)),
    );

/// Owns the suggested-products list for the tag-products screen so it can
/// be reloaded independently of the search sheet and never collide with it.
final suggestedProductsNotifierProvider =
    StateNotifierProvider<SuggestedProductsNotifier, SuggestedProductsState>(
      (ref) =>
          SuggestedProductsNotifier(ref.watch(reelImportRepositoryProvider)),
    );

final reelSubmitNotifierProvider =
    StateNotifierProvider.autoDispose<ReelSubmitNotifier, ReelSubmitState>(
      (ref) => ReelSubmitNotifier(ref.watch(reelImportRepositoryProvider)),
    );

final bulkImportNotifierProvider =
    StateNotifierProvider.autoDispose<BulkImportNotifier, BulkImportState>(
      (ref) => BulkImportNotifier(ref.watch(reelImportRepositoryProvider)),
    );

final reelIntentNotifierProvider = StateNotifierProvider.autoDispose<
    ReelIntentNotifier, ReelIntentNotifierState>(
  (ref) => ReelIntentNotifier(ref.watch(reelImportRepositoryProvider)),
);

// ── Real commission terms for the products on screen ────────────────────────

final tagProductCommissionRepositoryProvider =
    Provider<TagProductCommissionRepository>(
      (ref) => TagProductCommissionRepositoryImpl(
        remoteDataSource: ref.watch(reelImportRemoteDataSourceProvider),
        networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
      ),
    );

/// Builds the family key for [tagProductCommissionsProvider] from the ids a
/// list is about to render.
///
/// The key is the deduplicated, sorted ids joined by a comma, so the same set
/// in a different order is the same provider and is fetched once. A
/// `List<String>` cannot be a family argument — two equal lists are not
/// `==` — and keying on the list identity would refetch on every rebuild.
String tagProductCommissionKey(Iterable<String> productIds) {
  final ids = productIds.where((id) => id.isNotEmpty).toSet().toList()..sort();
  return ids.join(',');
}

/// Real commission terms, keyed by product id, for a whole list of products
/// in one request.
///
/// Watch it **once per list** with [tagProductCommissionKey] and hand each
/// card its own entry. Watching it per card would issue a call per card,
/// which is exactly the N+1 the batched endpoint exists to prevent.
///
/// A product missing from the map has no answer, and a product whose answer
/// is `NoPartnership` has no rate. Neither draws a figure; neither draws a
/// zero.
// ignore: specify_nonobvious_property_types
final tagProductCommissionsProvider = FutureProvider.autoDispose
    .family<Map<String, TagProductCommission>, String>((ref, key) async {
      final ids = key.isEmpty ? const <String>[] : key.split(',');
      final result = await ref
          .watch(tagProductCommissionRepositoryProvider)
          .getCommissions(ids);
      return result.fold(
        (failure) => throw Exception(NetworkExceptions.getMessage(failure)),
        (value) => value,
      );
    });
