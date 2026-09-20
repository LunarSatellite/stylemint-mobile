import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_terms.dart';

/// Partnership detail — backend `PartnershipDto` (`GET /v1/partnerships/{id}`).
class PartnershipDetailDto {
  const PartnershipDetailDto({
    required this.id,
    required this.vendorProfileId,
    required this.stateLabel,
    required this.commissionMinPercent,
    required this.commissionMaxPercent,
    required this.vendorRating,
    required this.requestMessage,
    required this.vendorName,
    this.vendorLogoUrl,
    this.vendorCategory,
    this.description,
  });

  final String id;
  final String vendorProfileId;
  final String stateLabel;

  /// Percent (`15.0` is fifteen percent), already converted from the
  /// fraction the backend sends. `PartnershipDto.commissionMinPercent`
  /// is `CommissionRange.MinPercent`, which — despite its name — is
  /// stored as a fraction in `0..1` (`0.15` == 15 %); `CommissionRange`
  /// says so and `RequestPartnershipVmValidator` pins it to
  /// `CommissionRange.Floor..Ceiling` == `0..1`. Reading it here without
  /// the ×100 made `toStringAsFixed(0)` on `0.15` render **"0%
  /// Commission"** on the brand detail header, and handed
  /// `PartnershipApplyArgs` a fraction where every other caller
  /// (`BrandListItemDto` → `BrandInfoData`) passes a percent — so the
  /// apply slider was labelled "0%-0%" and its `_range.start / 100`
  /// submitted `0.0015`, asking for 0.15 % instead of 15 %.
  final double commissionMinPercent;

  /// Percent. See [commissionMinPercent].
  final double commissionMaxPercent;
  final double? vendorRating;
  final String? requestMessage;
  final String vendorName;
  final String? vendorLogoUrl;
  final String? vendorCategory;
  final String? description;

  // `avgOrderValue` and `successRatePercent` were parsed here and drawn by
  // `brand_detail_screen.dart` as "Avg Order Value" and "Success Rate with
  // Creators: N%". The backend's `PartnershipDto`
  // (`Entity/Partnership/Dtos/PartnershipDto.cs`) has no such properties —
  // it carries ids, state, the commission range, the brief snapshot, the
  // joined vendor/creator display fields and `VendorRating`, and nothing
  // else — so `GET /v1/partnerships/{id}` never sent either one and both
  // read null on every response. The UI's null guards meant nothing ever
  // drew, which is why this sat unnoticed.
  //
  // They are deleted rather than kept against a future endpoint.
  // "Success Rate with Creators" is precisely the figure that rendered
  // "0%" for every brand on the sibling screen, and it got there because a
  // field was parsed before anything measured it. A field with no source
  // is a rendering waiting to happen.
  //
  // `vendorRating` above is different and stays: it is a real property of
  // the backend DTO, joined at read time by `CatalogVendorRatingProvider`
  // from Catalog's weighted product-review rollup for that vendor
  // (registered over `NoopVendorRatingProvider` in `StyleMintPlatform.cs`),
  // and three screens read it —
  // `brand_detail_screen.dart`, `partnership_apply_screen.dart` and
  // `partnership_requests_screen.dart`. It is null until the vendor has
  // rated products, and every reader hides the chip when it is null.

  static const _states = {
    1: 'Invited',
    2: 'Declined',
    3: 'Active',
    4: 'Paused',
    5: 'Ended',
  };

