import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

// StyleMint Reel Caption Standard v1 — pure Dart (no Flutter imports).
// Spec: stylemint-backend/docs/REEL_CAPTION_STANDARD.md
//
//   {Hook}
//   {Product name} · Rs {price}
//   Tap the product to shop on StyleMint.
//
//   #StyleMint #{topic1} #{topic2} #AIgenerated

/// User-visible copy owned by the standard. Kept in one place so it can be
/// swapped for a localized string: pass the translated value to
/// [ReelCaption.compose] / [ReelCaption.parse] via their `cta` parameter.
abstract final class ReelCaptionCopy {
  /// The single call to action. Never vary the wording per reel.
  static const String cta = 'Tap the product to shop on StyleMint.';
}

/// A tagged product as it appears in a caption: display name + price.
class CaptionProduct {
  const CaptionProduct({required this.name, required this.price});

  final String name;
  final Money price;
}

/// One rendered product line, split so a renderer can style the price.
/// [label] is "AeroPods Air" (or "AeroPods Air + 2 more"); [price] is
/// "Rs 8,999" (or "from Rs 1,800").
class CaptionProductLine {
  const CaptionProductLine({required this.label, required this.price});

  final String label;
  final String price;

  String get text => '$label${ReelCaption.productSeparator}$price';

  @override
  bool operator ==(Object other) =>
      other is CaptionProductLine &&
      other.label == label &&
      other.price == price;

  @override
  int get hashCode => Object.hash(label, price);

  @override
  String toString() => text;
}

enum CaptionIssueCode {
  hookMissing,
  hookTooShort,
  hookTooLong,
  hookHasHashtag,
  hookHasPrice,
  hookHasLink,
  hookTooManyEmoji,
  hookNotSentenceCase,
  shoutingWord,
  tooManyTopicTags,
  aiTagAsTopic,
  aiDisclosureMissing,
  captionTooLong,
}

/// A human-readable problem with a draft caption. [blocking] issues must be
/// fixed before the caption can be shared/saved; the rest are guidance.
class CaptionIssue {
  const CaptionIssue(this.code, this.message, {this.blocking = false});

  final CaptionIssueCode code;
  final String message;
  final bool blocking;

  @override
  String toString() => message;
}

/// Structured view of a caption string.
class ParsedReelCaption {
  const ParsedReelCaption({
    required this.raw,
    required this.hook,
    required this.productLines,
    required this.hasCta,
    required this.hashtags,
    required this.isStandard,
  });

  /// The caption with normalized line endings.
  final String raw;

  /// First line. For non-standard captions: the first line without hashtags.
  final String hook;

  /// Empty for non-standard captions.
  final List<CaptionProductLine> productLines;
  final bool hasCta;

  /// Tag text without the leading `#`, in order of appearance. For standard
  /// captions these are the tags on the hashtag line; otherwise every
  /// hashtag found anywhere in the caption.
  final List<String> hashtags;

  /// Whether the caption follows the standard layout exactly enough to be
  /// rendered as hook / product lines / CTA / hashtags.
  final bool isStandard;

  bool get isEmpty => raw.trim().isEmpty;

  /// Topic tags (no #StyleMint / #AIgenerated), de-duplicated, max 3.
  List<String> get topicTags => ReelCaption.normalizeTopicTags(hashtags);

  bool get hasAiTag => hashtags.any(
    (t) => t.toLowerCase() == ReelCaption.aiTag.toLowerCase(),
  );
}

/// Composer, parser and linter for the StyleMint Reel Caption Standard.
abstract final class ReelCaption {
  static const int hookMinLength = 20;
  static const int hookMaxLength = 70;
  static const int maxProductLines = 2;
  static const int maxTopicTags = 3;
  static const int maxHashtags = 5;
  static const int maxLength = 300;

  static const String brandTag = 'StyleMint';
  static const String aiTag = 'AIgenerated';
  static const String productSeparator = ' · ';

