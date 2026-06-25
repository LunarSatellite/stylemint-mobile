import 'package:flutter_riverpod/legacy.dart';

// ── Avatar ────────────────────────────────────────────────────────────────────

class AvatarImageNotifier extends StateNotifier<String?> {
  AvatarImageNotifier() : super(null);

  void setPath(String path) => state = path;
}

/// Local file path of the avatar the user just picked/captured.
final avatarImagePathProvider =
    StateNotifierProvider<AvatarImageNotifier, String?>(
  (ref) => AvatarImageNotifier(),
);

// ── Editable profile data ─────────────────────────────────────────────────────

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
          displayName: 'Danny Perierra',
          bio: 'Kathmandu-based content creator known for blending '
              'high-energy reels with streetwear aesthetics & movement-based storytelling.',
          tags: ['50+ Videos with 100K views', 'Marathon Runner'],
          niches: {'Fashion', 'Accessories', 'Books'},
        ));

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
