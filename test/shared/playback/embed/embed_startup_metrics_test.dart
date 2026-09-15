import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_startup_metrics.dart';
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

  void finishLoad() =>
      slot.handleEvent({'type': 'host_loaded', 'origin': hosts.last});

  int get _token => int.parse(
    RegExp(
      r'smPlayer\.assign\((\d+),',
    ).allMatches(scripts.join('\n')).last.group(1)!,
  );

  /// The host page reports [type] for the current reel.
  void report(String type) =>
      slot.handleEvent({'type': type, 'token': _token});

  int get retries => scripts.where((s) => s == 'smPlayer.retryStart()').length;
}

const _web = 'https://web.test';

EmbedRequest _request(SocialPlatform platform, String id) => EmbedRequest(
  EmbedSource(
    platform: platform,
    externalId: id,
    permalink: 'https://example.test/$id',
  ),
);

_FakeDriver _slot({
  EmbedStartupMetrics? metrics,
  Duration startTimeout = const Duration(seconds: 30),
}) {
  final slot = EmbedSlot(0, metrics: metrics, startTimeout: startTimeout);
  final driver = _FakeDriver(slot);
  slot.attach(driver);
  addTearDown(slot.dispose);
  return driver;
}

void main() {
  final tikTok = _request(SocialPlatform.tiktok, '7685232277147618581');

  test('times a cold start: assign, player ready, first frame', () {
    var now = Duration.zero;
    final metrics = EmbedStartupMetrics(clock: () => now);
    final d = _slot(metrics: metrics);

    d.slot.assign(tikTok, origin: _web, play: true, muted: false);
    d.finishLoad();
    now = const Duration(milliseconds: 900);
    d.report('ready');
    now = const Duration(milliseconds: 2100);
    d.report('playing');

    final sample = metrics.samples.single;
    expect(sample.key, 'tiktok:7685232277147618581');
    expect(sample.platform, 'tiktok');
    expect(sample.warm, isFalse);
    expect(sample.prerolled, isFalse);
    expect(sample.assignToReady, const Duration(milliseconds: 900));
    expect(sample.assignToFirstFrame, const Duration(milliseconds: 2100));
    expect(sample.playToFirstFrame, const Duration(milliseconds: 2100));
    expect(sample.startRetry, isNull);
  });

  test('times a pre-loaded reel from the swipe that plays it', () {
    var now = Duration.zero;
    final metrics = EmbedStartupMetrics(clock: () => now);
    final d = _slot(metrics: metrics);

    d.slot.assign(
      tikTok,
      origin: _web,
      play: false,
      muted: false,
      preroll: true,
    );
    d.finishLoad();
    now = const Duration(milliseconds: 800);
    d.report('ready');
    now = const Duration(milliseconds: 1900);
    d
      ..report('prerolled')
      ..report('paused');
    expect(d.slot.hasStarted, isFalse, reason: 'held off screen, not shown');
    expect(metrics.samples, isEmpty);
    expect(d.retries, 0, reason: 'a pre-roll pauses on purpose');

    now = const Duration(seconds: 6);
    d.slot.play();
    now = const Duration(milliseconds: 6180);
    d
      ..report('playing')
      ..report('playing');

    final sample = metrics.samples.single;
    expect(sample.warm, isTrue);
    expect(sample.prerolled, isTrue);
    expect(sample.playToFirstFrame, const Duration(milliseconds: 180));
    expect(sample.assignToFirstFrame, const Duration(milliseconds: 6180));
    expect(
      d.scripts.where((s) => s.startsWith('smPlayer.assign(')),
      hasLength(1),
      reason: 'the swipe reuses the loaded player',
    );
    expect(d.scripts.last, 'smPlayer.play()');
  });

  test(
    'a TikTok start with no frames in time is retried once, muted, and logged',
    () async {
      final metrics = EmbedStartupMetrics();
      final d = _slot(
        metrics: metrics,
        startTimeout: const Duration(milliseconds: 40),
      );

      d.slot.assign(tikTok, origin: _web, play: true, muted: false);
      d.finishLoad();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        d.retries,
        0,
        reason: 'a player still loading is left to the ready timeout',
      );

      d.report('ready');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(d.retries, 1);
      expect(metrics.startRetries, 1);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(d.retries, 1, reason: 'once per reel');

      d.report('playing');
      expect(metrics.samples.single.startRetry, 'timeout');
    },
  );

  test('a TikTok player that pauses before its first frame restarts at once',
      () {
    final metrics = EmbedStartupMetrics();
    final d = _slot(metrics: metrics);

    d.slot.assign(tikTok, origin: _web, play: true, muted: false);
    d
      ..finishLoad()
      ..report('ready')
      ..report('paused');
    expect(d.retries, 1);

    d.report('paused');
    expect(d.retries, 1);
    expect(d.slot.hasStarted, isFalse);

    d.report('playing');
    expect(metrics.samples.single.startRetry, 'paused');
    expect(metrics.startRetries, 1);
  });

  test('a start whose video time never moves is retried, even if "playing"',
      () async {
    final metrics = EmbedStartupMetrics();
    final d = _slot(
      metrics: metrics,
      startTimeout: const Duration(milliseconds: 40),
    );

    d.slot.assign(tikTok, origin: _web, play: true, muted: false);
    d
      ..finishLoad()
      ..report('ready')
      ..report('playing');
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(d.retries, 1);
    expect(metrics.samples.single.startRetry, isNull, reason: 'timed at 1');
    expect(metrics.startRetries, 1);
  });

  test('moving video time ends the start watch', () async {
    final d = _slot(startTimeout: const Duration(milliseconds: 20));

    d.slot.assign(tikTok, origin: _web, play: true, muted: false);
    d
      ..finishLoad()
      ..report('ready')
      ..report('playing')
      ..report('progress');
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(d.retries, 0);
  });

  test('a reel paused by the viewer after it played is not retried', () async {
    final d = _slot(startTimeout: const Duration(milliseconds: 20));

    d.slot.assign(tikTok, origin: _web, play: true, muted: false);
    d
      ..finishLoad()
      ..report('ready')
      ..report('playing')
      ..report('progress');
    d.slot.pause();
    d.report('paused');
    d.slot.play();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(d.retries, 0);
  });

  test('other platforms report blocked playback themselves', () async {
    final d = _slot(startTimeout: const Duration(milliseconds: 20));

    d.slot.assign(
      _request(SocialPlatform.youtube, 'aaaaaaaaaaa'),
      origin: 'https://app.test',
      play: true,
      muted: false,
    );
    d
      ..finishLoad()
      ..report('ready')
      ..report('paused');
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(d.retries, 0);
  });

  test('keeps the latest samples and gives medians by platform and warmth', () {
    final metrics = EmbedStartupMetrics(capacity: 3);
    EmbedStartupSample sample(String key, int ms, {bool warm = true}) =>
        EmbedStartupSample(
          key: key,
          warm: warm,
          prerolled: warm,
          assignToFirstFrame: Duration(milliseconds: ms),
          playToFirstFrame: Duration(milliseconds: ms),
        );

    metrics
      ..record(sample('tiktok:1', 5000, warm: false))
      ..record(sample('tiktok:2', 300))
      ..record(sample('tiktok:3', 100))
      ..record(sample('youtube:a', 200));

    expect(metrics.samples.map((s) => s.key), [
      'tiktok:2',
      'tiktok:3',
      'youtube:a',
    ]);
    expect(
      metrics.medianPlayToFirstFrame(platform: 'tiktok'),
      const Duration(milliseconds: 200),
    );
    expect(metrics.medianPlayToFirstFrame(), const Duration(milliseconds: 200));
    expect(metrics.medianPlayToFirstFrame(warm: false), isNull);
  });
}
