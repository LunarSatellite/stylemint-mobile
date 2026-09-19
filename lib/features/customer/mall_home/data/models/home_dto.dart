// @JsonKey on freezed factory parameters is supported by json_serializable.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/mall_json_readers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/shared/data/product_options_json.dart';
import 'package:stylemint_mobile_frontend/shared/data/product_reel_ref_json.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/product_reel_ref.dart';

part 'home_dto.freezed.dart';
part 'home_dto.g.dart';

/// `GET api/v1/public/home` (docs/mall/home-contract.md).
@freezed
abstract class HomeResponseDto with _$HomeResponseDto {
  const factory HomeResponseDto({
    DateTime? generatedUtc,
    @Default(false) bool personalized,
    HomeGreetingDto? greeting,
    @JsonKey(fromJson: readHomeSections)
    @Default(<HomeSectionDto>[])
    List<HomeSectionDto> sections,
  }) = _HomeResponseDto;

  const HomeResponseDto._();

  factory HomeResponseDto.fromJson(Map<String, dynamic> json) =>
      _$HomeResponseDtoFromJson(json);

  MallHome toDomain() => MallHome(
    generatedUtc: generatedUtc,
    personalized: personalized,
    greetingFirstName: optionalText(greeting?.firstName),
    sections: List.unmodifiable(sections.map((s) => s.toDomain()).nonNulls),
  );
}

/// Sections in server order. Kinds are matched case-insensitively; a
/// section that fails to parse is skipped like an unknown kind.
List<HomeSectionDto> readHomeSections(Object? raw) => readJsonList(raw, (json) {
  final kind = json['kind'];
  return HomeSectionDto.fromJson({
    ...json,
    'kind': kind is String ? kind.trim().toLowerCase() : kind,
  });
});

@freezed
abstract class HomeGreetingDto with _$HomeGreetingDto {
  const factory HomeGreetingDto({String? firstName}) = _HomeGreetingDto;

  factory HomeGreetingDto.fromJson(Map<String, dynamic> json) =>
      _$HomeGreetingDtoFromJson(json);
}

@freezed
abstract class HomeSeeAllDto with _$HomeSeeAllDto {
  const factory HomeSeeAllDto({
    @JsonKey(fromJson: readWireString) @Default('') String target,
    @JsonKey(fromJson: readStringMap)
    @Default(<String, String>{})
    Map<String, String> params,
  }) = _HomeSeeAllDto;

  const HomeSeeAllDto._();

  factory HomeSeeAllDto.fromJson(Map<String, dynamic> json) =>
      _$HomeSeeAllDtoFromJson(json);

  HomeSeeAll toDomain() => HomeSeeAll(
    target: homeSeeAllTargetFromWire(target),
    params: params,
  );
}

/// A section, discriminated by `kind`. Unknown kinds parse as
/// `HomeSectionDto.unknown` and are dropped by [toDomain].
@Freezed(unionKey: 'kind', fallbackUnion: 'unknown')
abstract class HomeSectionDto with _$HomeSectionDto {
  const factory HomeSectionDto.campaigns({
    @Default('') String id,
    String? eyebrow,
    String? title,
    String? subtitle,
    String? reason,
    HomeSeeAllDto? seeAll,
    @JsonKey(fromJson: readCampaignCards)
    @Default(<HomeCampaignCardDto>[])
    List<HomeCampaignCardDto> items,
  }) = HomeCampaignsSectionDto;

  const factory HomeSectionDto.products({
    @Default('') String id,
    String? eyebrow,
    String? title,
    String? subtitle,
    String? reason,
    HomeSeeAllDto? seeAll,
    @JsonKey(fromJson: readProductCards)
    @Default(<HomeProductCardDto>[])
    List<HomeProductCardDto> items,
  }) = HomeProductsSectionDto;

  const factory HomeSectionDto.reels({
    @Default('') String id,
    String? eyebrow,
    String? title,
    String? subtitle,
    String? reason,
    HomeSeeAllDto? seeAll,
    @JsonKey(fromJson: readReelCards)
    @Default(<HomeReelCardDto>[])
    List<HomeReelCardDto> items,
  }) = HomeReelsSectionDto;

  const factory HomeSectionDto.categories({
    @Default('') String id,
    String? eyebrow,
    String? title,
    String? subtitle,
    String? reason,
    HomeSeeAllDto? seeAll,
    @JsonKey(fromJson: readCategoryCards)
    @Default(<HomeCategoryCardDto>[])
    List<HomeCategoryCardDto> items,
  }) = HomeCategoriesSectionDto;

