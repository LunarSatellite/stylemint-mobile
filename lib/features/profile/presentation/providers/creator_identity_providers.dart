import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/core/auth/jwt_roles.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/creator_social_links.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';

/// The signed-in account id, resolved from secure storage. Recomputes when the
/// session changes.
final currentAccountIdProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  ref.watch(sessionControllerProvider);
  return ref.watch(tokenStorageProvider).accountId;
});

/// The account's active @handle (without the leading `@`), or null if none.
final activeHandleProvider = FutureProvider.autoDispose<String?>((ref) async {
  final accountId = await ref.watch(currentAccountIdProvider.future);
  if (accountId == null || accountId.isEmpty) return null;
  final either = await ref.watch(authRepositoryProvider).listHandles(accountId);
  return either.fold((_) => null, (handles) {
    if (handles.isEmpty) return null;
    final active = handles.firstWhere(
      (h) => h.isActive ?? false,
      orElse: () => handles.first,
    );
    return active.handle;
  });
});

/// AI-derived creator specializations. Best-effort — empty on failure or while
/// the backend is still populating them asynchronously after activation.
final creatorSpecializationsProvider = FutureProvider.autoDispose<List<String>>(
  (ref) async {
    final accountId = await ref.watch(currentAccountIdProvider.future);
    if (accountId == null || accountId.isEmpty) return const [];
    final either = await ref
        .watch(authRepositoryProvider)
        .listCreatorSpecializations(accountId);
    return either.fold((_) => const <String>[], (list) => list);
  },
);

/// Handles rendered by the creator-only social-link fields in Edit Profile.
final creatorSocialLinksProvider =
    FutureProvider.autoDispose<CreatorSocialLinks?>((ref) async {
      final isCreator = await ref.watch(isCreatorProvider.future);
      if (!isCreator) return null;
      final either = await ref
          .watch(profileRepositoryProvider)
          .getCreatorSocialLinks();
      return either.fold((_) => null, (links) => links);
    });
