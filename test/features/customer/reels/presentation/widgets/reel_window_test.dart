import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// fpdart exports a State of its own; the one this suite wants is Flutter's.
import 'package:fpdart/fpdart.dart' hide State;
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_poster.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

/// The reel the window resolves by id. No platform and no media URL, which
/// is the resolver's external-only path: a poster and a short note, no
/// WebView and no video engine. What this suite is about is the window's
/// chrome and lifecycle, not what plays inside the rectangle — the playback
/// decision itself is covered by `reel_playback_resolver_test.dart`.
Reel _reel() => Reel(
  id: 'pr-1',
  sourceUrl: '',
  thumbnailUrl: '',
  creatorId: 'a-1',
  creatorName: 'priya',
  creatorAvatarUrl: '',
  caption: '',
  musicTitle: '',
  musicArtist: '',
  taggedProducts: const [
    TaggedProductEntity(
      id: 'p-1',
      taggedProductId: 'tag-1',
      name: 'Canvas tote',
      imageUrl: '',
      price: Money(amount: 1800, currency: 'NPR'),
      quantity: 1,
    ),
  ],
  likeCount: 12,
  commentCount: 0,
  shareCount: 0,
  createdAt: DateTime(2026, 9, 15),
);

class _FakeReelsRepository implements ReelsRepository {
  _FakeReelsRepository({Either<NetworkExceptions, Reel>? detail})
    : detail = detail ?? right(_reel());

  Either<NetworkExceptions, Reel> detail;

  /// Every reel id the window asked for.
  final List<String> requested = [];

