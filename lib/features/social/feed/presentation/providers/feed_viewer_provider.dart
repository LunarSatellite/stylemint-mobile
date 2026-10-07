import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';

/// Who is looking at the feed — the name and photo the composer row and the
/// comment input draw next to "What's new?" and "Add a comment".
class FeedViewer {
  const FeedViewer({required this.displayName, this.avatarUrl});

  final String displayName;
  final String? avatarUrl;

  /// "Sam" from "Sam Rai"; empty when the profile has no name yet.
  String get firstName {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

/// Read from the same profile summary the Profile screen renders (as
/// `currentUserAvatarUrlProvider` does). Null for guests and while the profile
/// loads; the composer then falls back to a plain "What's new?".
final feedViewerProvider = Provider<FeedViewer?>((ref) {
  final signedIn = ref.watch(
    sessionControllerProvider.select((session) => session.isAuthenticated),
  );
  if (!signedIn) return null;
  return ref.watch(
    profileNotifierProvider.select(
      (state) => state.maybeWhen(
        loadSuccess: (summary) => FeedViewer(
          displayName: summary.displayName,
          avatarUrl: summary.avatarUrl.isEmpty ? null : summary.avatarUrl,
        ),
        orElse: () => null,
      ),
    ),
  );
});
