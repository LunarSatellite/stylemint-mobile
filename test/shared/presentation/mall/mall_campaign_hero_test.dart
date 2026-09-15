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
}) => MallCampaignHero(
  campaigns: campaigns,
  onAction: onAction ?? (_, _) {},
);

void main() {
  testMallLayouts('hero with three CTAs fits', (tester, width, scale) async {
    await pumpMall(tester, _hero(), width: width, textScale: scale);
    expectNoLayoutErrors(tester);
    final context = tester.element(find.byType(MallCampaignHero));
    expect(
      tester.getSize(find.byType(MallCampaignHero)).height,
      greaterThanOrEqualTo(MallCampaignHero.heightFor(context)),
    );
    expect(find.byType(MallPrimaryCta), findsOneWidget);
    expect(find.byType(MallGlassCta), findsNWidgets(2));
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

  testWidgets('height is ~62% of the screen, clamped', (tester) async {
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
              height = MallCampaignHero.heightFor(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return height;
    }

    expect(await heightOn(844), closeTo(844 * 0.62, 0.01));
    expect(await heightOn(500), MallCampaignHero.minHeight);
    expect(await heightOn(1400), MallCampaignHero.maxHeight);
  });

  testWidgets('title uses the display face and is a header', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMall(tester, _hero());
    final title = tester.widget<Text>(
      find.text('Layers that move with the city'),
    );
    expect(title.style?.fontFamily, 'InstrumentSerif');
    expect(
      tester.getSemantics(find.text('Layers that move with the city')),
      isSemantics(isHeader: true),
    );
    expect(find.bySemanticsLabel('Featured, Slide 1 of 3'), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
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

  testWidgets('auto-advances every 6 seconds', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpMall(tester, _hero());
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Layers that move with the city'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    expect(find.text('Second campaign'), findsOneWidget);
    expect(find.text('Layers that move with the city'), findsNothing);
    expect(find.bySemanticsLabel('Featured, Slide 2 of 3'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('pauses while touched and resumes a full interval after', (
    tester,
  ) async {
    await pumpMall(tester, _hero());
    final heroTopLeft = tester.getTopLeft(find.byType(MallCampaignHero));
    final gesture = await tester.startGesture(
      heroTopLeft + const Offset(40, 30),
    );
    await tester.pump(const Duration(seconds: 13));
    expect(find.text('Layers that move with the city'), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Layers that move with the city'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    expect(find.text('Second campaign'), findsOneWidget);
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

  testWidgets('swiping changes the slide', (tester) async {
    await pumpMall(tester, _hero());
    final hero = tester.getRect(find.byType(MallCampaignHero));
    await tester.flingFrom(
      Offset(hero.right - 40, hero.top + 40),
      const Offset(-300, 0),
      1000,
    );
    await _settle(tester);
    expect(find.text('Second campaign'), findsOneWidget);
  });

  testWidgets('single campaign: no indicator semantics, no auto-advance', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpMall(tester, _hero(campaigns: const [monsoonCampaign]));
    expect(find.bySemanticsLabel('Featured'), findsOneWidget);
    await tester.pump(const Duration(seconds: 13));
    expect(find.text('Layers that move with the city'), findsOneWidget);
    semantics.dispose();
  });
}
