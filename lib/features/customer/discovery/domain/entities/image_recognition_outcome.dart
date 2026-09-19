/// What the server's vision path actually achieved with a customer's image.
///
/// Mirrors the backend `VisualRecognitionOutcome`. The distinction exists
/// because the endpoint used to lie: when vision read features and the
/// catalogue matched nothing, it returned top-rated products by category,
/// indistinguishable from a real match. The outcome is now the thing that
/// says "we recognised this" — a non-empty product list no longer implies it.
///
/// The three real endings are kept apart all the way to the screen, because
/// they mean genuinely different things to a buyer:
///
/// * [matched] — the Mall stocks what was in the picture.
/// * [recognizedNoMatch] — the Mall *saw* it and does not stock it. The most
///   informative of the three, and the reason `recognizedFeatures` exists.
/// * [notRecognized] — the picture gave vision nothing to search with.
enum ImageRecognitionOutcome {
  matched,
  recognizedNoMatch,
  notRecognized,

  /// An outcome this build does not know — a value added to the server enum
  /// after this app shipped. Never assumed to mean recognition.
  unknown;

  /// Reads the wire value, which may arrive either as the enum's integer
  /// ordinal (the default `System.Text.Json` encoding, which is what the
  /// endpoint currently emits) or as its name, should the server later gain
  /// a `JsonStringEnumConverter`. Both are accepted so that adding the
  /// attribute server-side is not a client-breaking change.
  ///
  /// Returns `null` only when the field is absent — on the multimodal
  /// endpoint that legitimately means "no image was supplied". A present but
  /// unrecognised value is [unknown], which is a different thing from absent
  /// and must not be silently read as a match.
  static ImageRecognitionOutcome? maybeFrom(Object? raw) {
    if (raw == null) return null;
    if (raw is int) {
      return switch (raw) {
        0 => matched,
        1 => notRecognized,
        2 => recognizedNoMatch,
        _ => unknown,
      };
    }
    if (raw is String) {
      final name = raw.trim().toLowerCase();
      if (name.isEmpty) return null;
      return switch (name) {
        'matched' => matched,
        'notrecognized' => notRecognized,
        'recognizednomatch' => recognizedNoMatch,
        // A numeric string is still a number.
        _ => maybeFrom(int.tryParse(name)) ?? unknown,
      };
    }
    return unknown;
  }

  /// True only for [matched]. Every other value — including [unknown] — means
  /// the client may not tell the customer their image was recognised.
  bool get isRecognisedMatch => this == matched;

  /// True when the server positively reported that it found nothing. Products
  /// must never be shown for these.
  bool get isNoMatch => this == recognizedNoMatch || this == notRecognized;
}
