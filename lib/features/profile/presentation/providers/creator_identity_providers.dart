import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

/// The signed-in account id, resolved from secure storage. Recomputes when the
/// session changes.
final currentAccountIdProvider = FutureProvider.autoDispose<String?>((ref) async {
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
final creatorSpecializationsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final accountId = await ref.watch(currentAccountIdProvider.future);
  if (accountId == null || accountId.isEmpty) return const [];
  final either = await ref
      .watch(authRepositoryProvider)
      .listCreatorSpecializations(accountId);
  return either.fold((_) => const <String>[], (list) => list);
});
