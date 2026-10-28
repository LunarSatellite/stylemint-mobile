import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/image_recognition_outcome.dart';

/// Real search-result rows from `GET /api/v1/customer/search`.
class SearchResultProduct {
  const SearchResultProduct({
    required this.productId,
    required this.name,
    required this.heroImageUrl,
    required this.price,
    required this.currency,
    required this.averageRating,
    this.isSponsored = false,
    this.sponsoredLabel,
    this.organicPosition,
    this.matchReason,
    this.matchType = SearchMatchType.unknown,
  });

  final String productId;
  final String name;
  final String heroImageUrl;
  final double price;
  final String currency;
  final double averageRating;

  /// Voyager "Transparent Sponsored Product Boosting": true when this result
  /// is in a paid slot. Backend `ProductTileDto.IsSponsored`.
  final bool isSponsored;

  /// The disclosure the backend wants shown ("Sponsored"); null otherwise.
  final String? sponsoredLabel;

  /// Where this product ranked organically for the search (1-based); null
  /// for organic results or when unknown.
  final int? organicPosition;

  /// A short explanation supplied by the AI ranker when available.
  final String? matchReason;

  /// How the search found this product (AI features contract v1.0 §1).
  final SearchMatchType matchType;

  /// The disclosure a sponsored result must show, falling back to
  /// "Sponsored" if the label is missing; null for organic results.
  String? get sponsoredDisclosure =>
      isSponsored ? (sponsoredLabel ?? 'Sponsored') : null;
}

class SearchResultBrand {
  const SearchResultBrand({
    required this.brandId,
    required this.name,
    this.logoUrl,
    required this.averageRating,
    required this.productCount,
  });

  /// The vendor ACCOUNT id — what `/brands/{id}` and `GET v1/brands/{id}`
  /// expect. Read from `vendorAccountId` when the server sends it, else from
  /// `brandId` (which the search contract makes the account id too).
  final String brandId;
  final String name;
  final String? logoUrl;
  final double averageRating;
  final int productCount;
}

class SearchResultReel {
  const SearchResultReel({
    required this.reelId,
    required this.thumbnailUrl,
    required this.viewCount,
    this.matchType = SearchMatchType.unknown,
    this.matchReason,
  });

  final String reelId;
  final String thumbnailUrl;
  final int viewCount;

  /// How the search found this reel (AI features contract v1.0 §1).
  final SearchMatchType matchType;

  /// The server's short explanation; null when AI did not shape the search.
  final String? matchReason;
}

/// How one search hit was found — `matchType` on a search tile (AI features
/// contract v1.0 §1): `1` keyword, `2` meaning only, `3` both.
///
/// [unknown] is an older server that does not send the field. It is never
/// read as [meaning]: a hit nobody labelled must not wear the meaning chip.
enum SearchMatchType {
  keyword,
  meaning,
  both,
  unknown;

  static SearchMatchType parse(Object? raw) {
    final value = raw is num
        ? raw.toInt()
        : (raw is String ? int.tryParse(raw.trim()) : null);
    return switch (value) {
      1 => keyword,
      2 => meaning,
      3 => both,
      _ => unknown,
    };
  }

  /// Found only by similarity of meaning — no word of the query matched.
  bool get isMeaningOnly => this == meaning;
}

/// What one chip in `understanding.chips` says the search did with part of
/// the query (AI features contract v1.0 §1).
enum SearchChipKind {
  /// A hard filter: only results that satisfy it are shown.
  constraint,

  /// Ordered the results; removed nothing.
  preference,

  /// A "not …" the search enforced.
  exclusion,

  /// Recognised and deliberately not enforced (e.g. a budget).
  notApplied,

  /// A kind this build does not know. Never drawn.
  unknown;

  static SearchChipKind parse(Object? raw) => switch (raw) {
    'constraint' => constraint,
    'preference' => preference,
    'exclusion' => exclusion,
    'notApplied' => notApplied,
    _ => unknown,
  };

  /// The three kinds that change the results, and so can be taken off.
  bool get acts =>
      this == constraint || this == preference || this == exclusion;
}

/// One part of the query the search acted on.
class SearchUnderstandingChip {
  const SearchUnderstandingChip({
    required this.kind,
    required this.statement,
    required this.sourceText,
    this.attributeKey = '',
    this.label = '',
  });

  final SearchChipKind kind;
  final String attributeKey;
  final String label;

  /// "Material is cotton" — or, for [SearchChipKind.notApplied], a stable
  /// reason code (`budget`, `attribute-lookup-unavailable`), not prose.
  final String statement;

  /// The words of the query this chip came from ("cotton").
  final String sourceText;

