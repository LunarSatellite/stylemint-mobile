import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_origins.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_pool.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_reel_surface.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';

class _FakeDriver implements EmbedSlotDriver {
  _FakeDriver(this.slot);

  final EmbedSlot slot;
  final List<String> hosts = [];
  final List<String> scripts = [];

  @override
  Future<void> loadHost(String origin) async => hosts.add(origin);

  @override
  Future<void> runJavaScript(String source) async => scripts.add(source);
}

/// A feed's pool with fake WebViews.
class _Feed {
  _Feed(this.pool, this.drivers);

  final EmbedPlayerPool pool;
  final List<_FakeDriver> drivers;

  void loadHosts() {
    for (final driver in drivers) {
      if (driver.hosts.isNotEmpty) {
        driver.slot.handleEvent({
          'type': 'host_loaded',
          'origin': driver.hosts.last,
        });
      }
    }
  }

  _FakeDriver holding(EmbedRequest request) =>
      drivers.firstWhere((d) => d.slot.key == request.key);

  /// The player holding [request] reports [type].
  void report(
    EmbedRequest request,
    String type, [
    Map<String, Object?> extra = const {},
  ]) {
    final driver = holding(request);
    final token = int.parse(
      RegExp(
        r'smPlayer\.assign\((\d+),',
      ).allMatches(driver.scripts.join('\n')).last.group(1)!,
    );
    driver.slot.handleEvent({'type': type, 'token': token, ...extra});
  }
}

const _poster = Key('poster');
const _fallback = Key('fallback');

EmbedRequest _tikTok(String id) => EmbedRequest(
  EmbedSource(
    platform: SocialPlatform.tiktok,
    externalId: id,
    permalink: 'https://www.tiktok.com/@stylemint25/video/$id',
  ),
);

Future<_Feed> _feed(
  WidgetTester tester, {
  Duration startTimeout = const Duration(milliseconds: 2500),
}) async {
  final pool = EmbedPlayerPool(
    origins: Future.value(
      const EmbedOrigins(
        appOrigin: 'https://app.test',
        webOrigin: 'https://web.test',
      ),
    ),
    startTimeout: startTimeout,
  );
  final drivers = [for (final slot in pool.slots) _FakeDriver(slot)];
  for (final driver in drivers) {
    driver.slot.attach(driver);
  }
  await tester.pump();
  return _Feed(pool, drivers);
}

Future<void> _show(
  WidgetTester tester,
  _Feed feed,
  EmbedRequest request, {
  bool reduceMotion = false,
}) => tester.pumpWidget(
  MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: EmbedReelSurface(
        pool: feed.pool,
        request: request,
        showPauseIndicator: false,
        poster: const ColoredBox(key: _poster, color: Color(0xFF203040)),
        fallback: const SizedBox(key: _fallback),
      ),
    ),
  ),
);

double _posterOpacity(WidgetTester tester) {
  final fade = find.ancestor(
    of: find.byKey(_poster),
    matching: find.byType(FadeTransition),
  );
  return tester.widget<FadeTransition>(fade.first).opacity.value;
}

Future<void> _close(WidgetTester tester, _Feed feed) async {
  await tester.pumpWidget(const SizedBox.shrink());
  feed.pool.dispose();
}