  const factory HomeSectionDto.brands({
    @Default('') String id,
    String? eyebrow,
    String? title,
    String? subtitle,
    String? reason,
    HomeSeeAllDto? seeAll,
    @JsonKey(fromJson: readBrandCards)
    @Default(<HomeBrandCardDto>[])
    List<HomeBrandCardDto> items,
  }) = HomeBrandsSectionDto;

  const factory HomeSectionDto.creators({
    @Default('') String id,
    String? eyebrow,
    String? title,
    String? subtitle,
    String? reason,
    HomeSeeAllDto? seeAll,
    @JsonKey(fromJson: readCreatorCards)
    @Default(<HomeCreatorCardDto>[])
    List<HomeCreatorCardDto> items,
  }) = HomeCreatorsSectionDto;

  const factory HomeSectionDto.collections({
    @Default('') String id,
    String? eyebrow,
    String? title,
    String? subtitle,
    String? reason,
    HomeSeeAllDto? seeAll,
    @JsonKey(fromJson: readCollectionCards)
    @Default(<HomeCollectionCardDto>[])
    List<HomeCollectionCardDto> items,
  }) = HomeCollectionsSectionDto;

  const factory HomeSectionDto.trust({
    @Default('') String id,
    String? eyebrow,
    String? title,
    String? subtitle,
    String? reason,
    HomeSeeAllDto? seeAll,
  }) = HomeTrustSectionDto;

  const factory HomeSectionDto.unknown({@Default('') String id}) =
      HomeUnknownSectionDto;

  const HomeSectionDto._();

  factory HomeSectionDto.fromJson(Map<String, dynamic> json) =>
      _$HomeSectionDtoFromJson(json);

  /// Null for unknown kinds and for rails left with no usable cards.
  HomeSection? toDomain() => map(
    campaigns: (s) => _nonEmpty(
      s.items.map((c) => c.toDomain()).nonNulls,
      (items) => HomeCampaignsSection(
        id: s.id,
        eyebrow: optionalText(s.eyebrow),
        title: optionalText(s.title),
        subtitle: optionalText(s.subtitle),
        reason: optionalText(s.reason),
        seeAll: s.seeAll?.toDomain(),
        items: items,
      ),
    ),
    products: (s) => _nonEmpty(
      s.items.map((c) => c.toDomain()).nonNulls,
      (items) => HomeProductsSection(
        id: s.id,
        eyebrow: optionalText(s.eyebrow),
        title: optionalText(s.title),
        subtitle: optionalText(s.subtitle),
        reason: optionalText(s.reason),
        seeAll: s.seeAll?.toDomain(),
        items: items,
      ),
    ),
    reels: (s) => _nonEmpty(
      s.items.map((c) => c.toDomain()).nonNulls,
      (items) => HomeReelsSection(
        id: s.id,
        eyebrow: optionalText(s.eyebrow),
        title: optionalText(s.title),
        subtitle: optionalText(s.subtitle),
        reason: optionalText(s.reason),
        seeAll: s.seeAll?.toDomain(),
        items: items,
      ),
    ),
    categories: (s) => _nonEmpty(
      s.items.map((c) => c.toDomain()).nonNulls,
      (items) => HomeCategoriesSection(
        id: s.id,
        eyebrow: optionalText(s.eyebrow),
        title: optionalText(s.title),
        subtitle: optionalText(s.subtitle),
        reason: optionalText(s.reason),
        seeAll: s.seeAll?.toDomain(),
        items: items,
      ),
    ),
    brands: (s) => _nonEmpty(
      s.items.map((c) => c.toDomain()).nonNulls,
      (items) => HomeBrandsSection(
        id: s.id,
        eyebrow: optionalText(s.eyebrow),
        title: optionalText(s.title),
        subtitle: optionalText(s.subtitle),
        reason: optionalText(s.reason),
        seeAll: s.seeAll?.toDomain(),
        items: items,
      ),
    ),
    creators: (s) => _nonEmpty(
      s.items.map((c) => c.toDomain()).nonNulls,
      (items) => HomeCreatorsSection(
        id: s.id,
        eyebrow: optionalText(s.eyebrow),
        title: optionalText(s.title),
        subtitle: optionalText(s.subtitle),
        reason: optionalText(s.reason),
        seeAll: s.seeAll?.toDomain(),
        items: items,
      ),
    ),
    collections: (s) => _nonEmpty(
      s.items.map((c) => c.toDomain()).nonNulls,
      (items) => HomeCollectionsSection(
        id: s.id,
        eyebrow: optionalText(s.eyebrow),
        title: optionalText(s.title),
        subtitle: optionalText(s.subtitle),
        reason: optionalText(s.reason),
        seeAll: s.seeAll?.toDomain(),
        items: items,
      ),
    ),
    trust: (s) => HomeTrustSection(
      id: s.id,
      eyebrow: optionalText(s.eyebrow),
      title: optionalText(s.title),
      subtitle: optionalText(s.subtitle),
      reason: optionalText(s.reason),
      seeAll: s.seeAll?.toDomain(),
    ),
    unknown: (_) => null,
  );

