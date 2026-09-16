import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/home_mode.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/home_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/mall_home_page.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_home_skeleton.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../mall_test_support.dart';

final _home = GoRoute(path: '/home', builder: (_, _) => const HomeScreen());

List<Object> _overrides(FakeMallHomeRepository repo) => [
  mallHomeRepositoryProvider.overrideWithValue(repo),
  mallViewerSignedInProvider.overrideWithValue(false),
  mallClockProvider.overrideWithValue(mallTestNow),
];

Future<FakeMallHomeRepository> _pump(
  WidgetTester tester, {
  Either<NetworkExceptions, MallHome>? result,
  List<Either<NetworkExceptions, MallHome>>? results,
  double width = 390,
  double? height,
  double textScale = 1,
}) async {
  final repo = FakeMallHomeRepository(
    results ?? [result ?? right(sampleHome())],
  );
  await pumpMallApp(
    tester,
    location: '/home',
    routes: [_home],
    overrides: _overrides(repo),
    width: width,
    height: height,
    textScale: textScale,
  );
  return repo;
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));

void main() {
  group('zones', () {
    testWidgets('every zone renders from the server payload, in order', (
      tester,
    ) async {
      await _pump(tester, height: 6000);

      // Cinematic, bold retail, graphic, editorial, and the closing strip.
      expect(find.byType(MallCinematicHero), findsOneWidget);
      expect(find.byType(MallDealBand), findsOneWidget);
      expect(find.byType(MallCategoryMosaic), findsOneWidget);
      expect(find.byType(MallEditorialSpread), findsOneWidget);
      expect(find.byType(MallTrustStrip), findsOneWidget);

      expect(find.text('Good evening, Sumendra'), findsOneWidget);
      for (final text in [
        'Dubai Evening Edit',
        'Picked for you',
        'Because you follow Stylemint Nepal',
        'Linen co-ord set',
        'Shoppable reels',
        'Priya',
        'Aarav',
        'Silk scarf',
        'Fashion',
        'Stylemint Nepal',
        'Sumi Rai',
        'Minimal workwear',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }

      final tops = [
        'Picked for you',
        'Shoppable reels',
        'Deals',
        'Shop by category',
        'Brands we love',
        'Creators to follow',
        'The edits',
      ].map((title) => tester.getTopLeft(find.text(title)).dy).toList();
      expect(tops, [...tops]..sort());
      expect(tester.takeException(), isNull);
    });

    testWidgets('section markers number the blocks that show one, with no '
        'gaps', (tester) async {
      await _pump(tester, height: 6000);
      // Picked for you is 01, Shoppable reels 02; the full-bleed drop plate
      // takes no number, so Shop by category is 03 rather than 04.
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('03')).dy,
        greaterThan(tester.getTopLeft(find.text('Deals')).dy),
      );
    });

    testWidgets('labels AI reels, and only AI reels', (tester) async {
      await _pump(tester, height: 6000);
      expect(find.text('AI-generated'), findsOneWidget);
    });
  });

  group('live signals', () {
    testWidgets('cards carry only facts the payload actually contains', (
      tester,
    ) async {
      await _pump(tester, height: 6000);
      // p-1 has a rating and 12 ratings behind it.
      expect(find.text('12 reviews'), findsOneWidget);
      // p-2 is low stock, which the contract defines without a count.
      expect(find.text('Only a few left'), findsOneWidget);
      // p-3's sale really does end today in Kathmandu.
      expect(find.text('Ends today'), findsOneWidget);
    });

    testWidgets('the drop plate shows the real best discount and deadline', (
      tester,
    ) async {
      await _pump(tester, height: 6000);
      // p-4 is 1500 from 3000.
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('UP TO'), findsOneWidget);
      // mallTestNow is 13:00 UTC; the sale ends at 17:30 UTC.
      expect(find.text('Ends in 4h 30m'), findsOneWidget);
    });

    testWidgets('section meta counts what is there', (tester) async {
      await _pump(tester, height: 6000);
      expect(find.text('2 picks'), findsOneWidget);
      expect(find.text('2 products tagged'), findsOneWidget);
      expect(find.text('1 verified'), findsOneWidget);
      expect(find.text('26 pieces'), findsOneWidget);
    });

    testWidgets('a payload with no signals shows no signal copy', (
      tester,
    ) async {
      await _pump(
        tester,
        result: right(
          MallHome(
            sections: [
              HomeProductsSection(
                id: 'plain',
                title: 'Plain',
                items: [homeProduct('p-9')],
              ),
            ],
          ),
        ),
      );
      expect(find.text('Plain'), findsOneWidget);
      expect(find.textContaining('reviews'), findsNothing);
      expect(find.textContaining('Ends'), findsNothing);
      expect(find.text('Only a few left'), findsNothing);
      // Nothing is discounted, so no drop plate and no discount claim.
      expect(find.byType(MallDealBand), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });
  });

  testWidgets('no greeting when anonymous', (tester) async {
    await _pump(tester, result: right(sampleHome(firstName: null)));
    expect(find.textContaining('Good evening'), findsNothing);
  });

  group('states', () {
    testWidgets('shows skeletons while loading', (tester) async {
      final gate = Completer<void>();
      final repo = FakeMallHomeRepository([right(sampleHome())])..gate = gate;
      await pumpMallApp(
        tester,
        location: '/home',
        routes: [_home],
        overrides: _overrides(repo),
      );

      expect(find.byType(MallHomeSkeleton), findsOneWidget);
      expect(find.byType(SmSkeletonProductCard), findsWidgets);

      gate.complete();
      await tester.pump();
      await tester.pump();
      expect(find.byType(MallHomeSkeleton), findsNothing);
      expect(find.text('Picked for you'), findsOneWidget);
    });

    testWidgets('an error is a designed state that retries', (tester) async {
      final repo = await _pump(
        tester,
        results: [
          left(const NetworkExceptions.serverUnavailable()),
          right(sampleHome()),
        ],
      );
      expect(find.text("We couldn't open the Mall"), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(repo.homeCalls, 2);
      expect(find.text('Picked for you'), findsOneWidget);
    });

    testWidgets('offline has its own state, not the generic error', (
      tester,
    ) async {
      await _pump(
        tester,
        result: left(const NetworkExceptions.noInternetConnection()),
      );
      expect(find.text('The Mall is waiting for you'), findsOneWidget);
      expect(find.text('Offline'.toUpperCase()), findsOneWidget);
      expect(find.text("We couldn't open the Mall"), findsNothing);
    });

    testWidgets('an empty page shows the empty state', (tester) async {
      await _pump(tester, result: right(const MallHome(sections: [])));
      expect(find.text('The Mall is getting ready'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });
  });

  testWidgets('Home re-tap refreshes the Mall', (tester) async {
    final repo = await _pump(tester);
    _container(tester).read(mallHomeReselectedProvider.notifier).state++;
    await tester.pump();
    await tester.pump();
    expect(repo.homeCalls, 2);
  });

  group('navigation', () {
    testWidgets('a product opens its detail page', (tester) async {
      await _pump(tester, height: 6000);
      // Cards are one tap overlay above their text.
      await tester.tap(find.text('Linen co-ord set'), warnIfMissed: false);
      await settleTransition(tester);
      expect(find.text('product:p-1'), findsOneWidget);
    });

    testWidgets('a reel opens the landing pager', (tester) async {
      await _pump(tester, height: 6000);
      await tester.tap(find.text('Aarav'), warnIfMissed: false);
      await settleTransition(tester);
      expect(find.text('reel:r-human'), findsOneWidget);
    });

    testWidgets('a brand opens its storefront', (tester) async {
      await _pump(tester, height: 6000);
      await tester.tap(find.text('Stylemint Nepal'), warnIfMissed: false);
      await settleTransition(tester);
      expect(find.textContaining('/brands/v-1'), findsOneWidget);
    });

    testWidgets('a category opens its listing', (tester) async {
      await _pump(tester, height: 6000);
      await tester.tap(find.text('Fashion'), warnIfMissed: false);
      await settleTransition(tester);
      expect(find.textContaining('categorySlug=fashion'), findsOneWidget);
    });

    testWidgets('a collection opens from the editorial spread', (tester) async {
      await _pump(tester, height: 6000);
      await tester.tap(find.text('Monsoon layers'), warnIfMissed: false);
      await settleTransition(tester);
      expect(find.text('collection:monsoon-layers'), findsOneWidget);
    });

    testWidgets('the drop plate opens the sale listing', (tester) async {
      await _pump(tester, height: 6000);
      await tester.tap(find.text('Shop the drop'));
      await settleTransition(tester);
      expect(find.textContaining('onSale=true'), findsOneWidget);
    });

    testWidgets('See all opens the listing with the section query', (
      tester,
    ) async {
      await _pump(tester, height: 6000);
      await tester.tap(find.bySemanticsLabel('See all, Picked for you'));
      await settleTransition(tester);
      expect(find.textContaining('sort=bestselling'), findsOneWidget);
    });

    testWidgets('the campaign CTA flies into its collection', (tester) async {
      await _pump(tester, height: 6000);
      // The hero tags its artwork, so the push carries the flight.
      expect(find.byType(Hero), findsWidgets);
      await tester.tap(find.text('Shop the edit'));
      await settleTransition(tester);
      expect(find.text('collection:dubai-evening-edit'), findsOneWidget);
    });

    testWidgets('the Reels campaign CTA switches Home to Reels', (
      tester,
    ) async {
      await _pump(tester, height: 6000);
      expect(_container(tester).read(homeModeProvider), HomeMode.mall);
      await tester.tap(find.text('Watch reels'));
      await tester.pump();
      expect(_container(tester).read(homeModeProvider), HomeMode.reels);
    });
  });

  group('layout', () {
    for (final width in [320.0, 390.0]) {
      testWidgets('page fits at ${width.toInt()}dp, text ×1.3', (
        tester,
      ) async {
        await _pump(tester, width: width, textScale: 1.3);
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 12; i++) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -500),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('skeleton fits at ${width.toInt()}dp, text ×1.3', (
        tester,
      ) async {
        final repo = FakeMallHomeRepository([right(sampleHome())])
          ..gate = Completer<void>();
        await pumpMallApp(
          tester,
          location: '/home',
          routes: [_home],
          overrides: _overrides(repo),
          width: width,
          textScale: 1.3,
        );
        expect(find.byType(MallHomeSkeleton), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('states fit at ${width.toInt()}dp, text ×1.3', (
        tester,
      ) async {
        await _pump(
          tester,
          result: left(const NetworkExceptions.noInternetConnection()),
          width: width,
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('MallHomePage works outside HomeScreen', (tester) async {
    final repo = FakeMallHomeRepository([right(sampleHome())]);
    await pumpMallApp(
      tester,
      location: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: MallHomePage()),
        ),
      ],
      overrides: _overrides(repo),
    );
    expect(find.text('Picked for you'), findsOneWidget);
  });
}
