import 'package:flutter_riverpod/legacy.dart';

/// Holds the personal-information data collected for a creator application.
///
/// NOTE: the old multi-step wizard's "Social Media Profiles" step
/// (connected platforms, self-reported follower count, engagement rate,
/// content types, sample post URLs) has been removed — it only ever toggled
/// a local checkbox with no API call or OAuth, and none of that data (beyond
/// what's captured here) was ever meaningfully verified. Real social account
/// linking now happens via the OAuth-backed `SocialConnectScreen`. This class
/// is retained because [email] still backs the confirmation copy on the
/// legacy submitted/under-review/approved/rejected screens.
class CreatorFormData {
  final String fullName;
  final String email;
  final String phone;
  final String country;

  /// Display names of the selected content categories (for the review screen).
  final Set<String> categories;

  /// Backend category GUIDs (parallel to [categories]) — what the API needs.
  final Set<String> categoryIds;
  final String whyJoin;

  const CreatorFormData({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.country = '',
    this.categories = const {},
    this.categoryIds = const {},
    this.whyJoin = '',
  });

  CreatorFormData copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? country,
    Set<String>? categories,
    Set<String>? categoryIds,
    String? whyJoin,
  }) =>
      CreatorFormData(
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        country: country ?? this.country,
        categories: categories ?? this.categories,
        categoryIds: categoryIds ?? this.categoryIds,
        whyJoin: whyJoin ?? this.whyJoin,
      );
}

class CreatorFormNotifier extends StateNotifier<CreatorFormData> {
  CreatorFormNotifier() : super(const CreatorFormData());

  void saveStep1({
    required String fullName,
    required String email,
    required String phone,
    required String country,
    required Set<String> categories,
    required Set<String> categoryIds,
    required String whyJoin,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
      country: country,
      categories: Set.unmodifiable(categories),
      categoryIds: Set.unmodifiable(categoryIds),
      whyJoin: whyJoin,
    );
  }

  void reset() => state = const CreatorFormData();
}

final creatorFormProvider =
    StateNotifierProvider<CreatorFormNotifier, CreatorFormData>(
  (_) => CreatorFormNotifier(),
);
