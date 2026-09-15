import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_icons.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_bottom_nav_bar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_nav_icons.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

Widget _host(
  Widget bar, {
  bool disableAnimations = false,
  EdgeInsets padding = EdgeInsets.zero,
  double textScale = 1,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: disableAnimations,
        padding: padding,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(body: const SizedBox.expand(), bottomNavigationBar: bar),
    ),
  ),
);

List<SmBottomNavItem> _tabs({int ordersBadge = 0, String? avatarUrl}) => [
  SmBottomNavItem.glyph(SmNavIcons.home, label: 'Home'),
  SmBottomNavItem.glyph(SmNavIcons.compass, label: 'Discover'),
  SmBottomNavItem.glyph(SmNavIcons.box, label: 'Orders', badge: ordersBadge),
  SmBottomNavItem.glyph(
    SmNavIcons.person,
    label: 'Profile',
    avatarUrl: avatarUrl,
  ),
];

/// A bar whose selection follows taps, as a shell's would.
Widget _selectableBar({bool disableAnimations = false}) {
  var current = 0;
  return _host(
    StatefulBuilder(
      builder: (context, setState) => SmBottomNavBar(
        items: _tabs(),
        currentIndex: current,
        onTap: (index) => setState(() => current = index),
      ),
    ),
    disableAnimations: disableAnimations,
  );
}

/// Tints of the rail icons drawn in tab [tab], bottom layer first.
List<Color> _iconColors(WidgetTester tester, int tab) => tester
    .widgetList<ReelRailIcon>(
      find.descendant(
        of: find.byKey(SmBottomNavBar.tabKey(tab)),
        matching: find.byType(ReelRailIcon),
      ),
    )
    .map((icon) => icon.color)
    .toList();

/// The pill colour tab [tab] is currently painting.
Color _pillColor(WidgetTester tester, int tab) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byKey(SmBottomNavBar.pillKey(tab)),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color!;
}

/// A photo that never finishes loading, so the ring renders offline.
class _PendingImage extends ImageProvider<_PendingImage> {
  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}

/// A photo that fails to load, like a broken URL while offline.
class _BrokenImage extends ImageProvider<_BrokenImage> {
  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _BrokenImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(StateError('offline')),
  );
}