  factory PartnershipDetailDto.fromJson(Map<String, dynamic> json) {
    return PartnershipDetailDto(
      id: (json['id'] as String?) ?? '',
      vendorProfileId: (json['vendorProfileId'] as String?) ?? '',
      stateLabel: _states[(json['state'] as num?)?.toInt() ?? 0] ?? 'Unknown',
      commissionMinPercent:
          ((json['commissionMinPercent'] as num?)?.toDouble() ?? 0) * 100,
      commissionMaxPercent:
          ((json['commissionMaxPercent'] as num?)?.toDouble() ?? 0) * 100,
      vendorRating: (json['vendorRating'] as num?)?.toDouble(),
      requestMessage: json['requestMessage'] as String?,
      vendorName: (json['vendorName'] as String?) ?? '',
      vendorLogoUrl: json['vendorLogoUrl'] as String?,
      vendorCategory: json['vendorCategory'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// A titled section of the partnership terms with bullet points.
class TermsSection {
  const TermsSection({required this.heading, required this.bullets});
  final String heading;
  final List<String> bullets;
}

/// Active terms — backend `PartnershipTermsVersionDto` with nested `TermsBody`.
class PartnershipTermsDto {
  const PartnershipTermsDto({
    required this.versionNumber,
    required this.whoCanJoin,
    required this.reelContentRules,
  });

  final int versionNumber;
  final TermsSection whoCanJoin;
  final TermsSection reelContentRules;

  factory PartnershipTermsDto.fromJson(Map<String, dynamic> json) {
    final body = (json['body'] as Map<String, dynamic>?) ?? const {};
    return PartnershipTermsDto(
      versionNumber: (json['versionNumber'] as num?)?.toInt() ?? 1,
      whoCanJoin: _section(
        body['whoCanJoin'] as Map<String, dynamic>?,
        'Who Can Join',
        stringBullets: true,
      ),
      reelContentRules: _section(
        body['reelContentRules'] as Map<String, dynamic>?,
        'Reel Content Rules',
        stringBullets: false,
      ),
    );
  }

  static TermsSection _section(
    Map<String, dynamic>? json,
    String fallbackHeading, {
    required bool stringBullets,
  }) {
    if (json == null) {
      return TermsSection(heading: fallbackHeading, bullets: const []);
    }
    final raw = (json['bullets'] as List<dynamic>? ?? const []);
    final bullets = <String>[];
    for (final b in raw) {
      if (b is String) {
        bullets.add(b);
      } else if (b is Map<String, dynamic>) {
        final t = (b['text'] ?? b['body'] ?? b['content']) as String?;
        if (t != null && t.isNotEmpty) bullets.add(t);
      }
    }
    return TermsSection(
      heading: (json['heading'] as String?) ?? fallbackHeading,
      bullets: bullets,
    );
  }
}

/// Money value representation from the backend API.
class MoneyDto {
  const MoneyDto({required this.amount, required this.currency});

  final double amount;
  final String currency;

  factory MoneyDto.fromJson(Map<String, dynamic> json) => MoneyDto(
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        currency: (json['currency'] as String?) ?? 'NPR',
      );

  String get label {
    final symbol = currency.toUpperCase() == 'NPR' ? 'Rs' : currency;
    return '$symbol ${amount.toStringAsFixed(0)}';
  }
}

/// Potential earnings projection — `GET /v1/partnerships/{id}/potential-earnings`.
class PotentialEarningsDto {
  const PotentialEarningsDto({
    required this.partnershipId,
    required this.productVariantId,
    required this.commissionRate,
    required this.unitPrice,
    required this.perSale,
    required this.perFiftySales,
    required this.salesAssumed,
  });

  final String partnershipId;
  final String productVariantId;
  final double commissionRate;
  final MoneyDto unitPrice;
  final MoneyDto perSale;
  final MoneyDto perFiftySales;
  final int salesAssumed;

  factory PotentialEarningsDto.fromJson(Map<String, dynamic> json) {
    MoneyDto money(String key) {
      final raw = json[key];
      if (raw is Map<String, dynamic>) return MoneyDto.fromJson(raw);
      return const MoneyDto(amount: 0, currency: 'NPR');
    }

    return PotentialEarningsDto(
      partnershipId: (json['partnershipId'] as String?) ?? '',
      productVariantId: (json['productVariantId'] as String?) ?? '',
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0,
      unitPrice: money('unitPrice'),
      perSale: money('perSale'),
      perFiftySales: money('perFiftySales'),
      salesAssumed: (json['salesAssumed'] as num?)?.toInt() ?? 50,
    );
  }
}

/// A recipe attached to a partnership brief — `GET /v1/creator/partnerships/{id}/recipes`.
class RecipeAttachmentInfoDto {
  const RecipeAttachmentInfoDto({
    required this.recipeId,
    required this.recipeVersion,
    this.title,
    this.thumbnailUrl,
    required this.isHidden,
  });

  final String recipeId;
  final int recipeVersion;
  final String? title;
  final String? thumbnailUrl;
  final bool isHidden;

  factory RecipeAttachmentInfoDto.fromJson(Map<String, dynamic> json) =>
      RecipeAttachmentInfoDto(
        recipeId: (json['recipeId'] as String?) ?? '',
        recipeVersion: (json['recipeVersion'] as num?)?.toInt() ?? 1,
        title: json['title'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        isHidden: (json['isHidden'] as bool?) ?? false,
      );
}

// `SampleCampaignDto` stood here — `id`, `title`, `imageUrl`, `reelCount`,
// `creatorCollabCount` — documented as coming from
// `GET /v1/partnerships/{id}/campaigns`. There is no such route in
// lead360; see the note at the top of `brand_detail_screen.dart` for the
// full list of what `CreatorPartnershipsController` actually serves. The
// doc comment was the only thing that made the tab look sourced, and the
// tab it fed is gone.

/// Brand catalog detail — backend `VendorProfileDto`
/// (`GET /v1/brands/{vendorAccountId}`). Real approved-vendor profile
/// surfaced when a creator taps into a brand card from the catalog.
/// Commission fields arrive as decimals in the [0, 1] fractional range
/// (e.g. `0.15` = 15%); the mobile multiplies by 100 so downstream widgets
/// can render whole-percent values.
class BrandDetailDto {
  const BrandDetailDto({
    required this.id,
    required this.accountId,
    required this.businessName,
    required this.businessType,
    required this.commissionRangeMinPercent,
    required this.commissionRangeMaxPercent,
    this.description,
    this.logoUrl,
    this.websiteUrl,
  });

  final String id;
  final String accountId;
  final String businessName;

  /// Numeric value of `BusinessType` (1=Individual, 2=SoleProprietorship,
  /// 3=LimitedLiability, 4=Corporation, 5=Partnership, 6=NonProfit).
  /// Mapped to a friendly label by `BrandInfoScreen` since the legal form
  /// is the only taxonomy the vendor profile carries today; product
  /// categories live on individual products and are not aggregated here.
  final int businessType;

  final String? description;
  final String? logoUrl;
  final String? websiteUrl;
  final double commissionRangeMinPercent;
  final double commissionRangeMaxPercent;

  static const _businessTypeLabels = <int, String>{
    1: 'Individual',
    2: 'Sole Proprietorship',
    3: 'Limited Liability',
    4: 'Corporation',
    5: 'Partnership',
    6: 'Non-Profit',
  };

  String get businessTypeLabel =>
      _businessTypeLabels[businessType] ?? '';

  String get commissionRangeLabel =>
      '${commissionRangeMinPercent.toStringAsFixed(0)}-'
      '${commissionRangeMaxPercent.toStringAsFixed(0)}%';

  factory BrandDetailDto.fromJson(Map<String, dynamic> json) {
    return BrandDetailDto(
      id: (json['id'] as String?) ?? '',
      accountId: (json['accountId'] as String?) ?? '',
      businessName: (json['businessName'] as String?) ?? '',
      businessType: (json['businessType'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      commissionRangeMinPercent:
          ((json['commissionRangeMin'] as num?)?.toDouble() ?? 0) * 100,
      commissionRangeMaxPercent:
          ((json['commissionRangeMax'] as num?)?.toDouble() ?? 0) * 100,
    );
  }
}

// `BrandTrustDto` stood here: a 0–100 `score`, a five-band `tier`,
// `totalCampaignValue`, `verifiedByCount` and five component sub-scores,
// read from `GET /v1/creator/brands/{vendorId}/trust`. All of it is gone,
// along with the endpoint. See
// `data/models/brand_partnership_record_dto.dart` for what replaced it and
// why. Two things are worth keeping in mind here rather than only there:
//
//  * The server built every brand's score from five hardcoded constants,
//    and the recalculation that used them had no caller — so the row every
//    brand served was `score: 0`, `tier: New`, components `0`. This app
//    drew that as a 0.0 star rating and "Success Rate with Creators: 0%"
//    for every brand on the platform. Nothing threw: `required` binds a
//    Dart constructor, not the JSON, and `fromJson` filled every field with
//    `?? 0`.
//
//  * Its `pct()` helper multiplied each component by 100 on the way in,
//    documented as converting a [0, 1] fraction. The components were
//    already 0–100, so the day anything had recalculated them this screen
//    would have rendered "8500%". The bug never fired only because the
//    numbers were all zero. There is no `* 100` on a rate anywhere in this
//    feature now, and the replacement model does not parse a percent at
//    all. (`commissionRangeMin`/`Max` above genuinely are fractions on the
//    wire and keep their conversion.)

extension TermsSectionMapper on TermsSection {
  PartnershipTermsSection toDomain() =>
      PartnershipTermsSection(heading: heading, bullets: bullets);
}

extension PartnershipTermsDtoMapper on PartnershipTermsDto {
  PartnershipTerms toDomain() => PartnershipTerms(
        versionNumber: versionNumber,
        whoCanJoin: whoCanJoin.toDomain(),
        reelContentRules: reelContentRules.toDomain(),
      );
}

extension MoneyDtoMapper on MoneyDto {
  PartnershipMoney toDomain() =>
      PartnershipMoney(amount: amount, currency: currency);
}

extension PotentialEarningsDtoMapper on PotentialEarningsDto {
  PotentialEarnings toDomain() => PotentialEarnings(
        partnershipId: partnershipId,
        productVariantId: productVariantId,
        commissionRate: commissionRate,
        unitPrice: unitPrice.toDomain(),
        perSale: perSale.toDomain(),
        perFiftySales: perFiftySales.toDomain(),
        salesAssumed: salesAssumed,
      );
}

extension RecipeAttachmentInfoDtoMapper on RecipeAttachmentInfoDto {
  RecipeAttachmentInfo toDomain() => RecipeAttachmentInfo(
        recipeId: recipeId,
        recipeVersion: recipeVersion,
        isHidden: isHidden,
        title: title,
        thumbnailUrl: thumbnailUrl,
      );
}
