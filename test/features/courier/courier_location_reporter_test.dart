import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_location_reporter.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/location_capture_service.dart';

/// A position source driven by the test: [nextFix] answers `current()`, and
/// [move] pushes a fix down the movement stream.
class _FakePositions implements CourierPositionSource {
  LocationCaptureResult nextFix = _at(27.7000, 85.3000);
  final StreamController<LocationCaptured> _moves =
      StreamController<LocationCaptured>.broadcast();
  int currentCalls = 0;
  int? distanceFilter;

  void move(LocationCaptured fix) => _moves.add(fix);

  bool get hasListener => _moves.hasListener;

  @override
  Future<LocationCaptureResult> current() async {
    currentCalls++;
    return nextFix;
  }

  @override
  Stream<LocationCaptured> movements({required int distanceFilterMetres}) {
    distanceFilter = distanceFilterMetres;
    return _moves.stream;
  }
}

/// A timer the test fires by hand, so "60 seconds later" is one call rather
/// than a minute of wall clock.
class _FakeTimer implements Timer {
  _FakeTimer(this.duration, this.callback);

  final Duration duration;
  final void Function() callback;
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;

  @override
  void cancel() => _active = false;

  void fire() {
    if (!_active) return;
    _active = false;
    callback();
  }
}

LocationCaptured _at(double latitude, double longitude) => LocationCaptured(
  latitude: latitude,
  longitude: longitude,
  accuracyMetres: 10,
);

/// Roughly [metres] north of 27.7000, 85.3000 (1° latitude ≈ 111 km).
LocationCaptured _north(double metres) => _at(27.7000 + metres / 111000, 85.3);

void main() {
  late _FakePositions positions;
  late List<LocationCaptured> sent;
  late DateTime now;
  late List<_FakeTimer> timers;
  late CourierLocationReporter reporter;

  /// Lets the stream deliveries and the async send settle.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  _FakeTimer? activeTimer() =>
      timers.where((t) => t.isActive).isEmpty
          ? null
          : timers.lastWhere((t) => t.isActive);

  setUp(() {
    positions = _FakePositions();
    sent = [];
    now = DateTime.utc(2026, 10, 8, 10);
    timers = [];
    reporter = CourierLocationReporter(
      positions: positions,
      send: (fix) async => sent.add(fix),
      now: () => now,
      timer: (duration, callback) {
        final timer = _FakeTimer(duration, callback);
        timers.add(timer);
        return timer;
      },
    );
  });

  tearDown(() => reporter.stop());

  test('going online sends a position at once', () async {
    await reporter.start();

    expect(sent, hasLength(1));
    expect(sent.single.latitude, 27.7);
    expect(reporter.isRunning, isTrue);
    expect(positions.distanceFilter, 200);
    expect(activeTimer()?.duration, const Duration(seconds: 60));
  });

  test('a small move inside the minute is not sent', () async {
    await reporter.start();

    now = now.add(const Duration(seconds: 20));
    positions.move(_north(120));
    await settle();

    expect(sent, hasLength(1));
  });

  test('moving more than 200 m is sent straight away', () async {
    await reporter.start();

    now = now.add(const Duration(seconds: 20));
    positions.move(_north(260));
    await settle();

    expect(sent, hasLength(2));
    expect(sent.last.latitude, closeTo(27.7 + 260 / 111000, 1e-9));
  });

  test('distance is measured from the last report, not the first', () async {
    await reporter.start();

    now = now.add(const Duration(seconds: 10));
    positions.move(_north(260));
    await settle();
    expect(sent, hasLength(2));

    // 150 m beyond the last report: under the threshold again.
    now = now.add(const Duration(seconds: 10));
    positions.move(_north(410));
    await settle();
    expect(sent, hasLength(2));
  });

  test('standing still, the heartbeat sends every 60 s', () async {
    await reporter.start();
    expect(sent, hasLength(1));

    now = now.add(const Duration(seconds: 60));
    activeTimer()!.fire();
    await settle();
    expect(sent, hasLength(2));

    now = now.add(const Duration(seconds: 60));
    activeTimer()!.fire();
    await settle();
    expect(sent, hasLength(3));
    expect(positions.currentCalls, 3);
  });

  test('a movement report restarts the minute', () async {
    await reporter.start();
    final first = activeTimer();

    now = now.add(const Duration(seconds: 30));
    positions.move(_north(300));
    await settle();

    expect(first!.isActive, isFalse, reason: 'old heartbeat replaced');
    expect(activeTimer(), isNotNull);
    expect(activeTimer(), isNot(same(first)));
  });

  test('shouldSend: first, after the interval, or beyond 200 m', () async {
    expect(reporter.shouldSend(_north(0)), isTrue, reason: 'nothing sent');
    await reporter.start();

    expect(reporter.shouldSend(_north(150)), isFalse);
    expect(reporter.shouldSend(_north(250)), isTrue);

    now = now.add(const Duration(seconds: 59));
    expect(reporter.shouldSend(_north(0)), isFalse);
    now = now.add(const Duration(seconds: 1));
    expect(reporter.shouldSend(_north(0)), isTrue);
  });

  test('stopping (offline or backgrounded) sends nothing more', () async {
    await reporter.start();
    final heartbeat = activeTimer()!;

    reporter.stop();
    await settle();
    expect(reporter.isRunning, isFalse);
    expect(heartbeat.isActive, isFalse);
    expect(positions.hasListener, isFalse);

    positions.move(_north(1000));
    heartbeat.fire();
    await settle();
    expect(sent, hasLength(1));
  });

  test('starting twice does not double up', () async {
    await reporter.start();
    await reporter.start();
    expect(sent, hasLength(1));
    expect(timers.where((t) => t.isActive), hasLength(1));
  });

  test('restarting after a stop reports at once again', () async {
    await reporter.start();
    reporter.stop();
    now = now.add(const Duration(seconds: 5));
    await reporter.start();
    expect(sent, hasLength(2));
  });

  test('a refused permission stops it — no prompt every minute', () async {
    positions.nextFix = const LocationPermissionDenied();
    await reporter.start();

    expect(sent, isEmpty);
    expect(reporter.isRunning, isFalse);
    expect(activeTimer(), isNull);
    expect(positions.hasListener, isFalse);
  });

  test('a failed send is silent and the next one still goes', () async {
    var failNext = true;
    final flaky = CourierLocationReporter(
      positions: positions,
      send: (fix) async {
        if (failNext) {
          failNext = false;
          throw Exception('400 offline');
        }
        sent.add(fix);
      },
      now: () => now,
      timer: (duration, callback) {
        final timer = _FakeTimer(duration, callback);
        timers.add(timer);
        return timer;
      },
    );
    addTearDown(flaky.stop);

    await expectLater(flaky.start(), completes);
    expect(sent, isEmpty);

    now = now.add(const Duration(seconds: 60));
    activeTimer()!.fire();
    await settle();
    expect(sent, hasLength(1));
  });

  test('losing the fix indoors keeps the heartbeat going', () async {
    await reporter.start();

    positions.nextFix = const LocationTimedOut();
    activeTimer()!.fire();
    await settle();
    expect(sent, hasLength(1));
    expect(reporter.isRunning, isTrue);
    expect(activeTimer(), isNotNull);

    positions.nextFix = _north(0);
    now = now.add(const Duration(seconds: 60));
    activeTimer()!.fire();
    await settle();
    expect(sent, hasLength(2));
  });
}
