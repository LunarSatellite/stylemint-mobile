/// Apps a reel's StyleMint link can be sent to straight from StyleMint's
/// share sheet, each through the app's own documented share link.
///
/// Pure Dart. Every target carries the StyleMint link, so whoever opens it
/// lands on the reel in StyleMint. Instagram and TikTok are not here: they
/// accept no link from another app (only images or videos), so they are
/// reached through the phone's share menu or a copied link.
enum ReelShareTarget {
  /// `https://wa.me/?text=` — WhatsApp's click-to-chat share link. Shown
  /// only when WhatsApp is installed: without it the link opens a web page.
  whatsApp('WhatsApp'),

  /// On Android, the Facebook app's own share screen with the link
  /// ([androidPackage]); otherwise, or without the app,
  /// `https://www.facebook.com/sharer/sharer.php?u=` — Facebook's web share
  /// dialog (the web link never opens the app itself).
  facebook('Facebook'),

  /// `viber://forward?text=` — Viber's documented share deep link. Shown
  /// only when Viber is installed.
  viber('Viber'),

  /// `sms:?body=` — the phone's messaging app.
  messages('Messages');

  const ReelShareTarget(this.label);

  final String label;

  /// The Android app whose own share screen is tried first, before [uri].
  String? get androidPackage => switch (this) {
    ReelShareTarget.facebook => 'com.facebook.katana',
    _ => null,
  };

  /// What is handed to [androidPackage]'s share screen. Facebook ignores
  /// pre-filled text and previews a bare link, so it gets just the link.
  String appShareText({required Uri link, required String message}) =>
      this == ReelShareTarget.facebook ? link.toString() : message;

  /// Whether the button is shown only after checking the app is installed.
  bool get needsInstalledApp => installedProbe != null;

  /// A link only the installed app handles, used to check it is there.
  Uri? get installedProbe => switch (this) {
    ReelShareTarget.whatsApp => Uri.parse('whatsapp://send'),
    ReelShareTarget.viber => Uri.parse('viber://forward'),
    ReelShareTarget.facebook || ReelShareTarget.messages => null,
  };

  /// The link that opens this app with [message] (which contains [link]).
  Uri uri({required Uri link, required String message}) {
    final text = Uri.encodeComponent(message);
    return switch (this) {
      ReelShareTarget.whatsApp => Uri.parse('https://wa.me/?text=$text'),
      ReelShareTarget.facebook => Uri.parse(
        'https://www.facebook.com/sharer/sharer.php'
        '?u=${Uri.encodeComponent(link.toString())}',
      ),
      ReelShareTarget.viber => Uri.parse('viber://forward?text=$text'),
      ReelShareTarget.messages => Uri.parse('sms:?body=$text'),
    };
  }
}