void main() {
  final reel = _tikTok('7685232277147618581');

  testWidgets(
    'keeps the poster over a TikTok player until it plays, then fades it out',
    (tester) async {
      final feed = await _feed(tester);
      feed.pool.setWindow(active: reel);
      feed.loadHosts();
      await _show(tester, feed, reel);

      // TikTok states -1 (init) and 3 (buffering) are still loading.
      for (final type in ['init', 'ready', 'buffering']) {
        feed.report(reel, type);
        await tester.pump();
        expect(_posterOpacity(tester), 1, reason: type);
      }

      feed.report(reel, 'playing');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      expect(_posterOpacity(tester), inExclusiveRange(0, 1));
      await tester.pump(EmbedReelSurface.posterFadeOut);
      expect(_posterOpacity(tester), 0);

      await _close(tester, feed);
    },
  );

  testWidgets(
    'a stalled start keeps the poster up; once played, a pause never covers '
    'the player again',
    (tester) async {
      final feed = await _feed(
        tester,
        startTimeout: const Duration(milliseconds: 40),
      );
      feed.pool.setWindow(active: reel);
      feed.loadHosts();
      await _show(tester, feed, reel);

      feed.report(reel, 'ready');
      await tester.pump(const Duration(milliseconds: 50));
      expect(feed.holding(reel).scripts, contains('smPlayer.retryStart()'));
      feed.report(reel, 'paused');
      await tester.pump();
      expect(_posterOpacity(tester), 1, reason: "TikTok's start screen");

      feed.report(reel, 'playing');
      await tester.pump();
      await tester.pump(EmbedReelSurface.posterFadeOut);
      expect(_posterOpacity(tester), 0);

      feed.pool.togglePause();
      feed.report(reel, 'paused');
      await tester.pump();
      await tester.pump(EmbedReelSurface.posterFadeOut);
      expect(_posterOpacity(tester), 0);

      await _close(tester, feed);
    },
  );

  testWidgets('with reduced motion the poster goes at once', (tester) async {
    final feed = await _feed(tester);
    feed.pool.setWindow(active: reel);
    feed.loadHosts();
    await _show(tester, feed, reel, reduceMotion: true);

    feed
      ..report(reel, 'ready')
      ..report(reel, 'playing');
    await tester.pump();

    expect(_posterOpacity(tester), 0);
    await _close(tester, feed);
  });

  testWidgets('the poster is back at once when the reel leaves the stage', (
    tester,
  ) async {
    final feed = await _feed(tester);
    feed.pool.setWindow(active: reel);
    feed.loadHosts();
    await _show(tester, feed, reel);
    feed
      ..report(reel, 'ready')
      ..report(reel, 'playing');
    await tester.pump();
    await tester.pump(EmbedReelSurface.posterFadeOut);
    expect(_posterOpacity(tester), 0);

    feed.pool.setWindow(
      active: _tikTok('7000000000000000009'),
      neighbours: [reel],
    );
    await tester.pump();

    expect(_posterOpacity(tester), 1);
    await _close(tester, feed);
  });

  testWidgets(
    "an invalid TikTok video shows the can't-play fallback at once",
    (tester) async {
      final feed = await _feed(tester);
      feed.pool.setWindow(active: reel);
      feed.loadHosts();
      await _show(tester, feed, reel);

      feed.report(reel, 'error', {'code': 'tt_1001'});
      await tester.pump();

      expect(find.byKey(_fallback), findsOneWidget);
      expect(find.byKey(_poster), findsNothing);
      expect(
        feed
            .holding(reel)
            .scripts
            .where((s) => s.startsWith('smPlayer.assign(')),
        hasLength(1),
        reason: 'an invalid video is not retried',
      );
      await _close(tester, feed);
    },
  );

  for (final code in ['tt_2001', 'tt_3001']) {
    testWidgets(
      'a TikTok $code error is retried once behind the poster, then falls back',
      (tester) async {
        final feed = await _feed(tester);
        feed.pool.setWindow(active: reel);
        feed.loadHosts();
        await _show(tester, feed, reel);

        feed.report(reel, 'error', {'code': code});
        await tester.pump();
        expect(find.byKey(_fallback), findsNothing);
        expect(_posterOpacity(tester), 1);
        final assigns = feed
            .holding(reel)
            .scripts
            .where((s) => s.startsWith('smPlayer.assign('));
        expect(assigns, hasLength(2), reason: 'one silent retry');

        feed.report(reel, 'error', {'code': code});
        await tester.pump();
        expect(find.byKey(_fallback), findsOneWidget);
        await _close(tester, feed);
      },
    );
  }

  testWidgets(
    'a pre-rolled TikTok reel keeps its poster until it plays on screen',
    (tester) async {
      final feed = await _feed(tester);
      final current = _tikTok('7000000000000000001');
      feed.pool.setWindow(active: current, neighbours: [reel]);
      feed.loadHosts();
      await _show(tester, feed, reel);

      feed
        ..report(reel, 'ready')
        ..report(reel, 'prerolled')
        ..report(reel, 'paused');
      await tester.pump();
      expect(_posterOpacity(tester), 1);

      feed.pool.setWindow(active: reel, neighbours: [current]);
      await tester.pump();
      expect(_posterOpacity(tester), 1, reason: 'on screen, no frames yet');
      expect(feed.holding(reel).scripts.last, 'smPlayer.play()');

      feed.report(reel, 'playing');
      await tester.pump();
      await tester.pump(EmbedReelSurface.posterFadeOut);
      expect(_posterOpacity(tester), 0);

      await _close(tester, feed);
    },
  );
}