  static HomeSection? _nonEmpty<T>(
    Iterable<T> cards,
    HomeSection Function(List<T> items) build,
  ) {
    final items = List<T>.unmodifiable(cards);
    return items.isEmpty ? null : build(items);
  }
}

List<HomeCampaignCardDto> readCampaignCards(Object? raw) =>
    readJsonList(raw, HomeCampaignCardDto.fromJson);
List<HomeProductCardDto> readProductCards(Object? raw) =>
    readJsonList(raw, HomeProductCardDto.fromJson);
List<HomeReelCardDto> readReelCards(Object? raw) =>
    readJsonList(raw, HomeReelCardDto.fromJson);
List<HomeCategoryCardDto> readCategoryCards(Object? raw) =>
    readJsonList(raw, HomeCategoryCardDto.fromJson);
List<HomeBrandCardDto> readBrandCards(Object? raw) =>
    readJsonList(raw, HomeBrandCardDto.fromJson);
List<HomeCreatorCardDto> readCreatorCards(Object? raw) =>
    readJsonList(raw, HomeCreatorCardDto.fromJson);
List<HomeCollectionCardDto> readCollectionCards(Object? raw) =>
    readJsonList(raw, HomeCollectionCardDto.fromJson);
List<HomeCampaignCtaDto> readCampaignCtas(Object? raw) =>
    readJsonList(raw, HomeCampaignCtaDto.fromJson);

// ── Cards ──────────────────────────────────────────────────────────────────

@freezed
abstract class HomeMoneyDto with _$HomeMoneyDto {
  const factory HomeMoneyDto({
    @Default(0) double amount,
    @Default('NPR') String currency,
  }) = _HomeMoneyDto;

  const HomeMoneyDto._();

  factory HomeMoneyDto.fromJson(Map<String, dynamic> json) =>
      _$HomeMoneyDtoFromJson(json);

  Money toDomain() => Money(amount: amount, currency: currency);
}

@freezed
abstract class HomeCampaignCardDto with _$HomeCampaignCardDto {
  const factory HomeCampaignCardDto({
    @Default('') String id,
    @Default('') String slug,
    String? eyebrow,
    @Default('') String title,
    String? subtitle,
    String? heroImageUrl,
    String? heroReelId,
    @JsonKey(fromJson: readCampaignCtas)
    @Default(<HomeCampaignCtaDto>[])
    List<HomeCampaignCtaDto> ctas,
  }) = _HomeCampaignCardDto;

  const HomeCampaignCardDto._();

  factory HomeCampaignCardDto.fromJson(Map<String, dynamic> json) =>
      _$HomeCampaignCardDtoFromJson(json);

  HomeCampaign? toDomain() {
    final name = title.trim();
    if (id.isEmpty || name.isEmpty) return null;
    return HomeCampaign(
      id: id,
      slug: slug,
      title: name,
      eyebrow: optionalText(eyebrow),
      subtitle: optionalText(subtitle),
      heroImageUrl: mediaUrlOrNull(heroImageUrl),
      heroReelId: optionalText(heroReelId),
      ctas: List.unmodifiable(
        ctas.map((c) => c.toDomain()).where((c) => c.label.isNotEmpty),
      ),
    );
  }
}

@freezed
abstract class HomeCampaignCtaDto with _$HomeCampaignCtaDto {
  const factory HomeCampaignCtaDto({
    @Default('') String label,
    @JsonKey(fromJson: readWireEnum) @Default('') String targetKind,
    @JsonKey(fromJson: readWireString) @Default('') String targetValue,
  }) = _HomeCampaignCtaDto;

