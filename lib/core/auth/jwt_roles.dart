import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

/// Decodes the `roles` claim from a JWT access token **without** verifying the
/// signature. This is for UI gating only — the server is the source of truth
/// and still enforces authorization (a Customer-only token gets 403 on
/// `/v1/creator/*`). We only use it to avoid firing creator calls / to show a
/// "Become a creator" CTA when the role is absent.
Set<String> rolesFromJwt(String? jwt) {
  if (jwt == null || jwt.isEmpty) return const {};
  final parts = jwt.split('.');
  if (parts.length != 3) return const {};
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final roles = map['roles'];
    if (roles is List) {
      return roles.map((e) => e.toString().toLowerCase()).toSet();
    }
    return const {};
  } catch (_) {
    return const {};
  }
}

/// Current roles from the stored access token. Recomputes whenever the session
/// changes (login / refresh / role activation → re-login), so a freshly minted
/// token's roles are picked up.
final currentRolesProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  ref.watch(sessionControllerProvider);
  final token = await ref.watch(tokenStorageProvider).accessToken;
  return rolesFromJwt(token);
});

/// Whether the current session token carries the `Creator` role.
final isCreatorProvider = FutureProvider.autoDispose<bool>((ref) async {
  final roles = await ref.watch(currentRolesProvider.future);
  return roles.contains('creator');
});
