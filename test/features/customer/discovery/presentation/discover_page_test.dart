import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_item_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../../mall_home/mall_test_support.dart';
import '../../reels/fake_reels_repository.dart';
import '../discover_test_support.dart';

const ValueKey<String> _field = ValueKey('discover-search-field');

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _openMore(WidgetTester tester, String cardKey) async {
  await tester.tap(
    find.descendant(
      of: _key(cardKey),
      matching: find.byType(DiscoverMoreButton),
    ),
  );
  await settleTransition(tester);
}

Future<void> _selectChip(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key('discover-chip-$key'));
  await tester.pump();
  await tester.tap(_key('discover-chip-$key'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('typing shows grouped suggestions that open their pages', (
    tester,
  ) async {
    final discover = FakeDiscoverRepository(
      onSuggest: (query) => right(sampleSuggestions(query)),
    );
    await pumpDiscover(tester, discover: discover);

    await tester.enterText(find.byKey(_field), 'glow');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(discover.suggestCalls, ['glow']);
    for (final group in [
      'PRODUCTS',
      'BRANDS',
      'CREATORS',
      'CATEGORIES',
      'HASHTAGS',
    ]) {
      expect(find.text(group), findsOneWidget, reason: group);
    }
    expect(find.text('@glowwithasha'), findsOneWidget);
    expect(find.text('#glowup'), findsOneWidget);
    expect(find.text('42 posts'), findsOneWidget);

    await tester.tap(_key('suggest-brand-v-9'));
    await settleTransition(tester);
    expect(find.text('brand:v-9'), findsOneWidget);
  });

  testWidgets('recent searches show on an empty field; submit opens results', (
    tester,
  ) async {
    final recents = MemoryRecentSearchesStore(['linen']);
    await pumpDiscover(tester, recents: recents);

    await tester.tap(find.byKey(_field));
    await tester.pump();
    await tester.pump();
    expect(find.text('linen'), findsOneWidget);

    await tester.tap(_key('discover-recent-clear'));
    await tester.pump();
    expect(find.text('linen'), findsNothing);
    expect(recents.saved, isEmpty);

    await tester.enterText(find.byKey(_field), 'silk scarf');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settleTransition(tester);

    expect(find.text('results:silk scarf'), findsOneWidget);
    expect(recents.saved, ['silk scarf']);
  });

  testWidgets('chips switch the feed; product results toggle grid and list', (
    tester,
  ) async {
    await pumpDiscover(
      tester,
      catalog: FakeMallCatalogRepository(
        onProducts: (_) => right(productPage(['t-1', 't-2'])),
      ),
    );
    await tester.pump();

    expect(_key('discover-block-fy-products-0'), findsOneWidget);
    expect(find.text('Products'.toUpperCase()), findsWidgets);

    await _selectChip(tester, 'trending');
    expect(find.text('Bestselling right now'), findsOneWidget);
    expect(_key('discover-product-t-1'), findsOneWidget);
    expect(find.byType(MallProductCard), findsNWidgets(2));

    await tester.tap(_key('discover-layout-list'));
    await tester.pump();
    expect(find.byType(MallProductCard), findsNothing);
    expect(find.text('Product t-1'), findsOneWidget);
  });

  testWidgets('Not interested hides a card at once; Undo brings it back', (
    tester,
  ) async {
    final discover = FakeDiscoverRepository();
    await pumpDiscover(tester, discover: discover);
    await tester.pump();
    expect(_key('discover-product-p-1'), findsOneWidget);

    await _openMore(tester, 'discover-product-p-1');
    await tester.tap(_key('discover-action-not-interested'));
    await settleTransition(tester);

    const target = NotInterestedTarget(NotInterestedKind.product, 'p-1');
    expect(_key('discover-product-p-1'), findsNothing);
    expect(discover.marked, [target]);
    expect(find.text('Product hidden'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump();

    expect(_key('discover-product-p-1'), findsOneWidget);
    expect(discover.undone, [target]);
  });

  testWidgets('signed-out viewers are asked to sign in; nothing is hidden', (
    tester,
  ) async {
    final discover = FakeDiscoverRepository();
    await pumpDiscover(tester, discover: discover, signedIn: false);
    await tester.pump();

    await tester.longPress(_key('discover-product-p-2'));
    await settleTransition(tester);
    await tester.tap(_key('discover-action-not-interested'));
    await settleTransition(tester);

    expect(discover.marked, isEmpty);
    expect(_key('discover-product-p-2'), findsOneWidget);
  });

  testWidgets('a reel in the For you rail plays in the window', (tester) async {
    addTearDown(ReelWindow.debugResetOpenState);
    await pumpDiscover(
      tester,
      // Tall enough that the For you feed lays its reels rail out.
      height: 2400,
      overrides: [
        reelsRepositoryProvider.overrideWithValue(FakeReelsRepository()),
      ],
    );
    await tester.pump();

    final card = _key('discover-reel-r-ai');
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card, warnIfMissed: false);
    await settleTransition(tester);

    expect(find.byType(ReelWindow), findsOneWidget);
    expect(find.byKey(ReelWindow.aiLabelKey), findsOneWidget);
    expect(find.text('reel:r-ai'), findsNothing);
  });

  // The Reels chip's block is the feed's own wall of reels, not a rail: it
  // pages as you scroll, so tapping one enters the full-screen pager and
  // keeps the swipe onward.
  testWidgets('the reels grid still opens the full-screen pager', (
    tester,
  ) async {
    await pumpDiscover(tester);
    await tester.pump();

    await _selectChip(tester, 'reels');
    final card = _key('discover-reel-r-ai');
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card, warnIfMissed: false);
    await settleTransition(tester);

    expect(find.text('reel:r-ai'), findsOneWidget);
    expect(find.byType(ReelWindow), findsNothing);
  });

  testWidgets('reels can be reported with a reason', (tester) async {
    final discover = FakeDiscoverRepository();
    await pumpDiscover(tester, discover: discover);
    await tester.pump();

    await _selectChip(tester, 'reels');
    await _openMore(tester, 'discover-reel-r-ai');
    await tester.tap(_key('discover-action-report'));
    await settleTransition(tester);
    await tester.tap(_key('discover-report-SPAM'));
    await settleTransition(tester);

    expect(discover.reported, [('r-ai', ReelReportReason.spam)]);
  });

  testWidgets('error with retry, offline and empty states', (tester) async {
    await pumpDiscover(
      tester,
      home: FakeMallHomeRepository([
        left(const NetworkExceptions.serverUnavailable()),
        right(sampleHome()),
      ]),
    );
    await tester.pump();
    expect(_key('discover-feed-error'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(_key('discover-block-fy-products-0'), findsOneWidget);

    // The catalog has nothing on sale.
    await _selectChip(tester, 'sale');
    expect(_key('discover-feed-empty'), findsOneWidget);
    expect(find.text('No sales right now'), findsOneWidget);
  });

  testWidgets('offline shows its own message', (tester) async {
    await pumpDiscover(
      tester,
      home: FakeMallHomeRepository([
        left(const NetworkExceptions.noInternetConnection()),
      ]),
    );
    await tester.pump();

    expect(_key('discover-feed-offline'), findsOneWidget);
    expect(find.text("You're offline"), findsOneWidget);
  });

  testWidgets('hero collapses while browsing and returns at the top', (
    tester,
  ) async {
    await pumpDiscover(tester);
    await tester.pump();

    final header = _key('discover-header-region');
    final expandedHeight = tester.getSize(header).height;
    expect(expandedHeight, greaterThan(100));

    await tester.drag(_key('discover-feed'), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.getSize(header).height, lessThan(1));

    await tester.drag(_key('discover-feed'), const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(tester.getSize(header).height, closeTo(expandedHeight, 1));
  });
  testWidgets('no overflow at 320dp with text scale 1.3', (tester) async {
    await pumpDiscover(
      tester,
      width: 320,
      textScale: 1.3,
      catalog: FakeMallCatalogRepository(
        onProducts: (_) => right(productPage(['t-1', 't-2', 't-3'])),
      ),
      discover: FakeDiscoverRepository(
        onSuggest: (query) => right(sampleSuggestions(query)),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.drag(_key('discover-feed'), const Offset(0, -2400));
    await tester.pump();
    expect(tester.takeException(), isNull);

    for (final chip in ['reels', 'creators', 'brands', 'trending']) {
      await _selectChip(tester, chip);
      expect(tester.takeException(), isNull, reason: chip);
    }
    await tester.tap(_key('discover-layout-list'));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await _openMore(tester, 'discover-product-t-1');
    expect(_key('discover-action-not-interested'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(10, 10));
    await settleTransition(tester);

    await tester.enterText(find.byKey(_field), 'glow');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('BRANDS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
