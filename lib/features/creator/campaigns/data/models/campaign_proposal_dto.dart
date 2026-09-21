import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_proposal.dart';

/// Maps `BrandBriefDto` from `GET /v1/creator/campaigns[/{briefId}]`.
///
/// The guideline fields live inside a JSONB `body` document that the server
/// serializes with `WhenWritingNull`, so a rule the vendor never wrote is
/// *absent from the JSON*, not null-valued. Reading an absent key and reading
/// an explicit null both land here as null, which is the answer we want: in
/// both cases nobody specified anything. What this mapper must not do is turn
/// either into `''` or into an empty list, because the UI distinguishes
/// "unspecified" from "specified as nothing".
class CampaignProposalDto {
  const CampaignProposalDto({
    required this.id,
    required this.vendorProfileId,
    required this.version,
    required this.rootBriefId,
    required this.commissionMinPercent,
    required this.commissionMaxPercent,
    this.title,
    this.boostBudgetAmount,
    this.boostBudgetCurrency,
    this.publishedUtc,
    this.applicationsOpenUtc,
    this.applicationsCloseUtc,
    this.suggestedHooks = const [],
    this.doSayPoints = const [],
    this.dontSayPoints = const [],
    this.audioThemes = const [],
    this.productVariantIds = const [],
    this.brandDirection,
  });

  factory CampaignProposalDto.fromJson(Map<String, dynamic> json) {
    final body = json['body'] as Map<String, dynamic>?;
    final range = json['commissionRange'] as Map<String, dynamic>?;
    final direction = body?['brandDirection'] as Map<String, dynamic>?;

    return CampaignProposalDto(
      id: json['id'] as String? ?? '',
      vendorProfileId: json['vendorProfileId'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      rootBriefId: json['rootBriefId'] as String? ?? '',
      title: _nonBlank(json['title'] as String?),
      // The server sends fractions of 1 for commission; the domain carries
      // percent. Scaling here keeps the unit conversion in one place instead
      // of at every call site that formats a rate.
      commissionMinPercent:
          ((range?['minPercent'] as num?)?.toDouble() ?? 0) * 100,
      commissionMaxPercent:
          ((range?['maxPercent'] as num?)?.toDouble() ?? 0) * 100,
      boostBudgetAmount: (json['boostBudgetAmount'] as num?)?.toDouble(),
      boostBudgetCurrency: _nonBlank(json['boostBudgetCurrency'] as String?),
      publishedUtc: _utc(json['publishedUtc'] as String?),
      applicationsOpenUtc: _utc(json['applicationsOpenUtc'] as String?),
      applicationsCloseUtc: _utc(json['applicationsCloseUtc'] as String?),
      suggestedHooks: _hooks(body?['suggestedHooks']),
      doSayPoints: _strings(body?['doSayPoints']),
      dontSayPoints: _strings(body?['dontSayPoints']),
      audioThemes: _strings(body?['audioThemes']),
      productVariantIds: _strings(body?['productVariantIds']),
      brandDirection: direction == null
          ? null
          : BrandDirectionDto.fromJson(direction),
    );
  }

  final String id;
  final String vendorProfileId;
  final int version;
  final String rootBriefId;
  final String? title;
  final double commissionMinPercent;
  final double commissionMaxPercent;
  final double? boostBudgetAmount;
  final String? boostBudgetCurrency;
  final DateTime? publishedUtc;
  final DateTime? applicationsOpenUtc;
  final DateTime? applicationsCloseUtc;
  final List<BriefHook> suggestedHooks;
  final List<String> doSayPoints;
  final List<String> dontSayPoints;
  final List<String> audioThemes;
  final List<String> productVariantIds;
  final BrandDirectionDto? brandDirection;

  static List<String> _strings(dynamic raw) =>
      (raw as List<dynamic>? ?? const [])
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList(growable: false);

  static List<BriefHook> _hooks(dynamic raw) =>
      (raw as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (h) => BriefHook(
              text: h['text'] as String? ?? '',
              rationale: h['rationale'] as String? ?? '',
            ),
          )
          .where((h) => h.text.trim().isNotEmpty)
          .toList(growable: false);
}

/// Maps the `brandDirection` sub-document.
///
/// `referenceAssets` keeps the null/empty distinction the backend is explicit
/// about: null means the vendor never addressed assets, `[]` means they said
/// there are none.
class BrandDirectionDto {
  const BrandDirectionDto({
    this.campaignStory,
    this.presentation,
    this.referenceAssets,
  });

