import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/datasources/brands_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/datasources/partnerships_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/repositories/brands_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/repositories/partnerships_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/brand.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_terms.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/brands_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/partnerships_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/notifiers/partnerships_notifier.dart';

// Re-export new DTO types consumed by UI widgets
export 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart'
    show BrandDetailDto, BrandTrustDto, MoneyDto, PotentialEarningsDto, RecipeAttachmentInfoDto;

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

final brandsRemoteDataSourceProvider = Provider<BrandsRemoteDataSource>(
  (ref) => BrandsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final brandsRepositoryProvider = Provider<BrandsRepository>(
  (ref) => BrandsRepositoryImpl(
    remoteDataSource: ref.watch(brandsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// Unwraps a repository result for the read providers below, which signal
/// failure by throwing so `AsyncValue.error` carries the message.
T _orThrow<T>(NetworkEither<T> result) => result.fold(
      (failure) => throw Exception(NetworkExceptions.getMessage(failure)),
      (value) => value,
    );

/// Creator §7A "Browse all Brands" — real approved-vendor catalog.
final brandsListProvider = FutureProvider.autoDispose<List<Brand>>(
  (ref) async => _orThrow(await ref.watch(brandsRepositoryProvider).listBrands()),
);

/// Creator §7A "Recommended Brands for You".
final recommendedBrandsProvider = FutureProvider.autoDispose<List<Brand>>(
  (ref) async =>
      _orThrow(await ref.watch(brandsRepositoryProvider).listRecommendedBrands()),
);

/// Active terms for a given partnership id.
final partnershipTermsProvider =
    FutureProvider.autoDispose.family<PartnershipTerms, String>(
  (ref, partnershipId) async => _orThrow(
    await ref
        .watch(partnershipsRepositoryProvider)
        .getPartnershipTerms(partnershipId),
  ),
);

/// All terms versions for a given partnership id.
final partnershipTermsVersionsProvider =
    FutureProvider.autoDispose.family<List<PartnershipTerms>, String>(
  (ref, partnershipId) async => _orThrow(
    await ref
        .watch(partnershipsRepositoryProvider)
        .getTermsVersions(partnershipId),
  ),
);

/// Potential earnings projection for a given partnership (and optional variant).
final potentialEarningsProvider = FutureProvider.autoDispose
    .family<PotentialEarnings, (String partnershipId, String? variantId)>(
  (ref, args) async => _orThrow(
    await ref
        .watch(partnershipsRepositoryProvider)
        .getPotentialEarnings(args.$1, variantId: args.$2),
  ),
);

/// Recipes attached to a partnership brief.
final partnershipRecipesProvider =
    FutureProvider.autoDispose.family<List<RecipeAttachmentInfo>, String>(
  (ref, partnershipId) async => _orThrow(
    await ref
        .watch(partnershipsRepositoryProvider)
        .getPartnershipRecipes(partnershipId),
  ),
);

/// Creator §7B/C/D brand detail — single approved-vendor profile
/// (`GET /v1/brands/{vendorAccountId}`). DB-backed; replaces the
/// previously hardcoded `BrandInfoData` stub values.
final brandDetailProvider = FutureProvider.autoDispose
    .family<BrandDetailDto, String>((ref, vendorAccountId) {
  return ref.watch(brandsRemoteDataSourceProvider).getBrand(vendorAccountId);
});

/// Creator §7B/C/D brand detail — trust score
/// (`GET /v1/creator/brands/{vendorAccountId}/trust`). Powers the
/// "rating" and "success rate" tiles on the brand detail header.
/// Treated as optional by the screen — a 404 just hides those tiles
/// instead of breaking the whole page.
final brandTrustProvider = FutureProvider.autoDispose
    .family<BrandTrustDto, String>((ref, vendorAccountId) {
  return ref
      .watch(brandsRemoteDataSourceProvider)
      .getBrandTrust(vendorAccountId);
});