  @override
  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId) async {
    requested.add(reelId);
    return detail;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const MallReelRef _reelRef = MallReelRef(
  reelId: 'pr-1',
  posterUrl: 'https://example.com/reel-poster.jpg',
  hook: 'Styled three ways for the monsoon',
  durationSeconds: 12,
);

const MallReelRef _aiReelRef = MallReelRef(
  reelId: 'pr-2',
  posterUrl: 'https://example.com/reel-poster.jpg',
  hook: 'Made with AI',
  isAiGenerated: true,
  durationSeconds: 8,
);

MallProductVm _product(MallReelRef reel) => MallProductVm(
  id: 'p-reel',
  brandName: 'Kathmandu Atelier',
  name: 'Oversized linen co-ord set',
  price: const Money(amount: 3499, currency: 'NPR'),
  reel: reel,
);

/// What the host screen recorded: the Mall's tile opens the product on a
/// body tap and the window only on the play mark.
class _Taps {
  String? product;
}

/// A Mall tile on a screen, wired the way every Mall call site is.
Future<_Taps> _pumpTile(
  WidgetTester tester, {
  required ReelsRepository repository,
  MallReelRef reel = _reelRef,
  bool disableAnimations = false,
}) async {
  final taps = _Taps();
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [reelsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: MallProductTile.regularWidth,
              child: Builder(
                builder: (context) => MallProductTile(
                  product: _product(reel),
                  onTap: () => taps.product = 'p-reel',
                  onReelTap: (ref) =>
                      unawaited(openMallReelWindow(context, ref)),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taps;
}

Future<void> _tapPlayMark(WidgetTester tester) async {
  await tester.tap(find.byKey(MallReelTile.playKey));
  await tester.pumpAndSettle();
}

/// Every element inside the window that is neither an ancestor of the player
/// rectangle (those paint *behind* it) nor part of it, and whose box overlaps
/// the player rectangle.
List<String> _overlapsPlayer(WidgetTester tester) {
  final playerFinder = find.byKey(ReelWindow.playerRectKey);
  final playerRect = tester.getRect(playerFinder);
  final playerElement = tester.element(playerFinder);

  final exempt = <Element>{};
  playerElement.visitAncestorElements((element) {
    exempt.add(element);
    return true;
  });
  void collectPlayer(Element element) {
    exempt.add(element);
    element.visitChildren(collectPlayer);
  }

  collectPlayer(playerElement);

  final offenders = <String>[];
  void inspect(Element element) {
    // The window's tap sink is painted behind the content and draws
    // nothing — see the assertion on its child in the test below.
    if (element.widget.key == ReelWindow.panelKey) return;
    if (!exempt.contains(element)) {
      final object = element.renderObject;
      if (object is RenderBox && object.attached && object.hasSize) {
        final rect = object.localToGlobal(Offset.zero) & object.size;
        if (!rect.intersect(playerRect).isEmpty) {
          offenders.add('${element.widget.runtimeType} at $rect');
        }
      }
    }
    element.visitChildren(inspect);
  }

  inspect(tester.element(find.byType(ReelWindow)));
  return offenders;
}

void main() {
  // The one-window claim is static, and a test can tear its tree down before
  // the window's route future ever completes.
  setUp(ReelWindow.debugResetOpenState);

  group('opening', () {
    testWidgets('the play mark opens the reel in a window over the screen', (
      tester,
    ) async {
      final repository = _FakeReelsRepository();
      final taps = await _pumpTile(tester, repository: repository);

      expect(find.byType(ReelWindow), findsNothing);
      await _tapPlayMark(tester);

      expect(find.byType(ReelWindow), findsOneWidget);
      expect(ReelWindow.isOpen, isTrue);
      // The Mall is still there underneath: a window, not a route push.
      expect(find.byType(MallReelTile), findsOneWidget);
      // Playback is resolved by reel id, through the reels repository every
      // other reel surface uses.
      expect(repository.requested, ['pr-1']);
      expect(taps.product, isNull);
    });

    testWidgets('the rest of the tile still opens the product', (tester) async {
      final repository = _FakeReelsRepository();
      final taps = await _pumpTile(tester, repository: repository);

      final tile = tester.getRect(find.byType(MallReelTile));
      await tester.tapAt(Offset(tile.center.dx, tile.bottom - 6));
      await tester.pumpAndSettle();

      expect(taps.product, 'p-reel');
      expect(find.byType(ReelWindow), findsNothing);
      expect(repository.requested, isEmpty);
    });

    testWidgets('a second open never stacks a second window', (tester) async {
      final repository = _FakeReelsRepository();
      await _pumpTile(tester, repository: repository);
      await _tapPlayMark(tester);
      expect(find.byType(ReelWindow), findsOneWidget);

      // The tile is still tappable under the window; a second open is
      // refused rather than stacked.
      final context = tester.element(find.byType(MallReelTile));
      await openMallReelWindow(context, _reelRef);
      await tester.pumpAndSettle();

      expect(find.byType(ReelWindow), findsOneWidget);
      expect(find.byKey(ReelWindow.playerRectKey), findsOneWidget);
      expect(find.byType(ReelPlayer), findsOneWidget);
    });

    testWidgets('the window says so when the reel cannot be fetched', (
      tester,
    ) async {
      final repository = _FakeReelsRepository(
        detail: left(const NetworkExceptions.serverUnavailable()),
      );
      await _pumpTile(tester, repository: repository);
      await _tapPlayMark(tester);

      expect(find.text(ReelWindow.unavailableMessage), findsOneWidget);
      expect(find.byType(ReelPlayer), findsNothing);
    });
  });

  group('dismissing', () {
    testWidgets('the close control disposes the player it built', (
      tester,
    ) async {
      await _pumpTile(tester, repository: _FakeReelsRepository());
      await _tapPlayMark(tester);

      final player = tester.state<State<ReelPlayer>>(find.byType(ReelPlayer));
      expect(player.mounted, isTrue);

      await tester.tap(find.byKey(ReelWindow.closeKey));
      await tester.pumpAndSettle();

      // Unmounted means dispose() ran: the player releases its video
      // controller and the embed pool it owns there.
      expect(player.mounted, isFalse);
      expect(find.byType(ReelPlayer), findsNothing);
      expect(find.byType(ReelWindow), findsNothing);
      expect(ReelWindow.isOpen, isFalse);
    });

    testWidgets('the system back button dismisses it', (tester) async {
      await _pumpTile(tester, repository: _FakeReelsRepository());
      await _tapPlayMark(tester);
      expect(find.byType(ReelWindow), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(ReelWindow), findsNothing);
      expect(find.byType(ReelPlayer), findsNothing);
      expect(ReelWindow.isOpen, isFalse);
    });

    testWidgets('a tap outside dismisses it, a tap on the window does not', (
      tester,
    ) async {
      await _pumpTile(tester, repository: _FakeReelsRepository());
      await _tapPlayMark(tester);

      // The window's own padding is not a way out.
      final panel = tester.getRect(find.byKey(ReelWindow.panelKey));
      await tester.tapAt(panel.topLeft + const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byType(ReelWindow), findsOneWidget);

      await tester.tapAt(const Offset(6, 6));
      await tester.pumpAndSettle();
      expect(find.byType(ReelWindow), findsNothing);
      expect(ReelWindow.isOpen, isFalse);
    });

    testWidgets('a swipe down on the chrome dismisses it', (tester) async {
      await _pumpTile(tester, repository: _FakeReelsRepository());
      await _tapPlayMark(tester);

      await tester.fling(
        find.byKey(ReelWindow.headerKey),
        const Offset(0, 220),
        900,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReelWindow), findsNothing);
      expect(ReelWindow.isOpen, isFalse);
    });

    testWidgets('a dismissed window can be opened again', (tester) async {
      await _pumpTile(tester, repository: _FakeReelsRepository());
      await _tapPlayMark(tester);
      await tester.tap(find.byKey(ReelWindow.closeKey));
      await tester.pumpAndSettle();

      await _tapPlayMark(tester);
      expect(find.byType(ReelWindow), findsOneWidget);
      expect(find.byType(ReelPlayer), findsOneWidget);
    });
  });

  group('the chrome', () {
    testWidgets('nothing is drawn in front of the player rectangle', (
      tester,
    ) async {
      await _pumpTile(tester, repository: _FakeReelsRepository());
      await _tapPlayMark(tester);

      // YouTube's embedded player terms forbid any overlay, frame or visual
      // element in front of the player. Every control lives in the chrome.
      expect(
        _overlapsPlayer(tester),
        isEmpty,
        reason:
            'a widget overlapping the player rectangle breaks the embedded '
            'player terms — move it into the chrome',
      );
      // The one span-the-window layer is a childless tap sink behind the
      // content, so it paints nothing over the player.
      final sink = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(ReelWindow.panelKey),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(sink.child, isNull);
    });

    testWidgets('the close control sits outside the player rectangle', (
      tester,
    ) async {
      await _pumpTile(tester, repository: _FakeReelsRepository());
      await _tapPlayMark(tester);

      final player = tester.getRect(find.byKey(ReelWindow.playerRectKey));
      final close = tester.getRect(find.byKey(ReelWindow.closeKey));
      expect(close.intersect(player).isEmpty, isTrue);
      expect(close.bottom, lessThanOrEqualTo(player.top));
    });

    testWidgets('the hook and the shoppable products sit under the player', (
      tester,
    ) async {
      await _pumpTile(tester, repository: _FakeReelsRepository());
      await _tapPlayMark(tester);

      final player = tester.getRect(find.byKey(ReelWindow.playerRectKey));
      final hook = tester.getRect(find.byKey(ReelWindow.hookKey));
      final products = tester.getRect(find.byKey(ReelWindow.productsKey));
      expect(hook.top, greaterThanOrEqualTo(player.bottom));
      expect(products.top, greaterThanOrEqualTo(player.bottom));
      expect(find.text('Canvas tote'), findsOneWidget);
    });

    testWidgets('an AI-generated reel keeps its disclosure in the chrome', (
      tester,
    ) async {
      await _pumpTile(
        tester,
        repository: _FakeReelsRepository(),
        reel: _aiReelRef,
      );
      await _tapPlayMark(tester);

      final label = find.byKey(ReelWindow.aiLabelKey);
      expect(label, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ReelWindow),
          matching: find.text(ReelWindow.aiGeneratedLabel),
        ),
        findsOneWidget,
      );
      final player = tester.getRect(find.byKey(ReelWindow.playerRectKey));
      expect(tester.getRect(label).intersect(player).isEmpty, isTrue);
      expect(_overlapsPlayer(tester), isEmpty);
    });

    testWidgets('an unflagged reel carries no disclosure', (tester) async {
      await _pumpTile(tester, repository: _FakeReelsRepository());
      await _tapPlayMark(tester);

      expect(find.byKey(ReelWindow.aiLabelKey), findsNothing);
      expect(
        find.descendant(
          of: find.byType(ReelWindow),
          matching: find.text(ReelWindow.aiGeneratedLabel),
        ),
        findsNothing,
      );
    });
  });

  group('reduced motion', () {
    testWidgets('opens on the poster and never autoplays', (tester) async {
      await _pumpTile(
        tester,
        repository: _FakeReelsRepository(),
        disableAnimations: true,
      );
      await _tapPlayMark(tester);

      expect(find.byType(ReelWindow), findsOneWidget);
      expect(find.byType(ReelPlayer), findsNothing);
      expect(find.byKey(ReelWindow.playKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ReelWindow.playerRectKey),
          matching: find.byType(ReelPoster),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the viewer starts it themselves', (tester) async {
      await _pumpTile(
        tester,
        repository: _FakeReelsRepository(),
        disableAnimations: true,
      );
      await _tapPlayMark(tester);

      await tester.tap(find.byKey(ReelWindow.playKey));
      await tester.pumpAndSettle();

      expect(find.byType(ReelPlayer), findsOneWidget);
      // The start control is gone the moment a player exists: nothing is
      // ever drawn in front of one.
      expect(find.byKey(ReelWindow.playKey), findsNothing);
      expect(_overlapsPlayer(tester), isEmpty);
    });
  });

  group('the player rectangle', () {
    test('stays comfortably larger than 200x200 on every screen', () {
      // Chrome space left by a 320, 390 and 768dp-wide screen.
      const spaces = [
        Size(264, 512),
        Size(334, 788),
        Size(712, 968),
      ];
      for (final space in spaces) {
        final size = ReelWindow.playerSize(space.width, space.height);
        expect(size.width, greaterThan(200), reason: '$space');
        expect(size.height, greaterThan(200), reason: '$space');
        expect(size.width, lessThanOrEqualTo(ReelWindow.maxPlayerWidth));
        expect(size.height, lessThanOrEqualTo(space.height));
      }
    });

    test('is portrait wherever the height allows it', () {
      final size = ReelWindow.playerSize(334, 788);
      expect(size.width, greaterThanOrEqualTo(300));
      expect(size.height, greaterThan(size.width));
      expect(size.width / size.height, closeTo(9 / 16, 0.01));
    });

    testWidgets('fits inside the window on a small screen', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pumpTile(tester, repository: _FakeReelsRepository());
      // _pumpTile sets its own view size; put the small screen back.
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      await tester.pumpAndSettle();
      await _tapPlayMark(tester);

      expect(tester.takeException(), isNull);
      final player = tester.getRect(find.byKey(ReelWindow.playerRectKey));
      expect(player.width, greaterThan(200));
      expect(player.height, greaterThan(200));
      expect(_overlapsPlayer(tester), isEmpty);
    });
  });
}
