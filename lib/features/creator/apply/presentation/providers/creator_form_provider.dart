import 'package:flutter/material.dart' show Color, IconData, Icons;
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/creator_application.dart';

// ---------------------------------------------------------------------------
// Static option lists (kept here so all three wizard steps read the same data)
// ---------------------------------------------------------------------------

/// The four social platforms the backend accepts via `SocialIdentityProvider`
/// (enum 1..4). Mirrors the four icon rows in step 2.
class CreatorPlatformOption {
  const CreatorPlatformOption({
    required this.id,
    required this.name,
    required this.icon,
    required this.assetPath,
    required this.color,
  });
  final String id; // 'instagram' | 'tiktok' | 'youtube' | 'facebook'
  final String name;

  /// Fallback Material icon (used only if the SVG asset fails to load).
  final IconData icon;

  /// Brand SVG (assets/icons/...) for the actual logo render.
  final String assetPath;
  final Color color;
}

const List<CreatorPlatformOption> kCreatorPlatforms = [
  CreatorPlatformOption(
    id: 'instagram',
    name: 'Instagram',
    icon: Icons.camera_alt_outlined,
    assetPath: 'assets/icons/instagram.svg',
    color: Color(0xFFE1306C),
  ),
  CreatorPlatformOption(
    id: 'tiktok',
    name: 'TikTok',
    icon: Icons.music_note_outlined,
    assetPath: 'assets/icons/tiktok.svg',
    color: Color(0xFFFE2C55),
  ),
  CreatorPlatformOption(
    id: 'youtube',
    name: 'YouTube',
    icon: Icons.play_circle_outline,
    assetPath: 'assets/icons/youtube.svg',
    color: Color(0xFFFF0000),
  ),
  CreatorPlatformOption(
    id: 'facebook',
    name: 'Facebook',
    icon: Icons.thumb_up_outlined,
    assetPath: 'assets/icons/facebook.svg',
    color: Color(0xFF1877F2),
  ),
];

/// Self-reported follower-count bands, aligned with the backend
/// `AudienceSizeBand` enum (1..5 ascending). The dropdown mirrors the Figma
/// "Audience size" picker chips.
class AudienceBandOption {
  const AudienceBandOption(this.value, this.label);
  final int value;
  final String label;
}

const List<AudienceBandOption> kAudienceBands = [
  AudienceBandOption(1, '< 1K'),
  AudienceBandOption(2, '1K - 10K'),
  AudienceBandOption(3, '10K - 50K'),
  AudienceBandOption(4, '50K - 500K'),
  AudienceBandOption(5, '500K+'),
];

/// Engagement-rate buckets. NOT yet a backend field; displayed and stashed
/// locally only.
class EngagementRateOption {
  const EngagementRateOption(this.value, this.label);
  final String value;
  final String label;
}

const List<EngagementRateOption> kEngagementRates = [
  EngagementRateOption('lt_1', 'Less than 1%'),
  EngagementRateOption('1_3', '1% - 3%'),
  EngagementRateOption('3_6', '3% - 6%'),
  EngagementRateOption('6_10', '6% - 10%'),
  EngagementRateOption('gt_10', 'More than 10%'),
];

/// Content-kind chips. NOT yet a backend field; collected and shown locally.
class ContentKindOption {
  const ContentKindOption(this.id, this.label);
  final String id;
  final String label;
}

const List<ContentKindOption> kContentKinds = [
  ContentKindOption('short_video', 'Short-form Video (Reels/Shorts)'),
  ContentKindOption('stories', 'Stories'),
  ContentKindOption('long_video', 'Long-form Videos'),
  ContentKindOption('static_post', 'Static Posts'),
];

// ---------------------------------------------------------------------------
// Form data + notifier
// ---------------------------------------------------------------------------

/// Holds all data collected by the 3-step creator application wizard.
///
/// Step 1 carries the account-level personal info + content categories.
/// Step 2 carries the social media profiles + audience metrics + sample
/// content. Only the BE-compatible subset (bio, audienceBand,
/// contentCategoryIds, socials[]) actually leaves the device - engagement
/// rate, content kinds and sample URLs are kept locally for now and surface
/// in the review screen with a "saved on this device" hint until the backend
/// learns these fields.
class CreatorFormData {
  // --- Step 1: personal info -----------------------------------------------
  final String fullName;
  final String email;
  final String phone;
  final String country; // display name, e.g. "Nepal"
  final String countryCode; // ISO-2, e.g. "NP" - reserved for BE later

  /// Display names of the selected content categories (for the review screen).
  final Set<String> categories;

  /// Backend category GUIDs (parallel to [categories]) - what the API needs.
  final Set<String> categoryIds;
  final String whyJoin;

  // --- Step 2: social profiles + metrics -----------------------------------
  /// One row per declared social platform (Instagram/TikTok/YouTube/Facebook).
  /// [Platform.handle] is the @-handle, [Platform.followerCount] is the
  /// self-reported count sent as `followerCountSelfReported`.
  final List<Platform> platforms;

