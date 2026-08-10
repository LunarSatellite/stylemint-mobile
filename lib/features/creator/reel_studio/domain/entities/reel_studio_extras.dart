/// Domain entities for the Creator Studio insight surfaces — the read-only
/// AI-derived suggestions shown alongside a draft.
///
/// These mirror their DTOs one-for-one today; they exist so the repository
/// interface can stay in the domain layer instead of handing wire models to
/// the presentation layer.
class CoachingTip {
  const CoachingTip({
    required this.priority,
    this.category,
    this.tip,
    this.exampleText,
    this.evidenceSummary,
  });

  /// Lower sorts first in the studio's tip list.
  final int priority;
  final String? category;
  final String? tip;
  final String? exampleText;
  final String? evidenceSummary;
}

class CollabSuggestion {
  const CollabSuggestion({
    required this.otherCreatorId,
    required this.sharedProductId,
    this.otherCreatorHandle,
    this.sharedProductName,
    this.matchReason,
  });

  final String otherCreatorId;
  final String sharedProductId;
  final String? otherCreatorHandle;
  final String? sharedProductName;
  final String? matchReason;
}

class DropPartyPrompt {
  const DropPartyPrompt({
    required this.vendorAccountId,
    required this.highPerformingReelCount,
    this.vendorName,
    this.suggestionText,
  });

  final String vendorAccountId;
  final int highPerformingReelCount;
  final String? vendorName;
  final String? suggestionText;
}

class TagNudge {
  const TagNudge({
    required this.reelId,
    required this.suggestedProductId,
    this.productName,
    this.reason,
  });

  final String reelId;
  final String suggestedProductId;
  final String? productName;
  final String? reason;
}
