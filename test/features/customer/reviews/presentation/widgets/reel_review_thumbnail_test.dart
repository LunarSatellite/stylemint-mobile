import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/reel_review_thumbnail.dart';
import 'package:stylemint_mobile_frontend/shared/playback/linked_reel.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_playback_sheet.dart';

Review _review({required String? url, String? platform}) => Review(
  id: 'review-1',
  userId: 'user-1',
  userName: 'Asha',
  userAvatarUrl: '',
  rating: 5,
  comment: '',
  createdAt: DateTime(2026, 9, 14),
  images: const [],
  helpfulCount: 0,
  kind: ReviewKind.reel,
  reelPlatform: platform,
  reelSourceUrl: url,
);

void main() {
  late List<LinkedReel> played;

  setUp(() => played = []);

  Future<void> pumpTile(WidgetTester tester, Review review) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 120,
                child: ReelReviewThumbnail(
                  review: review,
                  onPlay: (_, reel) => played.add(reel),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('a playable reel review plays in StyleMint when tapped', (
    tester,
  ) async {
    await pumpTile(
      tester,
      _review(
        url: 'https://www.tiktok.com/@scout2015/video/6718335390845095173',
        platform: '2',
      ),
    );

    expect(find.text('TikTok'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline_rounded), findsOneWidget);
    await tester.tap(find.byType(ReelReviewThumbnail));

    expect(played, hasLength(1));
    expect(played.single.platform, SocialPlatform.tiktok);
    expect(played.single.platformVideoId, '6718335390845095173');
  });

  testWidgets('a reel that cannot play here is not tappable', (tester) async {
    await pumpTile(
      tester,
      _review(url: 'https://www.instagram.com/reel/C8abc/', platform: '1'),
    );

    expect(find.text('Instagram'), findsOneWidget);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    await tester.tap(find.byType(ReelReviewThumbnail));
    expect(played, isEmpty);
  });

  testWidgets('a link without a readable video id is not tappable', (
    tester,
  ) async {
    await pumpTile(
      tester,
      _review(url: 'https://vm.tiktok.com/ZMabc/', platform: 'TikTok'),
    );

    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    expect(find.byIcon(Icons.play_circle_outline_rounded), findsNothing);
  });

  testWidgets('the playback sheet plays the reel in-app and closes', (
    tester,
  ) async {
    const reel = LinkedReel(
      platform: SocialPlatform.youtube,
      permalink: 'https://youtube.com/shorts/39bix0Z0NOQ',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ReelPlaybackSheet(
                  reel: reel,
                  player: ColoredBox(
                    key: ValueKey('player'),
                    color: Colors.black,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('YouTube reel'), findsOneWidget);
    expect(find.byKey(const ValueKey('player')), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(ReelPlaybackSheet), findsNothing);
  });
}
