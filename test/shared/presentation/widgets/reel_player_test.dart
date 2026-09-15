import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_poster.dart';

/// A reel that cannot play in StyleMint: no embeddable video id (TikTok), or
/// no official media URL (Instagram).
class _UnplayableReel implements ReelMedia {
  const _UnplayableReel(this.platform, this.permalink);

  @override
  final SocialPlatform platform;

  @override
  final String permalink;

  @override
  String? get platformVideoId => null;

  @override
  String? get thumbnailUrl => null;

  @override
  String? get videoUrl =>
      platform == SocialPlatform.instagram ? null : 'legacy-provider-metadata';
}

void main() {
  const reels = [
    _UnplayableReel(
      SocialPlatform.tiktok,
      'https://www.tiktok.com/@stylemint/video/123',
    ),
    _UnplayableReel(
      SocialPlatform.instagram,
      'https://www.instagram.com/reel/abc/',
    ),
  ];

  for (final reel in reels) {
    testWidgets(
      'a ${reel.platform.displayName} reel that cannot play shows the poster '
      'and a note, with no way out of StyleMint',
      (tester) async {
        final playback = ReelPlaybackController();
        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 320,
              height: 560,
              child: ReelPlayer(
                reel: reel,
                isActive: true,
                playbackController: playback,
              ),
            ),
          ),
        );

        final player = find.byType(ReelPlayer);
        expect(find.byType(ReelPoster), findsOneWidget);
        expect(find.text(ReelPlayer.unavailableMessage), findsOneWidget);
        expect(find.textContaining('Watch on'), findsNothing);
        expect(find.byIcon(Icons.open_in_new_rounded), findsNothing);
        expect(
          find.descendant(of: player, matching: find.byType(ButtonStyleButton)),
          findsNothing,
        );
        expect(
          find.descendant(of: player, matching: find.byType(GestureDetector)),
          findsNothing,
        );
        expect(find.bySemanticsLabel(RegExp('Open reel')), findsNothing);

        // The feed's tap layer toggles through the controller: a no-op here.
        playback.toggle();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text(ReelPlayer.unavailableMessage), findsOneWidget);
      },
    );
  }
}