  factory BrandDirectionDto.fromJson(Map<String, dynamic> json) {
    final presentation = json['presentation'] as Map<String, dynamic>?;
    final assets = json['referenceAssets'] as List<dynamic>?;

    return BrandDirectionDto(
      campaignStory: _nonBlank(json['campaignStory'] as String?),
      presentation: presentation == null
          ? null
          : BrandPresentationDto.fromJson(presentation),
      // `?.` keeps the null/empty distinction the backend is explicit
      // about: a null list stays null, an empty one maps to an empty one.
      referenceAssets: assets
          ?.whereType<Map<String, dynamic>>()
          .map(
            (a) => BrandAssetLink(
              url: a['url'] as String? ?? '',
              label: _nonBlank(a['label'] as String?),
            ),
          )
          .where((a) => a.url.trim().isNotEmpty)
          .toList(growable: false),
    );
  }

  final String? campaignStory;
  final BrandPresentationDto? presentation;
  final List<BrandAssetLink>? referenceAssets;
}

/// Maps the `presentation` sub-document.
class BrandPresentationDto {
  const BrandPresentationDto({
    this.brandNameUsage,
    this.logoAndMarkUsage,
    this.toneOfVoice,
    this.mandatoryMentions,
  });

  factory BrandPresentationDto.fromJson(Map<String, dynamic> json) {
    final mentions = json['mandatoryMentions'] as List<dynamic>?;
    return BrandPresentationDto(
      brandNameUsage: _nonBlank(json['brandNameUsage'] as String?),
      logoAndMarkUsage: _nonBlank(json['logoAndMarkUsage'] as String?),
      toneOfVoice: _nonBlank(json['toneOfVoice'] as String?),
      mandatoryMentions: mentions
          ?.whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .toList(growable: false),
    );
  }

  final String? brandNameUsage;
  final String? logoAndMarkUsage;
  final String? toneOfVoice;
  final List<String>? mandatoryMentions;
}

/// Treats a blank string as absent.
///
/// A vendor cannot express "specified as empty" through a text guideline — the
/// authoring side trims — so `''` on the wire means nothing was written. It is
/// collapsed to null here so exactly one value stands for "unspecified" and
/// the UI has one thing to test. This does NOT apply to lists, where `[]` is a
/// real answer the vendor can give.
String? _nonBlank(String? v) =>
    (v == null || v.trim().isEmpty) ? null : v;

/// Parses a server timestamp as UTC.
///
/// The API sends ISO-8601; anything unparseable becomes null rather than a
/// fallback instant, because a wrong date on an application window would tell
/// a creator a campaign is open when it is closed.
DateTime? _utc(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}

extension CampaignProposalDtoMapper on CampaignProposalDto {
  CampaignProposal toDomain() => CampaignProposal(
    id: id,
    vendorProfileId: vendorProfileId,
    version: version,
    rootBriefId: rootBriefId,
    title: title,
    commission: CommissionBand(
      minPercent: commissionMinPercent,
      maxPercent: commissionMaxPercent,
    ),
    boostBudgetAmount: boostBudgetAmount,
    boostBudgetCurrency: boostBudgetCurrency,
    publishedUtc: publishedUtc,
    applicationsOpenUtc: applicationsOpenUtc,
    applicationsCloseUtc: applicationsCloseUtc,
    suggestedHooks: suggestedHooks,
    doSayPoints: doSayPoints,
    dontSayPoints: dontSayPoints,
    audioThemes: audioThemes,
    productVariantIds: productVariantIds,
    brandDirection: brandDirection?.toDomain(),
  );
}

extension BrandDirectionDtoMapper on BrandDirectionDto {
  BrandDirection toDomain() => BrandDirection(
    campaignStory: campaignStory,
    presentation: presentation?.toDomain(),
    referenceAssets: referenceAssets,
  );
}

extension BrandPresentationDtoMapper on BrandPresentationDto {
  BrandPresentation toDomain() => BrandPresentation(
    brandNameUsage: brandNameUsage,
    logoAndMarkUsage: logoAndMarkUsage,
    toneOfVoice: toneOfVoice,
    mandatoryMentions: mandatoryMentions,
  );
}