  static final RegExp _whitespace = RegExp(r'\s+');
  static final RegExp _hashtag = RegExp(
    r'#([\p{L}\p{M}\p{N}_]+)',
    unicode: true,
  );
  static final RegExp _hashtagToken = RegExp(
    r'^#[\p{L}\p{M}\p{N}_]+$',
    unicode: true,
  );
  static final RegExp _nonTagChars = RegExp(
    r'[^\p{L}\p{M}\p{N}]',
    unicode: true,
  );
  static final RegExp _letters = RegExp(r'\p{L}+', unicode: true);
  static final RegExp _pictographic = RegExp(
    r'\p{Extended_Pictographic}',
    unicode: true,
  );
  static final RegExp _productPrice = RegExp(
    r'^(from )?(Rs|[A-Z]{3}) ?\d[\d,]*(\.\d+)?$',
  );
  static final RegExp _priceMention = RegExp(
    r'\b(rs|npr|inr|usd)\.?\s?\d|\d[\d,]*\s?(rs|npr)\b|\$\s?\d|रु',
    caseSensitive: false,
  );
  static final RegExp _link = RegExp(
    r'(https?://|www\.)\S+'
    r'|\b[\w-]+\.(com|app|net|org|np|io|co|shop|store|link|me|ly|in)\b(/\S*)?',
    caseSensitive: false,
  );
  static final RegExp _aiMention = RegExp(
    r'\bai[\s_-]?generated\b'
    r'|\b(made|generated|created) (with|by|using) ai\b'
    r'|#aigc\b',
    caseSensitive: false,
  );
  static final RegExp _firstSentence = RegExp(r'^.+?[.!?](?=\s|$)');

  // ── Compose ──────────────────────────────────────────────────────────────

  /// Builds the caption string. Topic tags are normalized (letters/digits
  /// only, de-duplicated case-insensitively, max 3); `#AIgenerated` is added
  /// when [aiGenerated] is true. No products → no product lines and no CTA.
  static String compose({
    required String hook,
    required List<CaptionProduct> products,
    required bool aiGenerated,
    List<String> topicTags = const [],
    String cta = ReelCaptionCopy.cta,
  }) {
    final hookLine = normalizeHook(hook);
    final lines = productLinesFor(products);
    final body = <String>[
      if (hookLine.isNotEmpty) hookLine,
      ...lines.map((l) => l.text),
      if (lines.isNotEmpty) cta,
    ];
    final tags = hashtagsFor(
      topicTags: topicTags,
      aiGenerated: aiGenerated,
    ).map((t) => '#$t').join(' ');
    return body.isEmpty ? tags : '${body.join('\n')}\n\n$tags';
  }

  /// One line per product (max 2); 3+ products collapse into
  /// "{first} + {n} more · from Rs {lowest}".
  static List<CaptionProductLine> productLinesFor(
    List<CaptionProduct> products,
  ) {
    if (products.isEmpty) return const [];
    if (products.length <= maxProductLines) {
      return [
        for (final p in products)
          CaptionProductLine(
            label: _productName(p),
            price: formatCaptionPrice(p.price),
          ),
      ];
    }
    final lowest = products
        .map((p) => p.price)
        .reduce((a, b) => b.amount < a.amount ? b : a);
    return [
      CaptionProductLine(
        label: '${_productName(products.first)} + ${products.length - 1} more',
        price: 'from ${formatCaptionPrice(lowest)}',
      ),
    ];
  }

  /// "Rs 8,999" for whole amounts, "Rs 8,999.50" otherwise — via the app's
  /// shared [formatMoney].
  static String formatCaptionPrice(Money price) {
    final whole = price.amount == price.amount.roundToDouble();
    return formatMoney(price, decimalDigits: whole ? 0 : 2);
  }

  /// `StyleMint`, then up to 3 topic tags, then `AIgenerated` if flagged.
  /// Returned without the `#`. Never more than [maxHashtags].
  static List<String> hashtagsFor({
    required List<String> topicTags,
    required bool aiGenerated,
  }) => [brandTag, ...normalizeTopicTags(topicTags), if (aiGenerated) aiTag];

  static String normalizeHook(String hook) =>
      hook.replaceAll(_whitespace, ' ').trim();

