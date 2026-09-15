import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

Widget _numberRail({int count = 12}) => MallRail<int>(
  items: List.generate(count, (i) => i),
  itemWidth: 140,
  height: 80,
  semanticLabel: 'Numbers',
  itemBuilder: (_, i, _) => ColoredBox(
    key: ValueKey('tile-$i'),
    color: const Color(0xFF333333),
    child: Center(child: Text('$i')),
  ),
);

ScrollPosition _railPosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(MallRail<int>),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

void main() {
  testMallLayouts('reel rail fits', (tester, width, scale) async {
    await pumpMall(
      tester,
      MallRail<MallReelVm>(
        items: const [aiReel, humanReel, aiReel, humanReel],
        itemWidth: MallReelCard.compactWidth,
        height: MallReelCard.heightFor(MallReelCard.compactWidth),
        semanticLabel: 'Trending reels',
        itemBuilder: (_, reel, _) => MallReelCard(reel: reel, onTap: () {}),
      ),
      width: width,
      textScale: scale,
    );
    expectNoLayoutErrors(tester);
    expect(find.byType(MallReelCard), findsWidgets);
  });

  testWidgets('names itself for assistive technology', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMall(tester, _numberRail());
    expect(find.bySemanticsLabel('Numbers'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('snaps an item edge to the leading padding after a fling', (
    tester,
  ) async {
    await pumpMall(tester, _numberRail());
    await tester.fling(
      find.byKey(const ValueKey('tile-1')),
      const Offset(-230, 0),
      800,
    );
    await tester.pumpAndSettle();
    final position = _railPosition(tester);
    // itemWidth 140 + the rail's default 12dp spacing.
    const extent = 152.0;
    final remainder = position.pixels % extent;
    expect(position.pixels, greaterThan(0));
    expect(
      remainder < 0.5 ||
          extent - remainder < 0.5 ||
          position.pixels == position.maxScrollExtent,
      isTrue,
      reason: 'settled at ${position.pixels}',
    );
  });

  testWidgets('loading: skeletons, no scrolling, announced as loading', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMall(
      tester,
      MallRail<MallReelVm>(
        items: const [],
        isLoading: true,
        itemWidth: MallReelCard.compactWidth,
        height: MallReelCard.heightFor(MallReelCard.compactWidth),
        semanticLabel: 'Trending reels',
        skeletonBuilder: (_, _) =>
            const SmSkeletonReelCard(width: MallReelCard.compactWidth),
        itemBuilder: (_, reel, _) => MallReelCard(reel: reel),
      ),
    );
    expectNoLayoutErrors(tester);
    expect(find.byType(SmSkeletonReelCard), findsWidgets);
    expect(find.byType(MallReelCard), findsNothing);
    expect(find.bySemanticsLabel('Trending reels, Loading'), findsOneWidget);
    final scrollable = tester.widget<Scrollable>(
      find.descendant(
        of: find.byType(MallRail<MallReelVm>),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.physics, isA<NeverScrollableScrollPhysics>());
    semantics.dispose();
  });

  testWidgets('empty: shows the empty-state slot, or nothing', (tester) async {
    await pumpMall(
      tester,
      Column(
        children: [
          MallRail<int>(
            items: const [],
            itemWidth: 140,
            height: 80,
            semanticLabel: 'Numbers',
            emptyState: const Text('Nothing here yet'),
            itemBuilder: (_, i, _) => Text('$i'),
          ),
          MallRail<int>(
            items: const [],
            itemWidth: 140,
            height: 80,
            semanticLabel: 'Numbers',
            itemBuilder: (_, i, _) => Text('$i'),
          ),
        ],
      ),
    );
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MallRail<int>),
        matching: find.byType(ListView),
      ),
      findsNothing,
    );
  });

  testWidgets('RTL starts at the right-hand gutter', (tester) async {
    await pumpMall(
      tester,
      _numberRail(count: 3),
      textDirection: TextDirection.rtl,
    );
    final first = tester.getRect(find.byKey(const ValueKey('tile-0')));
    expect(first.right, closeTo(390 - 16, 0.5));
  });
}
