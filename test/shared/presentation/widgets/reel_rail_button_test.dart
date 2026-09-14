import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_icons.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: disableAnimations),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: child),
      ),
    ),
  ),
);

/// Scale of the pop transition — the one wrapping the icon, not the press
/// feedback's own scale transition.
double _popScale(WidgetTester tester) => tester
    .widgetList<ScaleTransition>(find.byType(ScaleTransition))
    .firstWhere((transition) => transition.child is ReelRailIcon)
    .scale
    .value;

void main() {
  testWidgets('a rail button shows its count under a shadowed icon', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ReelRailButton(
          icon: ReelRailIcons.heart,
          label: 'Like',
          count: '128',
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('128'), findsOneWidget);
    expect(find.bySemanticsLabel('Like, 128'), findsOneWidget);
    // The icon plus its blurred shadow copy — never a BackdropFilter.
    expect(find.byType(SvgPicture), findsNWidgets(2));
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.tap(find.byType(ReelRailButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('the like pop scales the icon up and settles back', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ReelRailButton(
          icon: ReelRailIcons.heart,
          label: 'Like',
          count: '1',
          popOnTap: true,
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(ReelRailButton));
    // The first frame starts the ticker; time only counts from the next one.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_popScale(tester), greaterThan(1));

    await tester.pumpAndSettle();
    expect(_popScale(tester), 1);
    expect(taps, 1);
  });

  testWidgets('the like pop is skipped with reduced motion', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ReelRailButton(
          icon: ReelRailIcons.heart,
          label: 'Like',
          count: '1',
          popOnTap: true,
          onTap: () => taps++,
        ),
        disableAnimations: true,
      ),
    );

    await tester.tap(find.byType(ReelRailButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_popScale(tester), 1);
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the avatar opens the profile and its badge toggles follow', (
    tester,
  ) async {
    var opened = 0;
    var toggled = 0;
    var following = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => ReelRailAvatar(
            creatorName: 'Sumendra',
            imageUrls: const [],
            isFollowing: following,
            onOpenProfile: () => opened++,
            onToggleFollow: () => setState(() {
              toggled++;
              following = !following;
            }),
          ),
        ),
      ),
    );

    expect(find.byKey(ReelRailAvatar.followBadgeKey), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Follow Sumendra'));
    await tester.pumpAndSettle();
    expect(toggled, 1);
    expect(opened, 0);
    expect(find.byKey(ReelRailAvatar.followingBadgeKey), findsOneWidget);
    expect(find.bySemanticsLabel('Following Sumendra'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel("Open Sumendra's profile"));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(toggled, 1);
  });

  testWidgets('an avatar without callbacks has no badge or targets', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ReelRailAvatar(creatorName: 'Sumendra', imageUrls: [])),
    );

    expect(find.byKey(ReelRailAvatar.followBadgeKey), findsNothing);
    expect(find.bySemanticsLabel('Follow Sumendra'), findsNothing);
    expect(find.bySemanticsLabel("Open Sumendra's profile"), findsNothing);
  });

  testWidgets('the product tile shows the compact price chip', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        ReelRailProductTile(
          imageUrl: '',
          priceLabel: 'Rs 1.8K',
          label: 'Shop Nomad Canvas Tote, Rs 1,800',
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('Rs 1.8K'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Shop Nomad Canvas Tote, Rs 1,800'),
      findsOneWidget,
    );
    await tester.tap(find.byType(ReelRailProductTile));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('the cart disc shows its item count as a badge', (tester) async {
    await tester.pumpWidget(_host(const ReelRailCartDisc(itemCount: 3)));

    expect(find.text('3'), findsOneWidget);
    expect(find.bySemanticsLabel('Cart, 3'), findsOneWidget);
  });

  testWidgets('an empty cart disc hides the badge', (tester) async {
    await tester.pumpWidget(_host(const ReelRailCartDisc()));

    expect(find.bySemanticsLabel('Cart'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('interactive rail items meet the 48dp tap-target guideline', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReelRailButton(
              icon: ReelRailIcons.share,
              label: 'Share',
              count: '9',
              onTap: () {},
            ),
            ReelRailProductTile(
              imageUrl: '',
              priceLabel: 'Rs 1.8K',
              label: 'Shop tote',
              onTap: () {},
            ),
            ReelRailCartDisc(itemCount: 2, onTap: () {}),
          ],
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });

  test('formatRailCount shortens thousands and millions', () {
    expect(formatRailCount(950), '950');
    expect(formatRailCount(1000), '1K');
    expect(formatRailCount(1200), '1.2K');
    expect(formatRailCount(3400000), '3.4M');
  });
}