  const HomeCampaignCtaDto._();

  factory HomeCampaignCtaDto.fromJson(Map<String, dynamic> json) =>
      _$HomeCampaignCtaDtoFromJson(json);

  HomeCampaignCta toDomain() => HomeCampaignCta(
    label: label.trim(),
    targetValue: targetValue,
    targetKind: switch (targetKind.toLowerCase()) {
      '1' || 'collection' => HomeCtaTargetKind.collection,
      '2' || 'reels' => HomeCtaTargetKind.reels,
      '3' || 'creators' => HomeCtaTargetKind.creators,
      '4' || 'category' => HomeCtaTargetKind.category,
      '5' || 'brand' => HomeCtaTargetKind.brand,
      '6' || 'product' => HomeCtaTargetKind.product,
      '7' || 'url' => HomeCtaTargetKind.url,
      _ => HomeCtaTargetKind.unknown,
    },
  );
}

@freezed
abstract class HomeProductCardDto with _$HomeProductCardDto {
  const factory HomeProductCardDto({
    @Default('') String id,
    @Default('') String name,
    String? brandName,
    String? vendorAccountId,
    String? imageUrl,
    HomeMoneyDto? price,
    HomeMoneyDto? compareAtPrice,
    double? rating,
    @Default(0) int reviewCount,
    @Default(false) bool isNew,
    @Default(false) bool isLowStock,
    @Default(false) bool isOnSale,
    DateTime? saleEndsUtc,
    // Nullable and not on the server yet; read tolerantly so a product still
    // renders (as its type tile) whatever shape arrives.
    @JsonKey(fromJson: readProductReelRef, includeToJson: false)
    ProductReelRef? reel,
    // Ships with `defaultVariantId`, but not on the deployed server yet:
    // absent or unparseable reads as true, so the card sends the buyer to the
    // product page rather than guessing a variant.
    @JsonKey(fromJson: readRequiresOptionSelection, includeToJson: false)
    @Default(true)
    bool requiresOptionSelection,
    @JsonKey(fromJson: readDefaultVariantId, includeToJson: false)
    String? defaultVariantId,
    @JsonKey(fromJson: readIsInStock, includeToJson: false)
    @Default(false)
    bool isInStock,
  }) = _HomeProductCardDto;

  const HomeProductCardDto._();

  factory HomeProductCardDto.fromJson(Map<String, dynamic> json) =>
      _$HomeProductCardDtoFromJson(json);

  /// Null without an id, a name or a price.
  HomeProduct? toDomain() {
    final current = price;
    if (id.isEmpty || name.trim().isEmpty || current == null) return null;
    return HomeProduct(
      id: id,
      name: name.trim(),
      price: current.toDomain(),
      brandName: optionalText(brandName),
      vendorAccountId: optionalText(vendorAccountId),
      imageUrl: mediaUrlOrNull(imageUrl),
      compareAtPrice: compareAtPrice?.toDomain(),
      rating: rating,
      reviewCount: reviewCount,
      isNew: isNew,
      isLowStock: isLowStock,
      isOnSale: isOnSale,
      saleEndsUtc: saleEndsUtc,
      reel: reel,
      requiresOptionSelection: requiresOptionSelection,
      defaultVariantId: defaultVariantId,
      isInStock: isInStock,
    );
  }
}

@freezed
abstract class HomeReelCardDto with _$HomeReelCardDto {
  const factory HomeReelCardDto({
    @Default('') String id,
    String? posterUrl,
    @Default('') String creatorAccountId,
    @Default('') String creatorName,
    String? creatorAvatarUrl,
    String? hook,
    @Default(0) int taggedProductCount,
    @Default(false) bool isAiGenerated,
    @Default(0) int likeCount,
    String? sourcePlatform,
  }) = _HomeReelCardDto;

  const HomeReelCardDto._();

  factory HomeReelCardDto.fromJson(Map<String, dynamic> json) =>
      _$HomeReelCardDtoFromJson(json);

