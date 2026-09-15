import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';

/// The signed-in user's profile photo URL, for the bottom bar's Profile tab.
///
/// Read from the same [profileNotifierProvider] summary the Profile screen
/// renders, so a new photo shows in the bar as soon as that profile reloads.
/// Null for guests, while the profile loads, and when the account has no
/// photo — the bar then draws the outline person icon.
final currentUserAvatarUrlProvider = Provider<String?>((ref) {
  final signedIn = ref.watch(
    sessionControllerProvider.select((session) => session.isAuthenticated),
  );
  if (!signedIn) return null;
  final url = ref.watch(
    profileNotifierProvider.select(
      (state) => state.maybeWhen(
        loadSuccess: (summary) => summary.avatarUrl,
        orElse: () => null,
      ),
    ),
  );
  return url == null || url.isEmpty ? null : url;
});
