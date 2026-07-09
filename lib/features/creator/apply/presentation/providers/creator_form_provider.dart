import 'package:flutter_riverpod/legacy.dart';

/// Holds all form data across the 3-step Creator Application flow.
/// Written to on each step's "Proceed"; read on Review + Submit.
class CreatorFormData {
  // Step 1 — Personal Information
  final String fullName;
  final String email;
  final String phone;
  final String country;

  /// Display names of the selected content categories (for the review screen).
  final Set<String> categories;

  /// Backend category GUIDs (parallel to [categories]) — what the API needs.
  final Set<String> categoryIds;
  final String whyJoin;

  // Step 2 — Social Media Profiles
  final Set<String> connectedPlatforms;
  final String totalFollowers;
  final String engagementRate;
  final Set<String> contentTypes;
  final List<String> sampleUrls;

  const CreatorFormData({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.country = '',
    this.categories = const {},
    this.categoryIds = const {},
    this.whyJoin = '',
    this.connectedPlatforms = const {},
    this.totalFollowers = '',
    this.engagementRate = '',
    this.contentTypes = const {},
    this.sampleUrls = const [],
  });

  CreatorFormData copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? country,
    Set<String>? categories,
    Set<String>? categoryIds,
    String? whyJoin,
    Set<String>? connectedPlatforms,
    String? totalFollowers,
    String? engagementRate,
    Set<String>? contentTypes,
    List<String>? sampleUrls,
  }) =>
      CreatorFormData(
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        country: country ?? this.country,
        categories: categories ?? this.categories,
        categoryIds: categoryIds ?? this.categoryIds,
        whyJoin: whyJoin ?? this.whyJoin,
        connectedPlatforms: connectedPlatforms ?? this.connectedPlatforms,
        totalFollowers: totalFollowers ?? this.totalFollowers,
        engagementRate: engagementRate ?? this.engagementRate,
        contentTypes: contentTypes ?? this.contentTypes,
        sampleUrls: sampleUrls ?? this.sampleUrls,
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

  void saveStep2({
    required Set<String> connectedPlatforms,
    required String totalFollowers,
    required String engagementRate,
    required Set<String> contentTypes,
    required List<String> sampleUrls,
  }) {
    state = state.copyWith(
      connectedPlatforms: Set.unmodifiable(connectedPlatforms),
      totalFollowers: totalFollowers,
      engagementRate: engagementRate,
      contentTypes: Set.unmodifiable(contentTypes),
      sampleUrls: List.unmodifiable(sampleUrls),
    );
  }

  void reset() => state = const CreatorFormData();
}

final creatorFormProvider =
    StateNotifierProvider<CreatorFormNotifier, CreatorFormData>(
  (_) => CreatorFormNotifier(),
);
