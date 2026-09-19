import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reels_pager.dart';

/// An Instagram reel with no media URL: it shows its poster, so no video or
/// WebView platform is needed.
Reel _reel(String id) => Reel(
  id: id,
  sourceUrl: 'https://www.instagram.com/reel/$id/',
  thumbnailUrl: '',
  creatorId: 'creator-$id',
  creatorName: 'Creator $id',
  creatorAvatarUrl: '',
  caption: '',
  musicTitle: '',
  musicArtist: '',
  taggedProducts: const [],
  likeCount: 0,
  commentCount: 0,
  shareCount: 0,
  createdAt: DateTime(2026, 9, 15),
);

void main() {
  setUp(() => ReelsPager.debugHostEmbedPlayers = false);
  tearDown(() => ReelsPager.debugHostEmbedPlayers = true);

  /// A clock the test moves by hand, so a dwell is a decision and not a race.
  late DateTime now;
  late List<(String, Duration)> dwells;
  late ReelsPagerController controller;

  Future<void> pump(WidgetTester tester) async {
    now = DateTime(2026, 9, 15, 12);
    dwells = [];
    controller = ReelsPagerController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReelsPager(
            controller: controller,
            reels: [_reel('r-1'), _reel('r-2'), _reel('r-3')],
            clock: () => now,
            onReelDwell: (reel, dwell) => dwells.add((reel.id, dwell)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> swipe(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(0, -600));
    await tester.pumpAndSettle();
  }

  testWidgets('reports one dwell per reel left, not one per frame', (
    tester,
  ) async {
    await pump(tester);

    // Scrolling within the first reel reports nothing.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(dwells, isEmpty);

    now = now.add(const Duration(seconds: 7));
    await swipe(tester);
    expect(dwells, [('r-1', const Duration(seconds: 7))]);

    now = now.add(const Duration(milliseconds: 300));
    await swipe(tester);
    expect(dwells.last, ('r-2', const Duration(milliseconds: 300)));
    expect(dwells, hasLength(2));
  });

  testWidgets('the reel on screen when the feed closes still counts', (
    tester,
  ) async {
    await pump(tester);
    now = now.add(const Duration(seconds: 12));
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SizedBox.shrink())),
    );
    await tester.pumpAndSettle();
    expect(dwells, [('r-1', const Duration(seconds: 12))]);
  });
}
