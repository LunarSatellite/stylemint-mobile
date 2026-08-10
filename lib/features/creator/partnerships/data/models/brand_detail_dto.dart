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
    this.avgOrderValue,
    this.successRatePercent,
  });

  final String id;
  final String vendorProfileId;
  final String stateLabel;
  final double commissionMinPercent;
  final double commissionMaxPercent;
  final double? vendorRating;
  final String? requestMessage;
  final String vendorName;
  final String? vendorLogoUrl;
  final String? vendorCategory;
  final String? description;
  final double? avgOrderValue;
  final double? successRatePercent;

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
          (json['commissionMinPercent'] as num?)?.toDouble() ?? 0,
      commissionMaxPercent:
          (json['commissionMaxPercent'] as num?)?.toDouble() ?? 0,
      vendorRating: (json['vendorRating'] as num?)?.toDouble(),
      requestMessage: json['requestMessage'] as String?,
      vendorName: (json['vendorName'] as String?) ?? '',
      vendorLogoUrl: json['vendorLogoUrl'] as String?,
      vendorCategory: json['vendorCategory'] as String?,
      description: json['description'] as String?,
      avgOrderValue: (json['avgOrderValue'] as num?)?.toDouble(),
      successRatePercent: (json['successRatePercent'] as num?)?.toDouble(),
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

/// A single sample campaign — backend `GET /v1/partnerships/{id}/campaigns`.
class SampleCampaignDto {
  const SampleCampaignDto({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.reelCount,
    required this.creatorCollabCount,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final int reelCount;
  final int creatorCollabCount;

  factory SampleCampaignDto.fromJson(Map<String, dynamic> json) {
    return SampleCampaignDto(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      reelCount: (json['reelCount'] as num?)?.toInt() ?? 0,
      creatorCollabCount: (json['creatorCollabCount'] as num?)?.toInt() ?? 0,
    );
  }
}

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