  /// Total followers/subscribers the creator declares on the apply form.
  /// Editable on step 2 (BE doesn't store this; we keep it locally only
  /// until the wizard learns a payload field for it).
  final String totalFollowers;

  /// `AudienceSizeBand` enum (1..5). Maps to the dropdown selection in step 2.
  final int audienceBand;

  /// Local-only engagement-rate bucket id (see [kEngagementRates]).
  final String engagementRate;

  /// Local-only selected content-kind ids (see [kContentKinds]).
  final Set<String> contentKinds;

  /// Local-only sample-content URLs the creator wants to showcase.
  final List<String> sampleUrls;

  /// Free-form `otherCategoryDescription` text used when one of the
  /// selected categories has `requiresOtherDescription == true`. Mirrors
  /// the BE's `OtherCategoryDescription` field; pre-filled on reapply.
  final String otherCategoryDescription;

  const CreatorFormData({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.country = '',
    this.countryCode = '',
    this.categories = const {},
    this.categoryIds = const {},
    this.whyJoin = '',
    this.platforms = const [],
    this.totalFollowers = '',
    this.audienceBand = 1,
    this.engagementRate = '',
    this.contentKinds = const {},
    this.sampleUrls = const [],
    this.otherCategoryDescription = '',
  });

  CreatorFormData copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? country,
    String? countryCode,
    Set<String>? categories,
    Set<String>? categoryIds,
    String? whyJoin,
    List<Platform>? platforms,
    String? totalFollowers,
    int? audienceBand,
    String? engagementRate,
    Set<String>? contentKinds,
    List<String>? sampleUrls,
    String? otherCategoryDescription,
  }) => CreatorFormData(
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    country: country ?? this.country,
    countryCode: countryCode ?? this.countryCode,
    categories: categories ?? this.categories,
    categoryIds: categoryIds ?? this.categoryIds,
    whyJoin: whyJoin ?? this.whyJoin,
    platforms: platforms ?? this.platforms,
    totalFollowers: totalFollowers ?? this.totalFollowers,
    audienceBand: audienceBand ?? this.audienceBand,
    engagementRate: engagementRate ?? this.engagementRate,
    contentKinds: contentKinds ?? this.contentKinds,
    sampleUrls: sampleUrls ?? this.sampleUrls,
    otherCategoryDescription:
        otherCategoryDescription ?? this.otherCategoryDescription,
  );
}

class CreatorFormNotifier extends StateNotifier<CreatorFormData> {
  CreatorFormNotifier() : super(const CreatorFormData());

  void saveStep1({
    required String fullName,
    required String email,
    required String phone,
    required String country,
    required String countryCode,
    required Set<String> categories,
    required Set<String> categoryIds,
    required String whyJoin,
    String otherCategoryDescription = '',
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
      country: country,
      countryCode: countryCode,
      categories: Set.unmodifiable(categories),
      categoryIds: Set.unmodifiable(categoryIds),
      whyJoin: whyJoin,
      otherCategoryDescription: otherCategoryDescription,
    );
  }

  void saveStep2({
    required List<Platform> platforms,
    required String totalFollowers,
    required int audienceBand,
    required String engagementRate,
    required Set<String> contentKinds,
    required List<String> sampleUrls,
  }) {
    state = state.copyWith(
      platforms: List.unmodifiable(platforms),
      totalFollowers: totalFollowers,
      audienceBand: audienceBand,
      engagementRate: engagementRate,
      contentKinds: Set.unmodifiable(contentKinds),
      sampleUrls: List.unmodifiable(sampleUrls),
    );
  }

  /// Pre-fill the wizard from a fetched [CreatorApplication]. Used by the
  /// reapply flow so the user lands on step 1 with their previous bio,
  /// categories, socials and audience band already filled in. Step-1
  /// personal fields the BE doesn't store (fullName/email/phone/country)
  /// remain empty — the user must re-enter those.
  void loadFromApplication(CreatorApplication app) {
    state = state.copyWith(
      whyJoin: app.bio,
      audienceBand: app.audienceBand,
      categoryIds: Set.unmodifiable(app.categoryIds),
      platforms: List.unmodifiable(app.socials),
      otherCategoryDescription: app.otherCategoryDescription ?? '',
    );
  }

  void reset() => state = const CreatorFormData();
}

final creatorFormProvider =
    StateNotifierProvider<CreatorFormNotifier, CreatorFormData>(
      (_) => CreatorFormNotifier(),
    );

/// Whether the wizard's primary action button should be enabled. Each step
/// bumps this to its current canProceed (or canSubmit on the review
/// step) on every internal change, so the wizard shell can watch and
/// re-enable the Proceed/Submit button without re-walking the step tree.
final stepCanProceedProvider = StateProvider<bool>((_) => false);