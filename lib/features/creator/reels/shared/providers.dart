import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/datasources/creator_reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/repositories/creator_reels_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/post_publish_report.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/reel_product_tag.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/repositories/creator_reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/notifiers/creator_reel_actions_notifier.dart';

Future<void> deleteCreatorReel(WidgetRef ref, String reelId) async {
  final result = await ref
      .read(creatorReelsRepositoryProvider)
      .deleteReel(reelId);
  if (result.isRight()) {
    // The whole family, so no page size is left holding the deleted reel —
    // this used to list three (sortBy, order) keys by hand, which stopped
    // being the shape of the key and would have quietly missed others.
    ref.invalidate(creatorReelsPageProvider);
    ref.invalidate(creatorReelSummariesProvider);
    ref.invalidate(creatorReelCountProvider);
  }
}

// ── Infrastructure ────────────────────────────────────────────────────────────

final creatorReelsRemoteDataSourceProvider =
    Provider<CreatorReelsRemoteDataSource>(
      (ref) => CreatorReelsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final creatorReelsRepositoryProvider = Provider<CreatorReelsRepository>(
  (ref) => CreatorReelsRepositoryImpl(
    remoteDataSource: ref.watch(creatorReelsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// Unwraps a repository result for the `FutureProvider` reads below, which
/// signal failure by throwing so `AsyncValue.error` carries the message.
T _orThrow<T>(NetworkEither<T> result) => result.fold(
  // Throw the typed [NetworkExceptions] (not just its message) so the
  // screen's AsyncValue.error can branch on .isNotFound etc.
  // ignore: only_throw_errors
  (failure) => throw failure,
  (value) => value,
);
// ── Reel detail (auto-disposed, keyed by reelId) ──────────────────────────────

// ignore: specify_nonobvious_property_types
final creatorReelDetailProvider = FutureProvider.autoDispose
    .family<CreatorReelDetail, String>(
      (ref, reelId) async => _orThrow(
        await ref.watch(creatorReelsRepositoryProvider).getReelDetail(reelId),
      ),
    );

// ── Reel list (auto-disposed, keyed by page size) ─────────────────────────────
// The endpoint has no sort parameters — it always answers in cursor order —
// so the old (sortBy, order) key selected between identical requests.

// ignore: specify_nonobvious_property_types
final creatorReelsPageProvider = FutureProvider.autoDispose
    .family<CreatorReelsSummaryPage, int>(
      (ref, pageSize) async => _orThrow(
        await ref
            .watch(creatorReelsRepositoryProvider)
            .listCreatorReels(pageSize: pageSize),
      ),
    );

/// Just the reels of [creatorReelsPageProvider], for the lists that do not
/// care about the total.
// ignore: specify_nonobvious_property_types
final creatorReelSummariesProvider = FutureProvider.autoDispose
    .family<List<CreatorReelSummary>, int>(
      (ref, pageSize) async =>
          (await ref.watch(creatorReelsPageProvider(pageSize).future)).items,
    );

/// The creator's total reel count, drafts included. Used for the dashboard
/// stat, which cannot be derived from the analytics overview — see
/// [CreatorReelsSummaryPage].
// ignore: specify_nonobvious_property_types
final creatorReelCountProvider = FutureProvider.autoDispose<int>(
  (ref) async =>
      (await ref.watch(creatorReelsPageProvider(1).future)).totalCount,
);

// ── Tagged products for a reel (auto-disposed, keyed by reelId) ───────────────

// ignore: specify_nonobvious_property_types
final reelTaggedProductsProvider = FutureProvider.autoDispose
    .family<List<ReelProductTag>, String>(
      (ref, reelId) async => _orThrow(
        await ref
            .watch(creatorReelsRepositoryProvider)
            .listTaggedProducts(reelId),
      ),
    );

final postPublishReportProvider = FutureProvider.autoDispose
    .family<PostPublishReport, String>(
      (ref, reelId) async => _orThrow(
        await ref
            .watch(creatorReelsRepositoryProvider)
            .getPostPublishReport(reelId),
      ),
    );

// ── Write actions (publish / unpublish / tag / untag) ─────────────────────────

final creatorReelActionsNotifierProvider =
    StateNotifierProvider.autoDispose<
      CreatorReelActionsNotifier,
      CreatorReelActionState
    >(
      (ref) => CreatorReelActionsNotifier(
        ref.watch(creatorReelsRepositoryProvider),
      ),
    );