  /// Letters, marks and digits only; null when nothing is left.
  static String? normalizeTopicTag(String raw) {
    final cleaned = raw.replaceAll(_nonTagChars, '');
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Normalizes, drops the system tags (#StyleMint, #AIgenerated),
  /// de-duplicates case-insensitively (first spelling wins) and caps at [max].
  static List<String> normalizeTopicTags(
    Iterable<String> raw, {
    int max = maxTopicTags,
  }) {
    final seen = <String>{};
    final out = <String>[];
    for (final r in raw) {
      if (out.length >= max) break;
      final tag = normalizeTopicTag(r);
      if (tag == null || _isSystemTag(tag)) continue;
      if (seen.add(tag.toLowerCase())) out.add(tag);
    }
    return out;
  }

  /// Caption length as the standard counts it (Unicode code points).
  static int length(String text) => text.runes.length;

  static bool isHookLengthValid(String hook) {
    final n = length(normalizeHook(hook));
    return n >= hookMinLength && n <= hookMaxLength;
  }

  // ── Parse ────────────────────────────────────────────────────────────────

  static ParsedReelCaption parse(
    String caption, {
    String cta = ReelCaptionCopy.cta,
  }) {
    final raw = caption.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      return ParsedReelCaption(
        raw: raw,
        hook: '',
        productLines: const [],
        hasCta: false,
        hashtags: const [],
        isStandard: false,
      );
    }

    final standard = _parseStandard(raw, lines, cta);
    if (standard != null) return standard;

    return ParsedReelCaption(
      raw: raw,
      hook: normalizeHook(lines.first.replaceAll(_hashtag, '')),
      productLines: const [],
      hasCta: lines.contains(cta),
      hashtags: extractHashtags(raw),
      isStandard: false,
    );
  }

  static ParsedReelCaption? _parseStandard(
    String raw,
    List<String> lines,
    String cta,
  ) {
    if (lines.length < 2) return null;

    final tokens = lines.last.split(_whitespace);
    if (!tokens.every(_hashtagToken.hasMatch)) return null;
    if (tokens.first.substring(1).toLowerCase() != brandTag.toLowerCase()) {
      return null;
    }

    final body = lines.sublist(0, lines.length - 1);
    final hook = body.first;
    if (hook.contains('#') || hook == cta) return null;

    var rest = body.sublist(1);
    final hasCta = rest.isNotEmpty && rest.last == cta;
    if (hasCta) rest = rest.sublist(0, rest.length - 1);
    // Product lines and the CTA come together or not at all.
    if (rest.isEmpty == hasCta) return null;
    if (rest.length > maxProductLines) return null;

    final products = <CaptionProductLine>[];
    for (final line in rest) {
      final product = _parseProductLine(line);
      if (product == null) return null;
      products.add(product);
    }

    return ParsedReelCaption(
      raw: raw,
      hook: hook,
      productLines: List.unmodifiable(products),
      hasCta: hasCta,
      hashtags: [for (final t in tokens) t.substring(1)],
      isStandard: true,
    );
  }

  static CaptionProductLine? _parseProductLine(String line) {
    final i = line.lastIndexOf(productSeparator);
    if (i <= 0) return null;
    final label = line.substring(0, i).trim();
    final price = line.substring(i + productSeparator.length).trim();
    if (label.isEmpty || !_productPrice.hasMatch(price)) return null;
    return CaptionProductLine(label: label, price: price);
  }

  /// Every hashtag in [text], without the `#`, in order of appearance.
  static List<String> extractHashtags(String text) => [
    for (final m in _hashtag.allMatches(text)) m.group(1)!,
  ];

  // ── Suggestions from a platform caption ───────────────────────────────────

  /// Existing hashtags from the platform caption as topic tags, minus
  /// #StyleMint / #AIgenerated, normalized, max 3.
  static List<String> suggestTopicTags(String platformCaption) =>
      normalizeTopicTags(extractHashtags(platformCaption));

  /// The platform caption's first sentence (links and hashtags removed) if it
  /// fits the hook length rule; otherwise empty so the creator writes one.
  static String suggestHook(String platformCaption) {
    for (final line in platformCaption.split(RegExp(r'[\r\n]+'))) {
      final cleaned = normalizeHook(
        line.replaceAll(_link, '').replaceAll(_hashtag, ''),
      );
      if (cleaned.isEmpty) continue;
      final sentence =
          (_firstSentence.firstMatch(cleaned)?.group(0) ?? cleaned).trim();
      return isHookLengthValid(sentence) ? sentence : '';
    }
    return '';
  }

  /// Whether a caption says the reel is AI-generated / synthetic.
  static bool mentionsAiGenerated(String caption) =>
      _aiMention.hasMatch(caption);

  // ── Lint ─────────────────────────────────────────────────────────────────

  /// Problems with a draft, most important first. Blocking issues (missing
  /// hook, hook outside 20–70 characters) must be fixed before sharing.
  static List<CaptionIssue> issues({
    required String hook,
    required List<CaptionProduct> products,
    required bool aiGenerated,
    List<String> topicTags = const [],
    String? sourceCaption,
  }) {
    final out = <CaptionIssue>[];
    final h = normalizeHook(hook);
    final n = length(h);

    if (h.isEmpty) {
      out.add(
        const CaptionIssue(
          CaptionIssueCode.hookMissing,
          'Add a hook — it is the first line viewers see.',
          blocking: true,
        ),
      );
    } else if (n < hookMinLength) {
      out.add(
        CaptionIssue(
          CaptionIssueCode.hookTooShort,
          'Hook is too short: $n of at least $hookMinLength characters.',
          blocking: true,
        ),
      );
    } else if (n > hookMaxLength) {
      out.add(
        CaptionIssue(
          CaptionIssueCode.hookTooLong,
          'Hook is too long: $n of at most $hookMaxLength characters.',
          blocking: true,
        ),
      );
    }

    if (h.contains('#')) {
      out.add(
        const CaptionIssue(
          CaptionIssueCode.hookHasHashtag,
          'Keep hashtags out of the hook — add them as topic tags.',
        ),
      );
    }
    if (_priceMention.hasMatch(h)) {
      out.add(
        const CaptionIssue(
          CaptionIssueCode.hookHasPrice,
          'Keep the price out of the hook — it is added from the tagged product.',
        ),
      );
    }
    if (_link.hasMatch(h)) {
      out.add(
        const CaptionIssue(
          CaptionIssueCode.hookHasLink,
          'Remove the link — links do not work in captions.',
        ),
      );
    }
    if (emojiCount(h) > 1) {
      out.add(
        const CaptionIssue(
          CaptionIssueCode.hookTooManyEmoji,
          'Use at most one emoji in the hook.',
        ),
      );
    }
    if (_startsLowercase(h)) {
      out.add(
        const CaptionIssue(
          CaptionIssueCode.hookNotSentenceCase,
          'Start the hook with a capital letter.',
        ),
      );
    }

    final shouting = shoutingWords([h, ...topicTags]);
    if (shouting.isNotEmpty) {
      out.add(
        CaptionIssue(
          CaptionIssueCode.shoutingWord,
          'Avoid ALL-CAPS words like "${shouting.first}".',
        ),
      );
    }

    final distinctTopics = normalizeTopicTags(topicTags, max: 1 << 20);
    if (distinctTopics.length > maxTopicTags) {
      out.add(
        const CaptionIssue(
          CaptionIssueCode.tooManyTopicTags,
          'Use at most $maxTopicTags topic tags.',
        ),
      );
    }

    final aiAsTopic = topicTags
        .map(normalizeTopicTag)
        .any((t) => t != null && t.toLowerCase() == aiTag.toLowerCase());
    if (aiAsTopic && !aiGenerated) {
      out.add(
        const CaptionIssue(
          CaptionIssueCode.aiTagAsTopic,
          'Turn on "AI-generated content" instead of adding #AIgenerated as a topic tag.',
        ),
      );
    } else if (!aiGenerated &&
        sourceCaption != null &&
        mentionsAiGenerated(sourceCaption)) {
      out.add(
        const CaptionIssue(
          CaptionIssueCode.aiDisclosureMissing,
          'The original caption says this reel is AI-generated. Turn on "AI-generated content" so #AIgenerated is included.',
        ),
      );
    }

    final total = length(
      compose(
        hook: hook,
        products: products,
        topicTags: topicTags,
        aiGenerated: aiGenerated,
      ),
    );
    if (total > maxLength) {
      out.add(
        CaptionIssue(
          CaptionIssueCode.captionTooLong,
          'Caption is too long: $total of at most $maxLength characters. '
          'Shorten the hook or remove a topic tag.',
        ),
      );
    }

    return out;
  }

  /// Emoji in [text]; a ZWJ sequence (e.g. a family emoji) counts once.
  static int emojiCount(String text) {
    var count = 0;
    for (final m in _pictographic.allMatches(text)) {
      final joined = m.start > 0 && text.codeUnitAt(m.start - 1) == 0x200D;
      if (!joined) count++;
    }
    return count;
  }

  /// ALL-CAPS words longer than 4 letters ("AMAZING"); short acronyms such
  /// as "NPR" or "SPF" are allowed.
  static List<String> shoutingWords(Iterable<String> texts) => [
    for (final text in texts)
      for (final m in _letters.allMatches(text))
        if (_isShouting(m.group(0)!)) m.group(0)!,
  ];

  static bool _isShouting(String word) =>
      word.length > 4 &&
      word == word.toUpperCase() &&
      word != word.toLowerCase();

  static bool _startsLowercase(String text) {
    final first = _letters.firstMatch(text)?.group(0);
    if (first == null) return false;
    final c = first[0];
    return c == c.toLowerCase() && c != c.toUpperCase();
  }

  static bool _isSystemTag(String tag) {
    final lower = tag.toLowerCase();
    return lower == brandTag.toLowerCase() || lower == aiTag.toLowerCase();
  }

  static String _productName(CaptionProduct product) {
    final name = normalizeHook(product.name);
    return name.isEmpty ? 'Product' : name;
  }
}

/// Editor state for one caption: the structured inputs plus derived output.
class ReelCaptionDraft {
  const ReelCaptionDraft({
    required this.hook,
    required this.products,
    required this.aiGenerated,
    this.topicTags = const [],
    this.sourceCaption,
  });

