/// A vendor's published campaign, as a creator sees it.
///
/// This is the creator-facing half of what the vendor authors in Brand Studio.
/// The server decides which briefs qualify — draft, retired and out-of-window
/// briefs are 404 to a creator — so nothing here re-judges eligibility.
///
/// Every guideline field is nullable all the way from the JSONB body, and that
/// is load-bearing: a vendor who never wrote a tone-of-voice rule is different
/// from one who wrote an empty one. The UI must render the first as absent
/// rather than as a blank section, so this type keeps null and '' apart and
/// never coalesces one into the other.
library;

/// One suggested opening line, with the reason the vendor suggests it.
class BriefHook {
  const BriefHook({required this.text, required this.rationale});

  final String text;
  final String rationale;
}

/// A link to material the creator works from — a logo pack, a swatch sheet,
/// a reel to match.
class BrandAssetLink {
  const BrandAssetLink({required this.url, this.label});

  final String url;

  /// Null when the vendor gave a bare URL and no name for it.
  final String? label;

  /// What to show as the link's name. Falls back to the URL because a link
  /// with no label is still a link the creator can follow — this is a display
  /// fallback, not a claim that the vendor supplied a label.
  String get displayLabel => (label != null && label!.trim().isNotEmpty)
      ? label!
      : url;
}

/// How the brand itself must appear and sound.
///
/// Each rule is separately nullable: a vendor may care about logo usage and
/// have nothing to say about tone.
class BrandPresentation {
  const BrandPresentation({
    this.brandNameUsage,
    this.logoAndMarkUsage,
    this.toneOfVoice,
    this.mandatoryMentions,
  });

  final String? brandNameUsage;
  final String? logoAndMarkUsage;
  final String? toneOfVoice;

  /// Null means the vendor never addressed mentions. An empty list means they
  /// said there are none. Those are different answers and stay different.
  final List<String>? mandatoryMentions;

  /// True when the vendor set no presentation rule at all, so the section can
  /// be omitted rather than drawn empty.
  bool get isEmpty =>
      brandNameUsage == null &&
      logoAndMarkUsage == null &&
      toneOfVoice == null &&
      mandatoryMentions == null;
}

/// The vendor's answer to "how must my brand be represented?".
class BrandDirection {
  const BrandDirection({
    this.campaignStory,
    this.presentation,
    this.referenceAssets,
  });

  final String? campaignStory;
  final BrandPresentation? presentation;

  /// Null means the vendor never addressed reference assets; an empty list
  /// means they said there are none.
  final List<BrandAssetLink>? referenceAssets;

  bool get isEmpty =>
      campaignStory == null &&
      (presentation == null || presentation!.isEmpty) &&
      referenceAssets == null;
}

/// The commission band the vendor is offering on this campaign.
///
/// Percent values, already scaled for display (12.5 means 12.5%).
class CommissionBand {
  const CommissionBand({required this.minPercent, required this.maxPercent});

  final double minPercent;
  final double maxPercent;

  /// The rate a tag actually snapshots. The backend derives the same midpoint
  /// server-side; showing anything else here would promise a number the
  /// commission chain would not honour.
  double get midpointPercent => (minPercent + maxPercent) / 2;

  String get label =>
      '${_trim(minPercent)}-${_trim(maxPercent)}%';

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

/// A published campaign a creator can read and apply to.
class CampaignProposal {
  const CampaignProposal({
    required this.id,
    required this.vendorProfileId,
    required this.version,
    required this.rootBriefId,
    required this.title,
    required this.commission,
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

  final String id;
  final String vendorProfileId;
  final int version;
  final String rootBriefId;

  /// Null when the vendor published without naming the campaign. The list
  /// shows a neutral placeholder rather than inventing a title.
  final String? title;

  final CommissionBand commission;
  final double? boostBudgetAmount;
  final String? boostBudgetCurrency;

  final DateTime? publishedUtc;
  final DateTime? applicationsOpenUtc;
  final DateTime? applicationsCloseUtc;

  final List<BriefHook> suggestedHooks;
  final List<String> doSayPoints;
  final List<String> dontSayPoints;
  final List<String> audioThemes;

  /// The products this campaign covers. Accepting the campaign restricts the
  /// creator's tagging to exactly these — the restriction is enforced
  /// server-side at reel-tag time, so this list is shown, not trusted.
  final List<String> productVariantIds;

  /// Null for briefs authored before brand direction existed, which is the
  /// truth about them: nobody specified anything.
  final BrandDirection? brandDirection;

  bool get hasProductRestriction => productVariantIds.isNotEmpty;
}
