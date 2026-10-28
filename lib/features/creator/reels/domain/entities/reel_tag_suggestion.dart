/// One item the ML detector found in a reel (a box on one frame) with the
/// catalogue products it looks like. Mirrors backend
/// `ReelTagSuggestionDetectionDto` (camelCase JSON).
class ReelTagSuggestionDetection {
  const ReelTagSuggestionDetection({
    required this.mediaIndex,
    required this.frameIndex,
    required this.frameTimeSeconds,
    required this.label,
    required this.detectorConfidence,
    required this.boxX,
    required this.boxY,
    required this.boxWidth,
    required this.boxHeight,
    required this.framesSeen,
    required this.candidates,
  });

  factory ReelTagSuggestionDetection.fromJson(Map<String, dynamic> json) =>
      ReelTagSuggestionDetection(
        mediaIndex: (json['mediaIndex'] as num?)?.toInt() ?? 0,
        frameIndex: (json['frameIndex'] as num?)?.toInt() ?? 0,
        frameTimeSeconds: (json['frameTimeSeconds'] as num?)?.toDouble(),
        label: (json['label'] as String?) ?? '',
        detectorConfidence: (json['detectorConfidence'] as num?)?.toDouble(),
        boxX: (json['boxX'] as num?)?.toDouble() ?? 0,
        boxY: (json['boxY'] as num?)?.toDouble() ?? 0,
        boxWidth: (json['boxWidth'] as num?)?.toDouble() ?? 0,
        boxHeight: (json['boxHeight'] as num?)?.toDouble() ?? 0,
        framesSeen: (json['framesSeen'] as num?)?.toInt() ?? 0,
        candidates: (json['candidates'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ReelTagSuggestionCandidate.fromJson)
            .where((c) => c.suggestionId.isNotEmpty)
            .toList(growable: false),
      );

  final int mediaIndex;
  final int frameIndex;

  /// Null when the detector did not record a timestamp.
  final double? frameTimeSeconds;
  final String label;

  /// Null when absent from the payload — never read as 0.
  final double? detectorConfidence;

  /// Bounding box, as fractions of the frame.
  final double boxX;
  final double boxY;
  final double boxWidth;
  final double boxHeight;
  final int framesSeen;
  final List<ReelTagSuggestionCandidate> candidates;

  ReelTagSuggestionDetection withoutSuggestion(String suggestionId) =>
      ReelTagSuggestionDetection(
        mediaIndex: mediaIndex,
        frameIndex: frameIndex,
        frameTimeSeconds: frameTimeSeconds,
        label: label,
        detectorConfidence: detectorConfidence,
        boxX: boxX,
        boxY: boxY,
        boxWidth: boxWidth,
        boxHeight: boxHeight,
        framesSeen: framesSeen,
        candidates: candidates
            .where((c) => c.suggestionId != suggestionId)
            .toList(growable: false),
      );
}

/// A candidate product for a detection. Name, image, price and vendor are
/// null when the server could not read the product card (or does not carry
/// the price) — shown as unknown, never as zero.
class ReelTagSuggestionCandidate {
  const ReelTagSuggestionCandidate({
    required this.suggestionId,
    required this.productId,
    required this.rank,
    required this.similarity,
    required this.embeddingModel,
    required this.productName,
    required this.primaryImageUrl,
    required this.priceAmount,
    required this.priceCurrency,
    required this.vendorDisplayName,
  });

  factory ReelTagSuggestionCandidate.fromJson(Map<String, dynamic> json) =>
      ReelTagSuggestionCandidate(
        suggestionId: (json['suggestionId'] as String?) ?? '',
        productId: (json['productId'] as String?) ?? '',
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        similarity: (json['similarity'] as num?)?.toDouble(),
        embeddingModel: json['embeddingModel'] as String?,
        productName: json['productName'] as String?,
        primaryImageUrl: json['primaryImageUrl'] as String?,
        priceAmount: (json['priceAmount'] as num?)?.toDouble(),
        priceCurrency: json['priceCurrency'] as String?,
        vendorDisplayName: json['vendorDisplayName'] as String?,
      );

  final String suggestionId;
  final String productId;
  final int rank;
  final double? similarity;
  final String? embeddingModel;
  final String? productName;
  final String? primaryImageUrl;
  final double? priceAmount;
  final String? priceCurrency;
  final String? vendorDisplayName;

  /// "NPR 1200.00", or null when the price is not known.
  String? get priceLabel {
    final amount = priceAmount;
    if (amount == null) return null;
    final currency = priceCurrency;
    return currency == null || currency.isEmpty
        ? amount.toStringAsFixed(2)
        : '$currency ${amount.toStringAsFixed(2)}';
  }
}