void main() {
  testWidgets('the bar is 64dp over the safe area, with a hairline, no blur', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(SmBottomNavBar(items: _tabs(), currentIndex: 0, onTap: (_) {})),
    );

    expect(
      tester.getSize(find.byType(SmBottomNavBar)).height,
      SmBottomNavBar.height + 1,
    );
    final bar = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(SmBottomNavBar),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = bar.decoration as BoxDecoration;
    expect(decoration.color, SmNavPalette.bar);
    expect(
      decoration.border!.top,
      const BorderSide(color: SmNavPalette.hairline),
    );
    expect(decoration.boxShadow, isNull);
    expect(find.byType(BackdropFilter), findsNothing);

    await tester.pumpWidget(
      _host(
        SmBottomNavBar(items: _tabs(), currentIndex: 0, onTap: (_) {}),
        padding: const EdgeInsets.only(bottom: 24),
      ),
    );
    expect(
      tester.getSize(find.byType(SmBottomNavBar)).height,
      SmBottomNavBar.height + 1 + 24,
    );
  });

  testWidgets('the active tab sits on the mint pill with a filled icon', (
    tester,
  ) async {
    await tester.pumpWidget(_selectableBar());

    expect(_pillColor(tester, 0), SmNavPalette.pill);
    expect(_pillColor(tester, 1).a, 0);
    expect(_iconColors(tester, 0), [SmNavPalette.active]);
    expect(_iconColors(tester, 1), [SmNavPalette.inactive]);

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(_pillColor(tester, 1), SmNavPalette.pill);
    expect(_pillColor(tester, 0).a, 0);
    // The compass fills mint and its needle is cut out in the bar colour.
    expect(_iconColors(tester, 1), [SmNavPalette.active, SmNavPalette.bar]);
    expect(_iconColors(tester, 0), [SmNavPalette.inactive]);
  });

  testWidgets('the pill fades in over 200ms', (tester) async {
    await tester.pumpWidget(_selectableBar());

    await tester.tap(find.text('Orders'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = _pillColor(tester, 2).a;
    expect(midway, greaterThan(0));
    expect(midway, lessThan(SmNavPalette.pill.a));

    await tester.pumpAndSettle();
    expect(_pillColor(tester, 2), SmNavPalette.pill);
  });

  testWidgets('the pill switches at once with reduced motion', (tester) async {
    await tester.pumpWidget(_selectableBar(disableAnimations: true));

    await tester.tap(find.text('Orders'));
    await tester.pump();
    expect(_pillColor(tester, 2), SmNavPalette.pill);
    expect(_pillColor(tester, 0).a, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('labels are 11.5 semibold when active, medium and muted if not', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(SmBottomNavBar(items: _tabs(), currentIndex: 0, onTap: (_) {})),
    );

    final active = tester.widget<Text>(find.text('Home')).style!;
    expect(active.fontSize, 11.5);
    expect(active.fontWeight, FontWeight.w600);
    expect(active.color, SmNavPalette.labelActive);

    final inactive = tester.widget<Text>(find.text('Discover')).style!;
    expect(inactive.fontSize, 11.5);
    expect(inactive.fontWeight, FontWeight.w500);
    expect(inactive.color!.a, closeTo(0.62, 0.005));
  });

  testWidgets('the badge shows the count, caps at 99+ and hides at 0', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    Future<void> pumpBadge(int count) => tester.pumpWidget(
      _host(
        SmBottomNavBar(
          items: _tabs(ordersBadge: count),
          currentIndex: 0,
          onTap: (_) {},
        ),
      ),
    );

    await pumpBadge(0);
    expect(find.byKey(SmBottomNavBar.badgeKey), findsNothing);
    expect(find.bySemanticsLabel('Orders'), findsOneWidget);

    await pumpBadge(7);
    expect(
      find.descendant(
        of: find.byKey(SmBottomNavBar.badgeKey),
        matching: find.text('7'),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Orders, 7'), findsOneWidget);
    final badge = tester.widget<Container>(find.byKey(SmBottomNavBar.badgeKey));
    expect(
      (badge.decoration! as BoxDecoration).color,
      DesignTokens.colorError,
    );
    // Top-right of the box icon.
    final icon = tester.getRect(
      find.descendant(
        of: find.byKey(SmBottomNavBar.tabKey(2)),
        matching: find.byType(ReelRailIcon),
      ),
    );
    final pill = tester.getRect(find.byKey(SmBottomNavBar.badgeKey));
    expect(pill.left, greaterThan(icon.center.dx));
    expect(pill.top, lessThan(icon.top));

    await pumpBadge(120);
    expect(find.text('99+'), findsOneWidget);
    expect(find.text('120'), findsNothing);
    expect(find.bySemanticsLabel('Orders, 99+'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the profile tab shows the photo, ringed mint when active', (
    tester,
  ) async {
    final photo = _PendingImage();
    Future<void> pumpAt(int index) => tester.pumpWidget(
      _host(
        SmBottomNavBar(
          items: _tabs(avatarUrl: 'https://cdn.example/me.jpg'),
          currentIndex: index,
          onTap: (_) {},
          avatarImage: (_) => photo,
        ),
      ),
    );
    BoxDecoration ring() =>
        tester
                .widget<Container>(find.byKey(SmBottomNavBar.avatarKey))
                .decoration!
            as BoxDecoration;

    await pumpAt(0);
    expect(
      tester.getSize(find.byKey(SmBottomNavBar.avatarKey)),
      const Size.square(24),
    );
    expect(ring().shape, BoxShape.circle);
    expect(
      ring().border!.top,
      const BorderSide(color: SmNavPalette.avatarRing, width: 1.5),
    );
    expect(ring().boxShadow, isNull);
    // The photo replaces the person icon.
    expect(_iconColors(tester, 3), isEmpty);

    await pumpAt(3);
    expect(ring().border!.top.color, SmNavPalette.active);
    expect(ring().boxShadow, [
      BoxShadow(color: SmNavPalette.avatarHalo, spreadRadius: 2),
    ]);
  });

  testWidgets('the profile tab falls back to the person icon', (tester) async {
    final broken = _BrokenImage();
    Widget bar(String? url, int index) => _host(
      SmBottomNavBar(
        items: _tabs(avatarUrl: url),
        currentIndex: index,
        onTap: (_) {},
        avatarImage: (_) => broken,
      ),
    );

    // Guest or no photo.
    for (final url in <String?>[null, '']) {
      await tester.pumpWidget(bar(url, 3));
      expect(find.byKey(SmBottomNavBar.avatarKey), findsNothing);
      expect(_iconColors(tester, 3), [SmNavPalette.active]);
    }

    // A photo that fails to load.
    await tester.pumpWidget(bar('https://cdn.example/gone.jpg', 0));
    await tester.pump();
    expect(find.byKey(SmBottomNavBar.avatarKey), findsNothing);
    expect(_iconColors(tester, 3), [SmNavPalette.inactive]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tap reports its index, with a haptic only on a change', (
    tester,
  ) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final taps = <int>[];
    await tester.pumpWidget(
      _host(SmBottomNavBar(items: _tabs(), currentIndex: 0, onTap: taps.add)),
    );

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(taps, [2]);
    expect(haptics, ['HapticFeedbackType.selectionClick']);

    // The selected tab still reports (shells refresh on it) but stays quiet.
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(taps, [2, 0]);
    expect(haptics, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tabs expose button, selected state and label to semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(SmBottomNavBar(items: _tabs(), currentIndex: 1, onTap: (_) {})),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Discover')),
      isSemantics(
        label: 'Discover',
        isButton: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Home')),
      isSemantics(
        label: 'Home',
        isButton: true,
        isSelected: false,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('the centre action sits between the halves, level with icons', (
    tester,
  ) async {
    final taps = <int>[];
    var imports = 0;
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        SmBottomNavBar(
          items: _tabs(),
          currentIndex: 0,
          onTap: taps.add,
          centerAction: SmNavCenterAction(
            semanticLabel: 'Import reel',
            onTap: () => imports++,
          ),
        ),
      ),
    );

    final circle = find.byKey(SmNavCenterAction.circleKey);
    expect(tester.getSize(circle), const Size.square(44));
    final homeIcon = tester.getCenter(
      find.descendant(
        of: find.byKey(SmBottomNavBar.tabKey(0)),
        matching: find.byType(ReelRailIcon),
      ),
    );
    final centre = tester.getCenter(circle);
    expect(centre.dy, moreOrLessEquals(homeIcon.dy));
    expect(
      centre.dx,
      greaterThan(tester.getCenter(find.byKey(SmBottomNavBar.tabKey(1))).dx),
    );
    expect(
      centre.dx,
      lessThan(tester.getCenter(find.byKey(SmBottomNavBar.tabKey(2))).dx),
    );
    // No label; a dark plus on the mint circle.
    expect(
      find.descendant(
        of: find.byType(SmNavCenterAction),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
    final plus = tester.widget<ReelRailIcon>(
      find.descendant(of: circle, matching: find.byType(ReelRailIcon)),
    );
    expect(plus.color, DesignTokens.buttonPrimaryText);

    await tester.tap(circle);
    await tester.pumpAndSettle();
    expect(imports, 1);
    expect(taps, isEmpty);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Import reel')),
      isSemantics(isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('every tab and the centre action meet tap-target guidelines', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        SmBottomNavBar(
          items: _tabs(ordersBadge: 3, avatarUrl: 'https://cdn.example/me.jpg'),
          currentIndex: 3,
          onTap: (_) {},
          avatarImage: (_) => _PendingImage(),
          centerAction: SmNavCenterAction(
            semanticLabel: 'Import reel',
            onTap: () {},
          ),
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets('labels shrink instead of overflowing at large text sizes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        SmBottomNavBar(
          items: [
            SmBottomNavItem.glyph(SmNavIcons.home, label: 'Home'),
            SmBottomNavItem.glyph(SmNavIcons.analytics, label: 'Analytics'),
            SmBottomNavItem.glyph(SmNavIcons.tag, label: 'Brands'),
            SmBottomNavItem.glyph(SmNavIcons.person, label: 'Profile'),
          ],
          currentIndex: 1,
          onTap: (_) {},
          centerAction: SmNavCenterAction(
            semanticLabel: 'Import reel',
            onTap: () {},
          ),
        ),
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(SmBottomNavBar)).height,
      SmBottomNavBar.height + 1,
    );
  });
}
