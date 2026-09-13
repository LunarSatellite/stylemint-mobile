import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_layout_policy.dart';

void main() {
  test('a YouTube player spans the page width with the action bar below it', () {
    const page = Size(360, 688);
    final bar = EmbedLayoutPolicy.panelHeight();
    final player = EmbedLayoutPolicy.playerRect(
      platform: SocialPlatform.youtube,
      page: page,
      topInset: 40,
      panelHeight: bar,
    );
    final barRect = Rect.fromLTRB(0, player.bottom, page.width, page.height);

    expect(player.width, page.width);
    expect(player.height, page.height - 40 - EmbedLayoutPolicy.compactBarHeight);
    expect(player.overlaps(barRect), isFalse);
    expect(barRect.height, bar);
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

  test('a YouTube player never drops below 200x200 on a small screen', () {
    final player = EmbedLayoutPolicy.playerRect(
      platform: SocialPlatform.youtube,
      page: const Size(180, 250),
      topInset: 24,
      panelHeight: EmbedLayoutPolicy.panelHeight(),
    );
    expect(player.size, const Size(200, 200));
  });

  test('TikTok and Facebook reels play full-bleed', () {
    const page = Size(360, 700);
    for (final platform in [SocialPlatform.tiktok, SocialPlatform.facebook]) {
      expect(
        EmbedLayoutPolicy.playerRect(
          platform: platform,
          page: page,
          topInset: 24,
          panelHeight: 240,
        ),
        Offset.zero & page,
      );
    }
  });
}
