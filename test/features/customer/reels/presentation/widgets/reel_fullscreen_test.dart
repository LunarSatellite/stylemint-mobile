import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/creator_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_more_button.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reels_pager.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/tagged_products_section.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_fullscreen.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';

/// An Instagram reel with no media URL: it shows its poster, so no video or
/// WebView platform is needed. What this suite is about is what surrounds the
/// player in and out of full screen, and that the player itself survives the
/// trip.
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
  createdAt: DateTime(2026, 10, 26),
);

final Finder _enter = find.byKey(ReelCard.enterFullscreenKey);
final Finder _exit = find.byKey(ReelCard.exitFullscreenKey);

void main() {
  setUp(() => ReelsPager.debugHostEmbedPlayers = false);
  tearDown(() => ReelsPager.debugHostEmbedPlayers = true);

  /// Every call the app made on the platform channel SystemChrome uses.
  late List<MethodCall> platformCalls;
  late ReelsPagerController controller;
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester) async {
    platformCalls = [];
    final messenger = tester.binding.defaultBinaryMessenger
      ..setMockMethodCallHandler(SystemChannels.platform, (call) async {
        platformCalls.add(call);
        return null;
      });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    controller = ReelsPagerController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReelsPager(
            controller: controller,
            reels: [_reel('r-1'), _reel('r-2'), _reel('r-3')],
          ),
        ),
      ),
    );
    await tester.pump();
    container = ProviderScope.containerOf(
      tester.element(find.byType(ReelsPager)),
    );
  }

  /// Lets the system UI calls, which run one after another, all go out.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  bool fullscreen() => container.read(reelFullscreenProvider);

  /// The overlay a reel shows outside full screen.
  void expectOverlay({required bool shown}) {
    final matcher = shown ? findsOneWidget : findsNothing;
    expect(find.byType(ReelActions), matcher);
    expect(find.byType(CreatorInfo), matcher);
    expect(find.byType(ReelMoreButton), matcher);
    expect(_enter, matcher);
    expect(_exit, shown ? findsNothing : findsOneWidget);
    // These reels carry no tags, so the strip is never there; it is checked
    // anyway so a full screen that drew one would fail here.
    expect(find.byType(TaggedProductsSection), findsNothing);
  }

  /// Two fingers on the middle of the reel, [from] apart vertically, moved to
  /// [to] apart in five steps.
  Future<void> pinch(
    WidgetTester tester, {
    required double from,
    required double to,
  }) async {
    final centre = tester.getCenter(find.byType(ReelsPager));
    final top = await tester.startGesture(
      centre - Offset(0, from / 2),
      pointer: 7,
    );
    final bottom = await tester.startGesture(
      centre + Offset(0, from / 2),
      pointer: 8,
    );
    await tester.pump();
    final step = (to - from) / 2 / 5;
    for (var i = 0; i < 5; i++) {
      await top.moveBy(Offset(0, -step));
      await bottom.moveBy(Offset(0, step));
      await tester.pump();
    }
    await top.up();
    await bottom.up();
    await tester.pump();
  }

  group('the full-screen button', () {
    testWidgets('is on the reel, labelled, and opens full screen', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      expectOverlay(shown: true);
      expect(
        find.bySemanticsLabel(ReelCard.enterFullscreenLabel),
        findsOneWidget,
      );

      await tester.tap(_enter);
      await tester.pump();

      expect(fullscreen(), isTrue);
      expect(
        find.bySemanticsLabel(ReelCard.exitFullscreenLabel),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('full screen is the video and the close button, nothing else', (
      tester,
    ) async {
      await pump(tester);
      final player = tester.state(find.byType(ReelPlayer));

      await tester.tap(_enter);
      await tester.pump();

      expectOverlay(shown: false);
      // The same player, not a second one: the video keeps playing where it
      // was instead of reloading.
      expect(find.byType(ReelPlayer), findsOneWidget);
      expect(tester.state(find.byType(ReelPlayer)), same(player));
      expect(
        tester.widget<ReelPlayer>(find.byType(ReelPlayer)).fitWhole,
        isTrue,
      );
    });

    testWidgets('hides the system bars and keeps the app portrait', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(_enter);
      await settle(tester);

      expect(
        platformCalls,
        contains(
          isA<MethodCall>()
              .having(
                (c) => c.method,
                'method',
                'SystemChrome.setEnabledSystemUIMode',
              )
              .having(
                (c) => c.arguments,
                'arguments',
                SystemUiMode.immersiveSticky.toString(),
              ),
        ),
      );
      // A reel of unknown (here: no) shape never unlocks landscape.
      final orientations = platformCalls.where(
        (c) => c.method == 'SystemChrome.setPreferredOrientations',
      );
      expect(orientations, isNotEmpty);
      expect(orientations.last.arguments, ['DeviceOrientation.portraitUp']);
    });
  });

  group('leaving full screen', () {
    testWidgets('the close button brings the overlay back on the same reel', (
      tester,
    ) async {
      await pump(tester);
      // Move to the second reel first, so "the same reel" means something.
      await tester.drag(find.byType(PageView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(controller.pageController.page, 1);
      final player = tester.state(find.byType(ReelPlayer));

      await tester.tap(_enter);
      await tester.pump();
      expectOverlay(shown: false);

      platformCalls.clear();
      await tester.tap(_exit);
      await settle(tester);

      expect(fullscreen(), isFalse);
      expectOverlay(shown: true);
      expect(controller.pageController.page, 1);
      expect(tester.state(find.byType(ReelPlayer)), same(player));
      expect(
        tester.widget<ReelPlayer>(find.byType(ReelPlayer)).fitWhole,
        isFalse,
      );
      // The system bars and the portrait lock are put back.
      expect(
        platformCalls.map((c) => c.method),
        containsAll(<String>[
          'SystemChrome.setEnabledSystemUIOverlays',
          'SystemChrome.setPreferredOrientations',
        ]),
      );
      expect(
        platformCalls
            .lastWhere(
              (c) => c.method == 'SystemChrome.setPreferredOrientations',
            )
            .arguments,
        ['DeviceOrientation.portraitUp'],
      );
    });

    testWidgets('system back leaves full screen and stays on the page', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(_enter);
      await tester.pump();
      expect(fullscreen(), isTrue);

      // What the platform sends for the Android back button or gesture.
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        SystemChannels.navigation.codec.encodeMethodCall(
          const MethodCall('popRoute'),
        ),
        (_) {},
      );
      await tester.pump();

      expect(fullscreen(), isFalse);
      expectOverlay(shown: true);
      expect(find.byType(ReelsPager), findsOneWidget);
    });

    testWidgets('a pinch in leaves full screen', (tester) async {
      await pump(tester);
      await tester.tap(_enter);
      await tester.pump();

      await pinch(tester, from: 300, to: 120);

      expect(fullscreen(), isFalse);
      expectOverlay(shown: true);
    });
  });

  group('gestures', () {
    testWidgets('spreading two fingers opens full screen', (tester) async {
      await pump(tester);
      final player = tester.state(find.byType(ReelPlayer));

      await pinch(tester, from: 80, to: 240);

      expect(fullscreen(), isTrue);
      expectOverlay(shown: false);
      // A pinch is not a swipe: the feed did not page under it.
      expect(controller.pageController.page, 0);
      expect(tester.state(find.byType(ReelPlayer)), same(player));
    });

    testWidgets('a small spread is not enough', (tester) async {
      await pump(tester);

      await pinch(tester, from: 200, to: 216);

      expect(fullscreen(), isFalse);
      expectOverlay(shown: true);
    });

    testWidgets('one finger still pages the feed, and never goes full '
        'screen', (tester) async {
      await pump(tester);

      await tester.drag(find.byType(PageView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(controller.pageController.page, 1);
      expect(fullscreen(), isFalse);

      await tester.drag(find.byType(PageView), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(controller.pageController.page, 0);
      expect(fullscreen(), isFalse);
    });

    testWidgets('a tap does not go full screen', (tester) async {
      await pump(tester);

      await tester.tapAt(tester.getCenter(find.byType(ReelsPager)));
      await tester.pump();

      expect(fullscreen(), isFalse);
      expectOverlay(shown: true);
    });

    testWidgets('a full-screen reel does not page away', (tester) async {
      await pump(tester);
      await tester.tap(_enter);
      await tester.pump();

      await tester.drag(find.byType(PageView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(controller.pageController.page, 0);
      expect(fullscreen(), isTrue);
    });
  });

  testWidgets('a landscape video may turn the phone sideways', (tester) async {
    await pump(tester);
    final owner = Object();

    container
        .read(reelFullscreenProvider.notifier)
        .enter(owner, allowLandscape: true);
    await settle(tester);

    final orientations = platformCalls
        .where((c) => c.method == 'SystemChrome.setPreferredOrientations')
        .last
        .arguments as List<Object?>;
    expect(
      orientations,
      containsAll(<String>[
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]),
    );

    // Someone else cannot end it; its owner can.
    container.read(reelFullscreenProvider.notifier).exit(Object());
    expect(fullscreen(), isTrue);
    container.read(reelFullscreenProvider.notifier).exit(owner);
    await settle(tester);
    expect(fullscreen(), isFalse);
    expect(
      platformCalls
          .lastWhere((c) => c.method == 'SystemChrome.setPreferredOrientations')
          .arguments,
      appOrientations.map((o) => o.toString()).toList(),
    );
  });
}
