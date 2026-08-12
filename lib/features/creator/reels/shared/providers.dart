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
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/reel_product_tag.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/repositories/creator_reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/notifiers/creator_reel_actions_notifier.dart';

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
      (failure) => throw Exception(NetworkExceptions.getMessage(failure)),
      (value) => value,
    );

// ── Reel detail (auto-disposed, keyed by reelId) ──────────────────────────────

// ignore: specify_nonobvious_property_types
final creatorReelDetailProvider =
    FutureProvider.autoDispose.family<CreatorReelDetail, String>(
  (ref, reelId) async => _orThrow(
    await ref.watch(creatorReelsRepositoryProvider).getReelDetail(reelId),
  ),
);

// ── Reel list (auto-disposed, keyed by (sortBy, order)) ───────────────────────
// sortBy: 'publishedAt' | 'views'   order: 'asc' | 'desc'

// ignore: specify_nonobvious_property_types
final creatorReelSummariesProvider = FutureProvider.autoDispose
    .family<List<CreatorReelSummary>, (String sortBy, String order)>(
  (ref, args) async => _orThrow(
    await ref.watch(creatorReelsRepositoryProvider).listCreatorReels(
          sortBy: args.$1,
          order: args.$2,
        ),
  ),
);

// ── Tagged products for a reel (auto-disposed, keyed by reelId) ───────────────

// ignore: specify_nonobvious_property_types
final reelTaggedProductsProvider =
    FutureProvider.autoDispose.family<List<ReelProductTag>, String>(
  (ref, reelId) async => _orThrow(
    await ref.watch(creatorReelsRepositoryProvider).listTaggedProducts(reelId),
  ),
);

// ── Write actions (publish / unpublish / tag / untag) ─────────────────────────

final creatorReelActionsNotifierProvider = StateNotifierProvider.autoDispose<
    CreatorReelActionsNotifier, CreatorReelActionState>(
  (ref) => CreatorReelActionsNotifier(
    ref.watch(creatorReelsRepositoryProvider),
  ),
);
