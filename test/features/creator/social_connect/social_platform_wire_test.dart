import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// Locks the backend wire contract for reel source platforms.
///
/// This regressed silently once already: the Discovery feed sends
/// `.ToString()` of the C# `ReelSourcePlatform` enum — PascalCase, and
/// `"YouTubeShorts"` rather than `"YouTube"` — while the parser compared it
/// against `SocialPlatform.<name>`, which is lowercase. Every comparison
/// failed and every reel silently fell back to Instagram, so YouTube reels
/// were handed to the mp4 player and TikTok/Facebook never offered their
/// "Watch on ..." button. Nothing threw, so nothing surfaced it.
void main() {
  group('SocialPlatform.tryParseWire', () {
    test('parses the int form sent by ReelDto.sourcePlatform', () {
      expect(SocialPlatform.tryParseWire(1), SocialPlatform.instagram);
      expect(SocialPlatform.tryParseWire(2), SocialPlatform.tiktok);
      expect(SocialPlatform.tryParseWire(3), SocialPlatform.youtube);
      expect(SocialPlatform.tryParseWire(4), SocialPlatform.facebook);
    });

    test('parses the PascalCase strings sent by the Discovery feed', () {
      expect(SocialPlatform.tryParseWire('Instagram'), SocialPlatform.instagram);
      expect(SocialPlatform.tryParseWire('TikTok'), SocialPlatform.tiktok);
      expect(SocialPlatform.tryParseWire('Facebook'), SocialPlatform.facebook);
    });

    test('maps YouTubeShorts to youtube — the case that silently broke', () {
      expect(
        SocialPlatform.tryParseWire('YouTubeShorts'),
        SocialPlatform.youtube,
      );
    });

    test('tolerates casing and separator drift', () {
      for (final raw in ['youtube_shorts', 'YouTube Shorts', 'YOUTUBE']) {
        expect(
          SocialPlatform.tryParseWire(raw),
          SocialPlatform.youtube,
          reason: '"$raw" should resolve to youtube',
        );
      }
      expect(SocialPlatform.tryParseWire('tiktok'), SocialPlatform.tiktok);
    });

    test('accepts numeric strings', () {
      expect(SocialPlatform.tryParseWire('3'), SocialPlatform.youtube);
    });

    test('returns null for absent or unrecognised values so the caller '
        'picks the fallback instead of inheriting a wrong one', () {
      expect(SocialPlatform.tryParseWire(null), isNull);
      expect(SocialPlatform.tryParseWire(''), isNull);
      expect(SocialPlatform.tryParseWire('  '), isNull);
      expect(SocialPlatform.tryParseWire('Vimeo'), isNull);
      expect(SocialPlatform.tryParseWire(0), isNull);
      expect(SocialPlatform.tryParseWire(9), isNull);
      expect(SocialPlatform.tryParseWire(const Object()), isNull);
    });

    test('int codes follow the backend contract, not enum order', () {
      // The old mapping was values[provider - 1], which silently remapped
      // every account if a member was ever reordered. These expectations
      // are pinned to ReelSourcePlatform in the backend.
      expect(SocialPlatform.tryParseWire(3), SocialPlatform.youtube);
      expect(SocialPlatform.tryParseWire(2), SocialPlatform.tiktok);
    });
  });
}
