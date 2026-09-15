/// A public reel shown on a creator or brand storefront.
class StorefrontReel {
  const StorefrontReel({
    required this.id,
    required this.creatorAccountId,
    this.creatorName,
    this.creatorAvatarUrl,
    this.caption,
    this.posterUrl,
    this.likeCount = 0,
    this.viewCount = 0,
    this.taggedProductCount = 0,
    this.isSavedByMe,
    this.createdUtc,
  });

  final String id;
  final String creatorAccountId;
  final String? creatorName;
  final String? creatorAvatarUrl;
  final String? caption;
  final String? posterUrl;

  /// Provider likes plus StyleMint likes.
  final int likeCount;

  /// Provider-synced views.
  final int viewCount;
  final int taggedProductCount;

  /// Null for guests.
  final bool? isSavedByMe;
  final DateTime? createdUtc;

  /// The caption carries the `#AIgenerated` disclosure, so the reel must show
  /// the "AI-generated" label.
  bool get isAiGenerated => captionIsAiGenerated(caption);

  /// The first caption line without links or hashtags, or null.
  String? get hook => captionHook(caption);
}

// Same rule as the backend's `ReelCaption.IsAiGenerated`.
final RegExp _aiDisclosure = RegExp(
  r'#aigenerated(?![\p{L}\p{N}_])',
  caseSensitive: false,
  unicode: true,
);

final RegExp _linkOrHashtag = RegExp(
  r'(https?://\S+|www\.\S+|#[\p{L}\p{N}_]+)',
  caseSensitive: false,
  unicode: true,
);

final RegExp _whitespace = RegExp(r'\s+');

/// Whether [caption] carries the `#AIgenerated` disclosure (any case).
bool captionIsAiGenerated(String? caption) =>
    caption != null && _aiDisclosure.hasMatch(caption);

/// The first caption line that still has words once links and hashtags are
/// removed; null when there is none.
String? captionHook(String? caption) {
  if (caption == null) return null;
  for (final line in caption.split('\n')) {
    final cleaned = line
        .replaceAll(_linkOrHashtag, ' ')
        .replaceAll(_whitespace, ' ')
        .trim();
    if (cleaned.isNotEmpty) return cleaned;
  }
  return null;
}
