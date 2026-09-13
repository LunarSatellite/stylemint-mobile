import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_origins.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_pool.dart';
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

  /// The host page finished loading and reported in.
  void finishLoad() =>
      slot.handleEvent({'type': 'host_loaded', 'origin': hosts.last});

  List<String> get assigns =>
      scripts.where((s) => s.startsWith('smPlayer.assign(')).toList();

  int get lastToken => int.parse(
    RegExp(r'^smPlayer\.assign\((\d+),').firstMatch(assigns.last)!.group(1)!,
  );
}

const _origins = EmbedOrigins(
  appOrigin: 'https://app.test',
  webOrigin: 'https://web.test',
);

EmbedRequest _youTube(String id) => EmbedRequest(
  EmbedSource(
    platform: SocialPlatform.youtube,
    externalId: id,
    permalink: 'https://www.youtube.com/shorts/$id',
  ),
);

EmbedRequest _tikTok(String id) => EmbedRequest(
  EmbedSource(
    platform: SocialPlatform.tiktok,
    externalId: id,
    permalink: 'https://www.tiktok.com/@maker/video/$id',
  ),
);

Future<(EmbedPlayerPool, List<_FakeDriver>)> _pool({
  int slots = 2,
  Duration readyTimeout = const Duration(seconds: 12),
}) async {
  final pool = EmbedPlayerPool(
    slotCount: slots,
    origins: Future.value(_origins),
    readyTimeout: readyTimeout,
  );
  final drivers = [for (final slot in pool.slots) _FakeDriver(slot)];
  for (final driver in drivers) {
    driver.slot.attach(driver);
  }
  await Future<void>.delayed(Duration.zero);
  addTearDown(pool.dispose);
  return (pool, drivers);
}

void main() {
  final a = _youTube('aaaaaaaaaaa');
  final b = _youTube('bbbbbbbbbbb');
  final c = _youTube('ccccccccccc');

  test('plays the reel on screen and cues the next one in another slot', () async {
    final (pool, d) = await _pool();

    pool.setWindow(active: a, neighbours: [b]);
    expect(d[0].hosts, ['https://app.test']);
    expect(d[1].hosts, ['https://app.test']);
    expect(d[0].scripts, isEmpty, reason: 'nothing runs before the page loads');

    d[0].finishLoad();
    d[1].finishLoad();
    expect(d[0].assigns.single, contains('"youtube","aaaaaaaaaaa"'));
    // wantPlay, muted, preroll: the next reel pre-rolls.
    expect(d[0].assigns.single, endsWith(',true,false,false)'));
    expect(d[1].assigns.single, contains('"bbbbbbbbbbb"'));
    expect(d[1].assigns.single, endsWith(',false,false,true)'));
  });

  test('a swipe plays the cued reel in place and recycles the old slot', () async {
    final (pool, d) = await _pool();
    pool.setWindow(active: a, neighbours: [b]);
    d[0].finishLoad();
    d[1].finishLoad();

    pool.setWindow(active: b, neighbours: [c, a]);

    expect(d[1].assigns, hasLength(1), reason: 'b was already cued');
    expect(d[1].scripts.last, 'smPlayer.play()');
    expect(d[0].scripts, contains('smPlayer.pause()'));
    expect(d[0].assigns.last, contains('"ccccccccccc"'));
    expect(d[0].hosts, hasLength(1), reason: 'same origin, no reload');
  });

  test('loads TikTok under the web origin and YouTube under the app origin', () async {
    final (pool, d) = await _pool(slots: 1);

    pool.setWindow(active: _tikTok('7000000000000000001'));
    expect(d[0].hosts, ['https://web.test']);
    d[0].finishLoad();
    expect(d[0].assigns.single, contains('"tiktok","7000000000000000001"'));

    pool.setWindow(active: a);
    expect(d[0].hosts, ['https://web.test', 'https://app.test']);
    expect(d[0].assigns, hasLength(1), reason: 'queued until the page loads');
    d[0].finishLoad();
    expect(d[0].assigns.last, contains('"youtube","aaaaaaaaaaa"'));
  });

  test('ignores events from a reel the slot has moved on from', () async {
    final (pool, d) = await _pool(slots: 1);
    pool.setWindow(active: a);
    d[0].finishLoad();
    final stale = d[0].lastToken;

    pool.setWindow(active: b);
    final slot = pool.slots.single;
    slot.handleEvent({'type': 'playing', 'token': stale});
    expect(slot.state, EmbedPlayerState.loading);

    slot.handleEvent({'type': 'playing', 'token': d[0].lastToken});
    expect(slot.state, EmbedPlayerState.playing);
    expect(slot.hasStarted, isTrue);
  });

  test('pauses while the feed is hidden and resumes when it is shown', () async {
    final (pool, d) = await _pool(slots: 1);
    pool.setWindow(active: a);
    d[0].finishLoad();

    pool.setHostActive(false);
    expect(d[0].scripts.last, 'smPlayer.pause()');

    pool.setHostActive(true);
    expect(d[0].scripts.last, 'smPlayer.play()');
  });

  test('retries an embed that timed out once, then gives up', () async {
    final (pool, d) = await _pool(
      slots: 1,
      readyTimeout: const Duration(milliseconds: 50),
    );
    pool.setWindow(active: a);
    d[0].finishLoad();

    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(d[0].assigns, hasLength(2));
    expect(pool.hasGivenUp(a.key), isFalse);

    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(pool.slots.single.state, EmbedPlayerState.failed);
    expect(pool.hasGivenUp(a.key), isTrue);
    expect(d[0].assigns, hasLength(2));
  });

  test('does not retry a video whose owner turned embedding off', () async {
    final (pool, d) = await _pool(slots: 1);
    pool.setWindow(active: a);
    d[0].finishLoad();

    pool.slots.single.handleEvent({
      'type': 'error',
      'token': d[0].lastToken,
      'code': 'yt_150',
    });
    await Future<void>.delayed(Duration.zero);

    expect(pool.hasGivenUp(a.key), isTrue);
    expect(d[0].assigns, hasLength(1));
  });

  test('reports a reel muted by an autoplay block and unmutes on request', () async {
    final (pool, d) = await _pool(slots: 1);
    pool.setWindow(active: a);
    d[0].finishLoad();

    pool.slots.single.handleEvent({
      'type': 'autoplayBlocked',
      'token': d[0].lastToken,
    });
    expect(pool.muted, isTrue);

    pool.setMuted(false);
    expect(pool.muted, isFalse);
    expect(d[0].scripts.last, 'smPlayer.setMuted(false)');
  });

  test('trim frees cued neighbours and stops cueing new ones', () async {
    final (pool, d) = await _pool();
    pool.setWindow(active: a, neighbours: [b]);
    d[0].finishLoad();
    d[1].finishLoad();

    pool.trim();
    expect(pool.slots[1].key, isNull);
    expect(d[1].scripts.last, startsWith('smPlayer.stop('));
    expect(pool.slots[0].key, a.key);

    pool.setWindow(active: a, neighbours: [b]);
    expect(pool.slots[1].key, isNull);
  });
}
