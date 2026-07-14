import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/datasources/creator_profile_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/repositories/creator_profile_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/badge_award.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/creator_profile.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/repositories/creator_profile_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/notifiers/badges_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/notifiers/creator_profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final creatorProfileRemoteDataSourceProvider =
    Provider<CreatorProfileRemoteDataSource>(
  (ref) => CreatorProfileRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  ),
);

final creatorProfileRepositoryProvider = Provider<CreatorProfileRepository>(
  (ref) => CreatorProfileRepositoryImpl(
    remoteDataSource: ref.watch(creatorProfileRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

// ── Profile load (family: one instance per accountId) ─────────────────────────

final creatorProfileNotifierProvider = StateNotifierProvider.family<
    CreatorProfileNotifier, CreatorProfileState, String>(
  (ref, accountId) => CreatorProfileNotifier(
    ref.watch(creatorProfileRepositoryProvider),
    accountId,
  ),
);

/// Derived view: resolved profile for a given accountId, null while loading or
/// on failure. Consumers don't need to import the notifier to call maybeWhen.
final resolvedCreatorProfileProvider =
    Provider.family<CreatorProfile?, String>(
  (ref, accountId) {
    if (accountId.isEmpty) return null;
    return ref.watch(creatorProfileNotifierProvider(accountId)).maybeWhen(
          loadSuccess: (p) => p,
          orElse: () => null,
        );
  },
);

// ── Profile update ────────────────────────────────────────────────────────────

final updateCreatorProfileNotifierProvider =
    StateNotifierProvider.autoDispose<
        UpdateCreatorProfileNotifier, UpdateCreatorProfileState>(
  (ref) => UpdateCreatorProfileNotifier(
    ref.watch(creatorProfileRepositoryProvider),
  ),
);

// ── Avatar (local file path, cleared on navigation) ──────────────────────────

class AvatarImageNotifier extends StateNotifier<String?> {
  AvatarImageNotifier() : super(null);

  void setPath(String path) => state = path;
}

final avatarImagePathProvider =
    StateNotifierProvider<AvatarImageNotifier, String?>(
  (ref) => AvatarImageNotifier(),
);

// ── Editable form state (seeded from loaded profile, mutated locally) ─────────

class CreatorProfileEditData {
  const CreatorProfileEditData({
    required this.displayName,
    required this.bio,
    required this.tags,
    required this.niches,
  });

  final String displayName;
  final String bio;
  final List<String> tags;
  final Set<String> niches;

  CreatorProfileEditData copyWith({
    String? displayName,
    String? bio,
    List<String>? tags,
    Set<String>? niches,
  }) =>
      CreatorProfileEditData(
        displayName: displayName ?? this.displayName,
        bio: bio ?? this.bio,
        tags: tags ?? this.tags,
        niches: niches ?? this.niches,
      );
}

class CreatorProfileEditNotifier
    extends StateNotifier<CreatorProfileEditData> {
  CreatorProfileEditNotifier()
      : super(const CreatorProfileEditData(
          displayName: '',
          bio: '',
          tags: [],
          niches: {},
        ));

  /// Called once the remote profile loads — replaces placeholder defaults with
  /// real values from the backend.
  void seed(CreatorProfile profile) {
    state = CreatorProfileEditData(
      displayName: profile.displayName,
      bio: profile.bio,
      tags: List<String>.from(profile.tags),
      niches: Set<String>.from(profile.niches),
    );
  }

  void update({
    required String displayName,
    required String bio,
    required List<String> tags,
    required Set<String> niches,
  }) =>
      state = state.copyWith(
        displayName: displayName,
        bio: bio,
        tags: List<String>.from(tags),
        niches: Set<String>.from(niches),
      );
}

final creatorProfileEditProvider =
    StateNotifierProvider<CreatorProfileEditNotifier, CreatorProfileEditData>(
  (ref) => CreatorProfileEditNotifier(),
);

// ── Creator specializations ───────────────────────────────────────────────────

/// Category IDs (GUIDs) of the creator's active specializations.
/// Used by the edit screen to compute add/remove diffs.
final creatorSpecializationIdsProvider =
    FutureProvider.family.autoDispose<List<String>, String>(
  (ref, accountId) async {
    if (accountId.isEmpty) return const [];
    final either = await ref
        .read(creatorProfileRepositoryProvider)
        .listSpecializationCategoryIds(accountId);
    return either.fold((_) => const [], (ids) => ids);
  },
);

// ── Badges ────────────────────────────────────────────────────────────────────

final badgesNotifierProvider =
    StateNotifierProvider<BadgesNotifier, BadgesState>(
  (ref) => BadgesNotifier(ref.watch(creatorProfileRepositoryProvider)),
);

final updateShowcaseNotifierProvider =
    StateNotifierProvider<UpdateShowcaseNotifier, UpdateShowcaseState>(
  (ref) => UpdateShowcaseNotifier(ref.watch(creatorProfileRepositoryProvider)),
);

/// Showcased badges in display order (up to 4), derived from the loaded list.
final showcasedBadgesProvider = Provider<List<BadgeAward>>(
  (ref) => ref
      .watch(badgesNotifierProvider)
      .maybeWhen(
        loadSuccess: (badges) => badges
            .where((b) => b.isShowcased)
            .toList()
          ..sort((a, b) =>
              (a.showcasedOrder ?? 99).compareTo(b.showcasedOrder ?? 99)),
        orElse: () => const [],
      ),
);

/// Resolved category names for the creator's active specializations.
/// Used by the profile screen to display niche chips.
final creatorNicheNamesProvider =
    FutureProvider.family.autoDispose<List<String>, String>(
  (ref, accountId) async {
    if (accountId.isEmpty) return const [];
    final results = await Future.wait([
      ref.watch(creatorSpecializationIdsProvider(accountId).future),
      ref.watch(productCategoriesProvider.future),
    ]);
    final ids = results[0] as List<String>;
    final categories = results[1] as List<CategoryOption>;
    if (ids.isEmpty) return const [];
    final catMap = {for (final c in categories) c.id: c.name};
    return ids
        .map((id) => catMap[id] ?? '')
        .where((n) => n.isNotEmpty)
        .toList(growable: false);
  },
);
