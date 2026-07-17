import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/datasources/partnerships_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/repositories/partnerships_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/partnerships_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/notifiers/partnerships_notifier.dart';

// Re-export new DTO types consumed by UI widgets
export 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart'
    show PotentialEarningsDto, RecipeAttachmentInfoDto, MoneyDto;

final partnershipsRemoteDataSourceProvider =
    Provider<PartnershipsRemoteDataSource>(
      (ref) => PartnershipsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final partnershipsRepositoryProvider = Provider<PartnershipsRepository>(
  (ref) => PartnershipsRepositoryImpl(
    remoteDataSource: ref.watch(partnershipsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final partnershipsNotifierProvider =
    StateNotifierProvider<PartnershipsNotifier, PartnershipsState>(
      (ref) => PartnershipsNotifier(ref.watch(partnershipsRepositoryProvider)),
    );

/// Derived view: active partnerships only, empty while loading or on failure.
final activePartnershipsProvider = Provider<List<ActivePartnership>>((ref) {
  return ref.watch(partnershipsNotifierProvider).maybeWhen(
        loadSuccess: (_, active, _) => active,
        orElse: () => const [],
      );
});

/// Derived view: ended partnerships only, empty while loading or on failure.
final endedPartnershipsProvider = Provider<List<EndedPartnership>>((ref) {
  return ref.watch(partnershipsNotifierProvider).maybeWhen(
        loadSuccess: (_, _, ended) => ended,
        orElse: () => const [],
      );
});

/// Derived view: count of pending invites, 0 while loading or on failure.
final pendingInvitesCountProvider = Provider<int>((ref) {
  return ref.watch(partnershipsNotifierProvider).maybeWhen(
        loadSuccess: (invites, _, _) => invites
            .where((i) => i.status == PartnershipStatus.pending)
            .length,
        orElse: () => 0,
      );
});

/// Derived view: pending invites themselves (not just the count), empty
/// while loading or on failure. Real vendor-initiated invitations a
/// creator can accept/decline — used for the dashboard preview section.
final pendingInvitesProvider = Provider<List<PartnershipInvite>>((ref) {
  return ref.watch(partnershipsNotifierProvider).maybeWhen(
        loadSuccess: (invites, _, _) =>
            invites.where((i) => i.status == PartnershipStatus.pending).toList(),
        orElse: () => const [],
      );
});

/// Active terms for a given partnership id.
final partnershipTermsProvider = FutureProvider.autoDispose
    .family<PartnershipTermsDto, String>((ref, partnershipId) {
  return ref
      .watch(partnershipsRemoteDataSourceProvider)
      .getPartnershipTerms(partnershipId);
});

/// All terms versions for a given partnership id.
final partnershipTermsVersionsProvider = FutureProvider.autoDispose
    .family<List<PartnershipTermsDto>, String>((ref, partnershipId) {
  return ref
      .watch(partnershipsRemoteDataSourceProvider)
      .getTermsVersions(partnershipId);
});

/// Potential earnings projection for a given partnership (and optional variant).
final potentialEarningsProvider = FutureProvider.autoDispose
    .family<PotentialEarningsDto, (String partnershipId, String? variantId)>(
  (ref, args) {
    return ref
        .watch(partnershipsRemoteDataSourceProvider)
        .getPotentialEarnings(args.$1, variantId: args.$2);
  },
);

/// Recipes attached to a partnership brief.
final partnershipRecipesProvider = FutureProvider.autoDispose
    .family<List<RecipeAttachmentInfoDto>, String>((ref, partnershipId) {
  return ref
      .watch(partnershipsRemoteDataSourceProvider)
      .getPartnershipRecipes(partnershipId);
});
