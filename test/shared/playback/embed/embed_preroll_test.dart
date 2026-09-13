import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_host_html.dart';
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

  String? get lastAssign {
    final assigns = scripts.where((s) => s.startsWith('smPlayer.assign('));
    return assigns.isEmpty ? null : assigns.last;
  }
}

EmbedRequest _youTube(String id) => EmbedRequest(
  EmbedSource(
    platform: SocialPlatform.youtube,
    externalId: id,
    permalink: 'https://www.youtube.com/shorts/$id',
  ),
);

Future<(EmbedPlayerPool, List<_FakeDriver>)> _pool({int slots = 3}) async {
  final pool = EmbedPlayerPool(
    slotCount: slots,
    origins: Future.value(
      const EmbedOrigins(
        appOrigin: 'https://app.test',
        webOrigin: 'https://web.test',
      ),
    ),
  );
  final drivers = [for (final slot in pool.slots) _FakeDriver(slot)];
  for (final driver in drivers) {
    driver.slot.attach(driver);
  }
  await Future<void>.delayed(Duration.zero);
  addTearDown(pool.dispose);
  return (pool, drivers);
}

/// Lets every host page that was asked to load report in.
void _loadHosts(List<_FakeDriver> drivers) {
  for (final driver in drivers) {
    if (driver.hosts.isNotEmpty) {
      driver.slot.handleEvent({
        'type': 'host_loaded',
        'origin': driver.hosts.last,
      });
    }
  }
}

_FakeDriver _holding(List<_FakeDriver> drivers, EmbedRequest request) =>
    drivers.firstWhere((d) => d.slot.key == request.key);

void main() {
  final a = _youTube('aaaaaaaaaaa');
  final b = _youTube('bbbbbbbbbbb');
  final c = _youTube('ccccccccccc');

  test('only the next reel pre-rolls; the reel on screen plays', () async {
    final (pool, drivers) = await _pool();

    pool.setWindow(active: a, neighbours: [b, c]);
    _loadHosts(drivers);

    expect(_holding(drivers, a).lastAssign, endsWith(',true,false,false)'));
    expect(_holding(drivers, b).lastAssign, endsWith(',false,false,true)'));
    expect(_holding(drivers, c).lastAssign, endsWith(',false,false,false)'));
    expect(_holding(drivers, b).slot.prerolls, isTrue);
    expect(_holding(drivers, a).slot.prerolls, isFalse);
  });

  test('nothing pre-rolls while the feed is in the background', () async {
    final (pool, drivers) = await _pool(slots: 2);

    pool
      ..setHostActive(false)
      ..setWindow(active: a, neighbours: [b]);
    _loadHosts(drivers);

    expect(_holding(drivers, b).lastAssign, endsWith(',false,false,false)'));
  });

  test('a pre-rolled reel starts playing the moment it is on screen', () async {
    final (pool, drivers) = await _pool(slots: 2);
    pool.setWindow(active: a, neighbours: [b]);
    _loadHosts(drivers);
    final next = _holding(drivers, b)
      ..slot.handleEvent({'type': 'playing', 'token': 1})
      ..scripts.clear();

    pool.setWindow(active: b, neighbours: [a]);

    expect(next.scripts, contains('smPlayer.play()'));
    expect(next.slot.prerolls, isFalse);
  });

  test('the host page keeps a pre-rolling reel muted until it is on screen', () {
    final html = embedHostHtml(origin: 'https://app.test');

    expect(html, contains('cur.preroll = !!preroll && !cur.wantPlay;'));
    expect(html, contains('if (cur.muted || !cur.wantPlay) yt.mute(); else yt.unMute();'));
    expect(html, contains('if (event.data === 1 && !cur.wantPlay)'));
  });
}