  HomeReel? toDomain() {
    if (id.isEmpty) return null;
    return HomeReel(
      id: id,
      creatorName: creatorName.trim(),
      creatorAccountId: creatorAccountId,
      posterUrl: mediaUrlOrNull(posterUrl),
      creatorAvatarUrl: mediaUrlOrNull(creatorAvatarUrl),
      hook: optionalText(hook),
      taggedProductCount: taggedProductCount,
      isAiGenerated: isAiGenerated,
      likeCount: likeCount,
      sourcePlatform: optionalText(sourcePlatform),
    );
  }
}

@freezed
abstract class HomeCategoryCardDto with _$HomeCategoryCardDto {
  const factory HomeCategoryCardDto({
    @Default('') String id,
    @Default('') String slug,
    @Default('') String name,
    String? imageUrl,
  }) = _HomeCategoryCardDto;

  const HomeCategoryCardDto._();

  factory HomeCategoryCardDto.fromJson(Map<String, dynamic> json) =>
      _$HomeCategoryCardDtoFromJson(json);

  HomeCategory? toDomain() {
    if ((id.isEmpty && slug.isEmpty) || name.trim().isEmpty) return null;
    return HomeCategory(
      id: id,
      slug: slug,
      name: name.trim(),
      imageUrl: mediaUrlOrNull(imageUrl),
    );
  }
}

@freezed
abstract class HomeBrandCardDto with _$HomeBrandCardDto {
  const factory HomeBrandCardDto({
    @Default('') String vendorAccountId,
    @Default('') String name,
    String? logoUrl,
    String? coverImageUrl,
    String? tagline,
    @Default(false) bool isVerified,
  }) = _HomeBrandCardDto;

  const HomeBrandCardDto._();

  factory HomeBrandCardDto.fromJson(Map<String, dynamic> json) =>
      _$HomeBrandCardDtoFromJson(json);

  HomeBrand? toDomain() {
    if (vendorAccountId.isEmpty || name.trim().isEmpty) return null;
    return HomeBrand(
      vendorAccountId: vendorAccountId,
      name: name.trim(),
      logoUrl: mediaUrlOrNull(logoUrl),
      coverImageUrl: mediaUrlOrNull(coverImageUrl),
      tagline: optionalText(tagline),
      isVerified: isVerified,
    );
  }
}

@freezed
abstract class HomeCreatorCardDto with _$HomeCreatorCardDto {
  const factory HomeCreatorCardDto({
    @Default('') String accountId,
    @Default('') String displayName,
    String? handle,
    String? avatarUrl,
    String? coverImageUrl,
    @Default(false) bool isVerified,
    @JsonKey(fromJson: readStringList)
    @Default(<String>[])
    List<String> styleTags,
    int? followerCount,
  }) = _HomeCreatorCardDto;

  const HomeCreatorCardDto._();

  factory HomeCreatorCardDto.fromJson(Map<String, dynamic> json) =>
      _$HomeCreatorCardDtoFromJson(json);

  HomeCreator? toDomain() {
    if (accountId.isEmpty || displayName.trim().isEmpty) return null;
    return HomeCreator(
      accountId: accountId,
      displayName: displayName.trim(),
      handle: optionalText(handle),
      avatarUrl: mediaUrlOrNull(avatarUrl),
      coverImageUrl: mediaUrlOrNull(coverImageUrl),
      isVerified: isVerified,
      styleTags: styleTags,
      followerCount: followerCount,
    );
  }
}

@freezed
abstract class HomeCollectionCardDto with _$HomeCollectionCardDto {
  const factory HomeCollectionCardDto({
    @Default('') String slug,
    @JsonKey(fromJson: readWireEnum) @Default('') String kind,
    @Default('') String title,
    String? subtitle,
    String? coverImageUrl,
    int? itemCount,
    @JsonKey(fromJson: readStringList)
    @Default(<String>[])
    List<String> previewImageUrls,
  }) = _HomeCollectionCardDto;

  const HomeCollectionCardDto._();

  factory HomeCollectionCardDto.fromJson(Map<String, dynamic> json) =>
      _$HomeCollectionCardDtoFromJson(json);

  HomeCollection? toDomain() {
    if (slug.isEmpty || title.trim().isEmpty) return null;
    return HomeCollection(
      slug: slug,
      kind: collectionKindFromWire(kind),
      title: title.trim(),
      subtitle: optionalText(subtitle),
      coverImageUrl: mediaUrlOrNull(coverImageUrl),
      itemCount: itemCount,
      previewImageUrls: List.unmodifiable(
        previewImageUrls.map(mediaUrlOrNull).nonNulls,
      ),
    );
  }
}