  /// Pre-fill for a freshly imported reel from its platform caption.
  factory ReelCaptionDraft.fromPlatformCaption(
    String platformCaption, {
    required List<CaptionProduct> products,
  }) => ReelCaptionDraft(
    hook: ReelCaption.suggestHook(platformCaption),
    products: products,
    topicTags: ReelCaption.suggestTopicTags(platformCaption),
    aiGenerated: ReelCaption.mentionsAiGenerated(platformCaption),
    sourceCaption: platformCaption,
  );

  /// Pre-fill for editing a published reel: a standard caption round-trips
  /// through [ReelCaption.parse]; anything else is treated like a platform
  /// caption.
  factory ReelCaptionDraft.fromExistingCaption(
    String? caption, {
    required List<CaptionProduct> products,
  }) {
    final text = caption ?? '';
    final parsed = ReelCaption.parse(text);
    if (!parsed.isStandard) {
      return ReelCaptionDraft.fromPlatformCaption(text, products: products);
    }
    return ReelCaptionDraft(
      hook: parsed.hook,
      products: products,
      topicTags: parsed.topicTags,
      aiGenerated: parsed.hasAiTag,
      sourceCaption: text,
    );
  }

  final String hook;
  final List<CaptionProduct> products;
  final List<String> topicTags;
  final bool aiGenerated;

  /// Original caption (platform or previously saved), used to flag a
  /// dropped AI disclosure.
  final String? sourceCaption;

  String get caption => ReelCaption.compose(
    hook: hook,
    products: products,
    topicTags: topicTags,
    aiGenerated: aiGenerated,
  );

  List<CaptionIssue> get issues => ReelCaption.issues(
    hook: hook,
    products: products,
    topicTags: topicTags,
    aiGenerated: aiGenerated,
    sourceCaption: sourceCaption,
  );

  /// Share / Save stay disabled until the hook is 20–70 characters.
  bool get canSubmit => ReelCaption.isHookLengthValid(hook);

  ReelCaptionDraft copyWith({
    String? hook,
    List<CaptionProduct>? products,
    List<String>? topicTags,
    bool? aiGenerated,
  }) => ReelCaptionDraft(
    hook: hook ?? this.hook,
    products: products ?? this.products,
    topicTags: topicTags ?? this.topicTags,
    aiGenerated: aiGenerated ?? this.aiGenerated,
    sourceCaption: sourceCaption,
  );
}
