import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_icons.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

Widget _host(
  Widget child, {
  bool disableAnimations = false,
  bool tickersEnabled = true,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: disableAnimations),
      child: TickerMode(
        enabled: tickersEnabled,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: child),
        ),
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

double _scaleOf(WidgetTester tester, Key key) =>
    tester.widget<ScaleTransition>(find.byKey(key)).scale.value;

ReelRailProductTile _tile({bool inCart = false, int? cartCount}) =>
    ReelRailProductTile(
      productId: 'prod-tote',
      priceLabel: 'Rs 1.8K',
      label: 'Shop Nomad Canvas Tote, Rs 1,800',
      inCart: inCart,
      cartCount: cartCount,
      onTap: () {},
    );

Border _frameBorder(WidgetTester tester) {
  final frame = tester.widget<Container>(
    find.byKey(ReelRailProductTile.frameKey),
  );
  return (frame.foregroundDecoration! as BoxDecoration).border! as Border;
}

/// Records the haptic types the widget under test asks for.
List<Object?> _recordHaptics(WidgetTester tester) {
  final haptics = <Object?>[];
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
      return null;
    });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return haptics;
}

List<String> _announcements(WidgetTester tester) =>
    tester.takeAnnouncements().map((a) => a.message).toList();

const _lightImpact = 'HapticFeedbackType.lightImpact';

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
          productId: 'prod-tote',
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

  group('product tile cart state', () {
    testWidgets('an in-cart tile has a 2dp mint frame and shows the cart '
        'count in its badge', (tester) async {
      await tester.pumpWidget(_host(_tile(inCart: true, cartCount: 2)));

      final border = _frameBorder(tester);
      expect(border.top.color, DesignTokens.primaryGreen);
      expect(border.top.width, 2);
      expect(find.byKey(ReelRailProductTile.inCartBadgeKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ReelRailProductTile.inCartBadgeKey),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Shop Nomad Canvas Tote, Rs 1,800, in cart'),
        findsOneWidget,
      );
    });

    testWidgets('a tile not in the cart keeps the white frame and still '
        'shows the cart count', (tester) async {
      await tester.pumpWidget(_host(_tile(cartCount: 3)));

      final border = _frameBorder(tester);
      expect(border.top.color, const Color(0xE6FFFFFF));
      expect(border.top.width, 1.5);
      expect(find.byKey(ReelRailProductTile.inCartBadgeKey), findsNothing);
      expect(find.byKey(ReelRailProductTile.cartCountKey), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Shop Nomad Canvas Tote, Rs 1,800'),
        findsOneWidget,
      );
    });

    testWidgets('the count caps at 99+ and hides for an empty cart', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_tile(cartCount: 120)));
      expect(find.text('99+'), findsOneWidget);

      // A fresh tile (not an update), so nothing celebrates.
      await tester.pumpWidget(_host(KeyedSubtree(child: _tile(cartCount: 0))));
      expect(find.byKey(ReelRailProductTile.cartCountKey), findsNothing);
    });
  });

  group('product tile celebration', () {
    testWidgets('plays when the cart count rises, not on the first build, '
        'and never shows text', (tester) async {
      final haptics = _recordHaptics(tester);
      await tester.pumpWidget(_host(_tile(cartCount: 1)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(_scaleOf(tester, ReelRailProductTile.popKey), 1);
      expect(tester.hasRunningAnimations, isFalse);
      expect(haptics, isEmpty);
      expect(_announcements(tester), isEmpty);

      await tester.pumpWidget(_host(_tile(inCart: true, cartCount: 2)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(_scaleOf(tester, ReelRailProductTile.popKey), greaterThan(1));
      expect(find.byKey(ReelRailProductTile.inCartBadgeKey), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      // The price chip never swaps for an "added" message.
      expect(find.text('Rs 1.8K'), findsOneWidget);
      expect(find.textContaining('Added'), findsNothing);
      expect(haptics, [_lightImpact]);
      expect(_announcements(tester), ['Added to cart']);

      await tester.pumpAndSettle();
      expect(_scaleOf(tester, ReelRailProductTile.popKey), 1);
      expect(haptics, [_lightImpact]);
    });

    testWidgets('the first transition into the cart celebrates too', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      await tester.pumpWidget(_host(_tile(cartCount: 2)));
      await tester.pumpWidget(_host(_tile(inCart: true, cartCount: 2)));
      await tester.pump();

      expect(haptics, [_lightImpact]);
      await tester.pumpAndSettle();
    });

    testWidgets('stays quiet when the cart first loads or shrinks', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      await tester.pumpWidget(_host(_tile()));
      await tester.pumpWidget(_host(_tile(inCart: true, cartCount: 4)));
      await tester.pump();
      await tester.pumpWidget(_host(_tile(cartCount: 1)));
      await tester.pumpAndSettle();

      expect(haptics, isEmpty);
      expect(_announcements(tester), isEmpty);
    });

    testWidgets('no celebration or haptic while tickers are off', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      await tester.pumpWidget(
        _host(_tile(cartCount: 0), tickersEnabled: false),
      );
      await tester.pumpWidget(
        _host(_tile(inCart: true, cartCount: 1), tickersEnabled: false),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The state still changes.
      expect(find.byKey(ReelRailProductTile.inCartBadgeKey), findsOneWidget);
      expect(_scaleOf(tester, ReelRailProductTile.popKey), 1);
      expect(haptics, isEmpty);
      expect(_announcements(tester), isEmpty);
    });

    testWidgets('no celebration for a reel built off screen', (tester) async {
      final haptics = _recordHaptics(tester);
      Widget offScreen(ReelRailProductTile tile) => _host(
        Transform.translate(offset: const Offset(0, 900), child: tile),
      );
      await tester.pumpWidget(offScreen(_tile(cartCount: 0)));
      await tester.pumpWidget(offScreen(_tile(inCart: true, cartCount: 1)));
      await tester.pump();

      expect(haptics, isEmpty);
    });

    testWidgets('reduced motion keeps the state change but skips the pop, '
        'ring and bounce', (tester) async {
      final haptics = _recordHaptics(tester);
      await tester.pumpWidget(
        _host(_tile(cartCount: 0), disableAnimations: true),
      );
      await tester.pumpWidget(
        _host(_tile(inCart: true, cartCount: 1), disableAnimations: true),
      );
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_scaleOf(tester, ReelRailProductTile.popKey), 1);
      expect(find.byKey(ReelRailProductTile.inCartBadgeKey), findsOneWidget);
      expect(_frameBorder(tester).top.color, DesignTokens.primaryGreen);
      expect(haptics, [_lightImpact]);
      expect(find.text('Rs 1.8K'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
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

  testWidgets('the cart disc pops with a haptic when its count rises', (
    tester,
  ) async {
    final haptics = _recordHaptics(tester);
    await tester.pumpWidget(_host(const ReelRailCartDisc()));
    // The cart loading is not an add.
    await tester.pumpWidget(_host(const ReelRailCartDisc(itemCount: 1)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_scaleOf(tester, ReelRailCartDisc.popKey), 1);
    expect(haptics, isEmpty);

    await tester.pumpWidget(_host(const ReelRailCartDisc(itemCount: 2)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_scaleOf(tester, ReelRailCartDisc.popKey), greaterThan(1));
    expect(haptics, [_lightImpact]);
    expect(_announcements(tester), ['Added to cart']);
    expect(find.bySemanticsLabel('Cart, 2'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(_scaleOf(tester, ReelRailCartDisc.popKey), 1);
  });

  testWidgets('the cart disc skips the pop with reduced motion', (
    tester,
  ) async {
    final haptics = _recordHaptics(tester);
    await tester.pumpWidget(
      _host(const ReelRailCartDisc(itemCount: 1), disableAnimations: true),
    );
    await tester.pumpWidget(
      _host(const ReelRailCartDisc(itemCount: 2), disableAnimations: true),
    );
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(_scaleOf(tester, ReelRailCartDisc.popKey), 1);
    expect(haptics, [_lightImpact]);
    expect(find.text('2'), findsOneWidget);
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
              productId: 'prod-tote',
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
