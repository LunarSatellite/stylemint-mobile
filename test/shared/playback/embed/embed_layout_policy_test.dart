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

  test('on a shorter page a Short keeps the page height instead of cropping', () {
    expect(shortOn(const Size(360, 600)), const Rect.fromLTWH(0, 0, 360, 600));
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
    final rail = Rect.fromLTRB(player.right, player.top, page.width, player.bottom);

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
}
