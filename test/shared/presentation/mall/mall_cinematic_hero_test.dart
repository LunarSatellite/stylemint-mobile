import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

/// Lets a page animation and the copy cross-fade finish.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _hero({
  List<MallCampaignVm> campaigns = heroCampaigns,
  void Function(MallCampaignVm, MallCampaignAction)? onAction,
  ValueChanged<MallCampaignVm>? onReel,
  String? Function(MallCampaignVm)? heroTagFor,
  Widget? overline,
}) => MallCinematicHero(
  campaigns: campaigns,
  onAction: onAction ?? (_, _) {},
  onReel: onReel,
  heroTagFor: heroTagFor,
  overline: overline,
);

void main() {
  testMallLayouts('the stage fits, at its full height', (
    tester,
    width,
    scale,
  ) async {
    await pumpMall(tester, _hero(), width: width, textScale: scale);
    expectNoLayoutErrors(tester);
    final context = tester.element(find.byType(MallCinematicHero));
    expect(
      tester.getSize(find.byType(MallCinematicHero)).height,
      greaterThanOrEqualTo(MallCinematicHero.heightFor(context)),
    );
  });

  testWidgets('RTL at 320dp and ×1.3 fits', (tester) async {
    await pumpMall(
      tester,
      _hero(),
      width: 320,
      textScale: 1.3,
      textDirection: TextDirection.rtl,
    );
    expectNoLayoutErrors(tester);
  });

  testWidgets('height is about three quarters of the screen, clamped', (
    tester,
  ) async {
    Future<double> heightOn(double screenHeight) async {
      tester.view
        ..physicalSize = Size(390, screenHeight)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var height = 0.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              height = MallCinematicHero.heightFor(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return height;
    }

    expect(await heightOn(844), closeTo(844 * 0.72, 0.01));
    expect(await heightOn(500), MallCinematicHero.minHeight);
    expect(await heightOn(1400), MallCinematicHero.maxHeight);
  });

  testWidgets('the title is a header in the display face, closing on an '
      'italic word', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMall(tester, _hero());
    const title = 'Layers that move with the city';
    final text = tester.widget<Text>(find.text(title));
    expect(text.style?.fontFamily, 'InstrumentSerif');
    expect(tester.getSemantics(find.text(title)), isSemantics(isHeader: true));

    // The closing word carries the italic; the rest does not.
    final spans = <TextSpan>[];
    text.textSpan!.visitChildren((span) {
      if (span is TextSpan && span.text != null) spans.add(span);
      return true;
    });
    expect(spans.last.text, 'city');
    expect(spans.last.style?.fontStyle, FontStyle.italic);
    expect(spans.first.style?.fontStyle, isNot(FontStyle.italic));
    semantics.dispose();
  });

  testWidgets('a one-word title keeps its single span', (tester) async {
    await pumpMall(
      tester,
      _hero(
        campaigns: const [MallCampaignVm(id: 'k', title: 'Drop')],
      ),
    );
    expect(find.text('Drop'), findsOneWidget);
  });

  testWidgets('never blurs: the stage holds no BackdropFilter', (
    tester,
  ) async {
    await pumpMall(tester, _hero());
    expect(find.byType(MallPrimaryCta), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.byType(MallGlassCta), findsNothing);
  });

  testWidgets('CTAs report the campaign and action; at most three show', (
    tester,
  ) async {
    MallCampaignVm? campaign;
    MallCampaignAction? action;
    await pumpMall(
      tester,
      _hero(
        campaigns: const [
          MallCampaignVm(
            id: 'k-many',
            title: 'Too many actions',
            actions: [
              MallCampaignAction(id: 'a', label: 'One'),
              MallCampaignAction(id: 'b', label: 'Two'),
              MallCampaignAction(id: 'c', label: 'Three'),
              MallCampaignAction(id: 'd', label: 'Four'),
            ],
          ),
        ],
        onAction: (c, a) {
          campaign = c;
          action = a;
        },
      ),
    );
    expect(find.text('Four'), findsNothing);
    await tester.tap(find.text('Two'));
    expect(campaign?.id, 'k-many');
    expect(action?.id, 'b');
  });

  testWidgets('reel campaign exposes a Watch reel action', (tester) async {
    MallCampaignVm? watched;
    await pumpMall(
      tester,
      _hero(
        campaigns: const [
          MallCampaignVm(id: 'k-reel', title: 'Watch the look', reelId: 'r-1'),
        ],
        onReel: (campaign) => watched = campaign,
      ),
    );

    final watch = find.text('Watch reel');
    expect(watch, findsOneWidget);
    await tester.tap(watch);
    expect(watched?.reelId, 'r-1');
  });
  testWidgets('auto-advances, and stops dead under reduced motion', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMall(tester, _hero());
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Layers that move with the city'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    expect(find.text('Second campaign'), findsOneWidget);
    expect(find.bySemanticsLabel('Featured, Slide 2 of 3'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('never auto-advances when animations are disabled', (
    tester,
  ) async {
    await pumpMall(tester, _hero(), disableAnimations: true);
    await tester.pump(const Duration(seconds: 20));
    await _settle(tester);
    expect(find.text('Layers that move with the city'), findsOneWidget);
    expect(find.text('Second campaign'), findsNothing);
  });

  group('shared element', () {
    testWidgets('only the campaign on screen carries the tag', (tester) async {
      await pumpMall(
        tester,
        _hero(heroTagFor: (campaign) => 'tag-${campaign.id}'),
      );
      expect(find.byType(Hero), findsOneWidget);
      expect(
        tester.widget<Hero>(find.byType(Hero)).tag,
        'tag-k-1',
      );
    });

    testWidgets('no tag, no flight', (tester) async {
      await pumpMall(tester, _hero(heroTagFor: (_) => null));
      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('opting a single campaign in is enough', (tester) async {
      await pumpMall(tester, _hero());
      expect(find.byType(Hero), findsNothing);
    });
  });

  testWidgets('the overline rides on the stage', (tester) async {
    await pumpMall(
      tester,
      _hero(overline: const Text('Good evening, Sumendra')),
    );
    expect(find.text('Good evening, Sumendra'), findsOneWidget);
  });

  testWidgets('an empty campaign list draws nothing', (tester) async {
    await pumpMall(tester, _hero(campaigns: const []));
    expect(find.byType(MallPrimaryCta), findsNothing);
  });
}
