import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/datasources/creator_reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/models/creator_reel_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/repositories/creator_reels_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/repositories/creator_reels_repository.dart';

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

// ── Reel detail (auto-disposed, keyed by reelId) ──────────────────────────────

// ignore: specify_nonobvious_property_types
final creatorReelDetailProvider =
    FutureProvider.autoDispose.family<CreatorReelDetail, String>(
  (ref, reelId) async {
    final repo = ref.watch(creatorReelsRepositoryProvider);
    final result = await repo.getReelDetail(reelId);
    return result.fold(
      (failure) => throw Exception(NetworkExceptions.getMessage(failure)),
      (detail) => detail,
    );
  },
);

// ── Reel list (auto-disposed, keyed by (sortBy, order)) ───────────────────────
// sortBy: 'publishedAt' | 'views'   order: 'asc' | 'desc'

// ignore: specify_nonobvious_property_types
final creatorReelSummariesProvider = FutureProvider.autoDispose
    .family<List<CreatorReelSummary>, (String sortBy, String order)>(
  (ref, args) async {
    final repo = ref.watch(creatorReelsRepositoryProvider);
    final result = await repo.listCreatorReels(
      sortBy: args.$1,
      order: args.$2,
    );
    return result.fold(
      (failure) => throw Exception(NetworkExceptions.getMessage(failure)),
      (reels) => reels,
    );
  },
);

// ── Tagged products for a reel (auto-disposed, keyed by reelId) ───────────────

// ignore: specify_nonobvious_property_types
final reelTaggedProductsProvider =
    FutureProvider.autoDispose.family<List<ReelTagManagementDto>, String>(
  (ref, reelId) =>
      ref.watch(creatorReelsRemoteDataSourceProvider).listTaggedProducts(reelId),
);
