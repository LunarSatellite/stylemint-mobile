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
  testWidgets('renders every section kind in server order', (tester) async {
    await _pump(tester, height: 6000);

    expect(find.text('Good evening, Sumendra'), findsOneWidget);
    expect(find.byType(MallCampaignHero), findsOneWidget);
    expect(find.byType(MallTrustStrip), findsOneWidget);
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

  testWidgets('labels AI reels, and only AI reels', (tester) async {
    await _pump(tester, height: 6000);
    expect(find.text('AI-generated'), findsOneWidget);
  });

  testWidgets('no greeting when anonymous', (tester) async {
    await _pump(tester, result: right(sampleHome(firstName: null)));
    expect(find.textContaining('Good evening'), findsNothing);
  });

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

  testWidgets('error view retries', (tester) async {
    final repo = await _pump(
      tester,
      results: [
        left(const NetworkExceptions.serverUnavailable()),
        right(sampleHome()),
      ],
    );
    expect(
      find.text("We couldn't load the Mall. Please try again."),
      findsOneWidget,
    );

    await tester.tap(find.text('Tap to retry'));
    await tester.pump();
    await tester.pump();
    expect(repo.homeCalls, 2);
    expect(find.text('Picked for you'), findsOneWidget);
  });

  testWidgets('says when there is no internet', (tester) async {
    await _pump(
      tester,
      result: left(const NetworkExceptions.noInternetConnection()),
    );
    expect(find.textContaining('No internet connection'), findsOneWidget);
  });

  testWidgets('an empty page shows the empty state', (tester) async {
    await _pump(tester, result: right(const MallHome(sections: [])));
    expect(find.text('The Mall is getting ready'), findsOneWidget);
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

    testWidgets('a brand opens its product listing', (tester) async {
      await _pump(tester, height: 6000);
      await tester.tap(find.text('Stylemint Nepal'), warnIfMissed: false);
      await settleTransition(tester);
      expect(find.textContaining('vendorAccountId=v-1'), findsOneWidget);
    });

    testWidgets('See all opens the listing with the section query', (
      tester,
    ) async {
      await _pump(tester, height: 6000);
      await tester.tap(find.bySemanticsLabel('See all, Picked for you'));
      await settleTransition(tester);
      expect(find.textContaining('sort=bestselling'), findsOneWidget);
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