  /// What the chip says on screen, or null when it has nothing to say.
  ///
  /// A not-applied chip quotes the customer's own words and says they were
  /// not used; its reason code is never shown as if it were a sentence.
  String? get displayText {
    switch (kind) {
      case SearchChipKind.constraint:
      case SearchChipKind.preference:
      case SearchChipKind.exclusion:
        final statementText = statement.trim();
        final text = statementText.isNotEmpty
            ? statementText
            : sourceText.trim();
        return text.isEmpty ? null : text;
      case SearchChipKind.notApplied:
        final source = sourceText.trim();
        return source.isEmpty ? null : 'Not applied: \u201c$source\u201d';
      case SearchChipKind.unknown:
        return null;
    }
  }

  /// Whether the customer can take this chip off and search again: it acts
  /// on the results and its words can be found in [query].
  bool canRemoveFrom(String query) =>
      kind.acts && queryWithoutChip(query, this) != null;
}

/// `understanding` on a search response (AI features contract v1.0 §1): what
/// the words were read as. Deterministic, so present with or without AI.
class SearchUnderstanding {
  const SearchUnderstanding({
    this.searchedText,
    this.retrievalMode,
    this.chips = const [],
    this.setAsideUnverifiable = 0,
    this.setAsideConflicting = 0,
    this.degradedReason,
  });

  final String? searchedText;

  /// `lexical` or `hybrid` — what actually ran.
  final String? retrievalMode;
  final List<SearchUnderstandingChip> chips;

  /// Results left out because they never recorded the attribute asked about.
  final int setAsideUnverifiable;

  /// Results left out because what they recorded contradicts the ask.
  final int setAsideConflicting;
  final String? degradedReason;

  /// The chips that have something to draw, in server order.
  List<SearchUnderstandingChip> get visibleChips => [
    for (final chip in chips)
      if (chip.displayText != null) chip,
  ];

  int get setAsideTotal => setAsideUnverifiable + setAsideConflicting;
}

/// [query] with [chip]'s words taken out, so the search can run again
/// without what that chip enforced. Null when the words are not in the query
/// as whole words, or when nothing would be left to search for.
String? queryWithoutChip(String query, SearchUnderstandingChip chip) {
  final source = chip.sourceText.trim();
  if (source.isEmpty) return null;
  final pattern = RegExp(
    '(^|\\s)${RegExp.escape(source)}(?=\\s|\$)',
    caseSensitive: false,
  );
  if (!pattern.hasMatch(query)) return null;
  final rest = query
      .replaceFirst(pattern, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return rest.isEmpty ? null : rest;
}

class SearchResultCreator {
  const SearchResultCreator({
    required this.creatorProfileId,
    required this.handle,
    required this.displayName,
    this.avatarUrl,
    required this.followerCount,
  });

  final String creatorProfileId;
  final String handle;
  final String displayName;
  final String? avatarUrl;

  /// Follower total, or null when it was not measured. Null renders as
  /// absent rather than as a zero.
  final int? followerCount;
}

class CustomerSearchResults {
  const CustomerSearchResults({
    required this.products,
    required this.brands,
    required this.reels,
    required this.creators,
    required this.totalHits,
    this.queryUnderstanding,
    this.aiApplied = false,
    this.productTotal,
    this.imageRecognition,
    this.recognizedFeatures = const [],
    this.understanding,
    this.requestId,
  });

  static const empty = CustomerSearchResults(
    products: [],
    brands: [],
    reels: [],
    creators: [],
    totalHits: 0,
  );

  final List<SearchResultProduct> products;
  final List<SearchResultBrand> brands;
  final List<SearchResultReel> reels;
  final List<SearchResultCreator> creators;
  final int totalHits;
  final String? queryUnderstanding;

  /// The search response's ranking id (first page of the unified search
  /// only), echoed on interaction events; null when the server sent none.
  final String? requestId;

  /// Whether AI (an LLM reading of the query, semantic retrieval, or vision
  /// for a photo) really shaped these results. Only then may the screen say
  /// "Understood as", draw the sparkle or show per-product reasons. A
  /// server that does not send `aiApplied` reads as false.
  final bool aiApplied;

  /// Every product matching the query (the server may cap it), for "See all
  /// N products"; null when the server did not say.
  final int? productTotal;

  /// What the image arm of the search achieved, or `null` when no image was
  /// part of the request. When this is anything other than
  /// [ImageRecognitionOutcome.matched], nothing in [products] may be
  /// presented to the customer as recognised from their picture.
  final ImageRecognitionOutcome? imageRecognition;

  /// The features vision read out of the image, so a no-match can say what
  /// was seen instead of shrugging. Empty when nothing was recognised or
  /// when the endpoint does not report features.
  final List<String> recognizedFeatures;

  /// What the search read the words as (AI features contract v1.0 §1). It
  /// may carry chips while [aiApplied] is false — the reading is
  /// deterministic — so a chip never wears AI wording on its own.
  final SearchUnderstanding? understanding;
}
