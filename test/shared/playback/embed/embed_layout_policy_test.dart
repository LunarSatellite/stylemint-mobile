import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_layout_policy.dart';

void main() {
  Rect shortOn(Size page) => EmbedLayoutPolicy.playerRect(
    platform: SocialPlatform.youtube,
    page: page,
    aspectRatio: EmbedLayoutPolicy.shortsAspectRatio,
  );

  test('a Short fills the page width at its own shape, from the top', () {
    expect(shortOn(const Size(360, 688)), const Rect.fromLTWH(0, 0, 360, 640));
  });

  test(
    'on a shorter page a Short keeps the page height instead of cropping',
    () {
      expect(
        shortOn(const Size(360, 600)),
        const Rect.fromLTWH(0, 0, 360, 600),
      );
    },
  );

  test('vertical reels fill the screen; square and landscape show whole', () {
    expect(EmbedLayoutPolicy.fillsScreen(9 / 16), isTrue);
    expect(EmbedLayoutPolicy.fillsScreen(3 / 4), isTrue);
    expect(EmbedLayoutPolicy.fillsScreen(1), isFalse);
    expect(EmbedLayoutPolicy.fillsScreen(16 / 9), isFalse);
  });

  group('coverRect fills the page with no bars', () {
    const page = Size(360, 688);

    test('a Short covers the full height and is trimmed at the sides', () {
      final player = EmbedLayoutPolicy.coverRect(
        page: page,
        aspectRatio: EmbedLayoutPolicy.shortsAspectRatio,
      );

      expect(player.top, 0);
      expect(player.height, 688);
      expect(player.width, closeTo(387, 0.01));
      expect(player.left, closeTo(-13.5, 0.01));
      expect(player.center.dx, closeTo(page.width / 2, 0.01));
    });

    test('a landscape video still covers the whole page', () {
      final player = EmbedLayoutPolicy.coverRect(
        page: page,
        aspectRatio: 16 / 9,
      );

      expect(player.height, 688);
      expect(player.contains(Offset.zero), isTrue);
      expect(player.left <= 0 && player.right >= page.width, isTrue);
    });

    test('on a page wider than the video the top and bottom are trimmed', () {
      final player = EmbedLayoutPolicy.coverRect(
        page: const Size(400, 600),
        aspectRatio: EmbedLayoutPolicy.shortsAspectRatio,
      );

      expect(player.width, 400);
      expect(player.height, closeTo(711.11, 0.01));
      expect(player.top, closeTo(-55.56, 0.01));
    });
  });

  test('a stats rail beside a YouTube player stays outside it', () {
    const page = Size(360, 688);
    final player = EmbedLayoutPolicy.playerRect(
      platform: SocialPlatform.youtube,
      page: page,
      topInset: 96,
      panelHeight: 176,
      rightInset: EmbedLayoutPolicy.railWidth,
    );
    final rail = Rect.fromLTRB(
      player.right,
      player.top,
      page.width,
      player.bottom,
    );

    expect(rail.width, EmbedLayoutPolicy.railWidth);
    expect(player.overlaps(rail), isFalse);
  });

  test('a YouTube player never drops below 200x200', () {
    final player = EmbedLayoutPolicy.playerRect(
      platform: SocialPlatform.youtube,
      page: const Size(180, 250),
      topInset: 24,
      panelHeight: 64,
    );
    expect(player.size, const Size(200, 200));
  });

  test('TikTok and Facebook players fill the page', () {
    const page = Size(360, 700);
    for (final platform in [SocialPlatform.tiktok, SocialPlatform.facebook]) {
      expect(
        EmbedLayoutPolicy.playerRect(
          platform: platform,
          page: page,
          aspectRatio: EmbedLayoutPolicy.shortsAspectRatio,
        ),
        Offset.zero & page,
      );
    }
  });

  group('a TikTok player keeps below the status bar', () {
    test('only TikTok draws a header along its top edge', () {
      expect(
        EmbedLayoutPolicy.keepsClearOfStatusBar(SocialPlatform.tiktok),
        isTrue,
      );
      for (final platform in [
        SocialPlatform.youtube,
        SocialPlatform.facebook,
        SocialPlatform.instagram,
      ]) {
        expect(EmbedLayoutPolicy.keepsClearOfStatusBar(platform), isFalse);
      }
    });

    test('it covers the page below the status bar down to the bottom', () {
      const page = Size(360, 780);
      final player = EmbedLayoutPolicy.coverRectBelow(
        page: page,
        aspectRatio: EmbedLayoutPolicy.shortsAspectRatio,
        topInset: 24,
      );

      expect(player.top, 24);
      expect(player.bottom, closeTo(780, 0.01));
      expect(player.left <= 0 && player.right >= page.width, isTrue);
    });

    test('on a wide page it is trimmed at the bottom, never above the bar', () {
      final player = EmbedLayoutPolicy.coverRectBelow(
        page: const Size(600, 800),
        aspectRatio: EmbedLayoutPolicy.shortsAspectRatio,
        topInset: 24,
      );

      expect(player.top, 24);
      expect(player.width, 600);
      expect(player.bottom, greaterThan(800));
    });
  });
}
