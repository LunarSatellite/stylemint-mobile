import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_layout_policy.dart';

void main() {
  test('a YouTube player gets its own rect with the rail and panel outside it', () {
    const page = Size(360, 700);
    final panel = EmbedLayoutPolicy.panelHeight(hasProducts: true);
    final player = EmbedLayoutPolicy.playerRect(
      platform: SocialPlatform.youtube,
      page: page,
      topInset: 24,
      panelHeight: panel,
    );
    final rail = Rect.fromLTRB(player.right, player.top, page.width, player.bottom);
    final panelRect = Rect.fromLTRB(0, player.bottom, page.width, page.height);

    expect(player.width, greaterThanOrEqualTo(200));
    expect(player.height, greaterThanOrEqualTo(200));
    expect(rail.width, EmbedLayoutPolicy.railWidth);
    expect(player.overlaps(rail), isFalse);
    expect(player.overlaps(panelRect), isFalse);
    expect(panelRect.height, panel);
  });

  test('a YouTube player never drops below 200x200 on a small screen', () {
    final player = EmbedLayoutPolicy.playerRect(
      platform: SocialPlatform.youtube,
      page: const Size(240, 380),
      topInset: 24,
      panelHeight: EmbedLayoutPolicy.panelHeight(hasProducts: true),
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
