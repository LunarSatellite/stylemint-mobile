import 'package:stylemint_mobile_frontend/shared/domain/reel_caption/reel_caption.dart';

/// What sharing a reel sends: a StyleMint link, never the source platform's.
///
/// Pure Dart. The Android app claims `https://<origin>/reels/*` as an App
/// Link (AndroidManifest.xml), so the link opens the reel in StyleMint.
abstract final class ReelShare {
  /// Web origin of StyleMint share links.
  static const origin = String.fromEnvironment(
    'SHARE_WEB_ORIGIN',
    defaultValue: 'https://stylemint.voyageritnepal.com',
  );

  static const int _hookMaxLength = 120;
  static final RegExp _link = RegExp(
    r'(https?://|www\.)\S+',
    caseSensitive: false,
  );
  static final RegExp _whitespace = RegExp(r'\s+');

  /// `https://<origin>/reels/{reelId}`.
  static Uri link(String reelId) =>
      Uri.parse('$origin/reels/${Uri.encodeComponent(reelId)}');

  /// The caption's hook line, then an invitation naming the creator with the
  /// StyleMint link.
  static String text({
    required String reelId,
    required String caption,
    required String creatorName,
  }) {
    final hook = hookLine(caption);
    final name = creatorName.trim();
    final invite = name.isEmpty
        ? 'Watch this reel on StyleMint'
        : "Watch $name's reel on StyleMint";
    final line = '$invite: ${link(reelId)}';
    return hook.isEmpty ? line : '$hook\n\n$line';
  }

  /// The caption's first line ([ReelCaption.parse]) without hashtags or links
  /// (a platform caption can carry its own URLs), shortened if very long.
  static String hookLine(String caption) {
    final hook = ReelCaption.parse(caption).hook
        .replaceAll(_link, '')
        .replaceAll(_whitespace, ' ')
        .trim();
    final runes = hook.runes;
    if (runes.length <= _hookMaxLength) return hook;
    final cut = String.fromCharCodes(runes.take(_hookMaxLength - 1));
    return '${cut.trimRight()}…';
  }
}
