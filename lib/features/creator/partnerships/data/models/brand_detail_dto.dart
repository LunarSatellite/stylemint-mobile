/// Partnership detail — backend `PartnershipDto` (`GET /v1/partnerships/{id}`).
class PartnershipDetailDto {
  const PartnershipDetailDto({
    required this.id,
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
