import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/location_capture_service.dart';

/// Where the rider's position comes from.
///
/// An interface so the reporter can be tested with a scripted position
/// stream; the real one is [GeolocatorCourierPositionSource].
abstract interface class CourierPositionSource {
  /// One fix now. Never prompts: asking is left to the map and to going
  /// online, which the rider sees happen. A reporter that prompted would ask
  /// again on every return to the app.
  Future<LocationCaptureResult> current();

  /// Fixes as the rider moves at least [distanceFilterMetres]. Only listened
  /// to after [current] succeeded, so permission is already settled.
  Stream<LocationCaptured> movements({required int distanceFilterMetres});
}

class GeolocatorCourierPositionSource implements CourierPositionSource {
  const GeolocatorCourierPositionSource(this._capture);

  final LocationCaptureService _capture;

  @override
  Future<LocationCaptureResult> current() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        return const LocationPermissionDeniedForever();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationPermissionDenied();
      }
    } on Object catch (error) {
      return LocationCaptureFailed(error.toString());
    }
    // Granted, so the shared capture will not prompt; it still reports
    // services-off and timeouts as themselves.
    return _capture.capture(timeout: const Duration(seconds: 10));
  }

  @override
  Stream<LocationCaptured> movements({required int distanceFilterMetres}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilterMetres,
        ),
      ).map(
        (position) => LocationCaptured(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMetres: position.accuracy,
        ),
      );
}

/// Sends the rider's live position while they are online and the app is in
/// the foreground: once on going online, then every [interval], and sooner
/// whenever they have moved more than [minDistanceMetres] since the last one.
///
/// This is what makes "riders within 5 km of the pick-up" true. Without it
/// the server falls back to the centre of the rider's home area, which for a
/// rider out on the road can be the wrong side of the city.
///
/// Never in the way: nothing awaits it from the UI, and a failed report is
/// a debug log, not an error — the next one is at most [interval] away. A
/// refused permission stops it rather than re-prompting every minute.
class CourierLocationReporter {
  CourierLocationReporter({
    required CourierPositionSource positions,
    required Future<void> Function(LocationCaptured fix) send,
    DateTime Function()? now,
    Timer Function(Duration, void Function())? timer,
    this.interval = const Duration(seconds: 60),
    this.minDistanceMetres = 200,
  }) : _positions = positions,
       _send = send,
       _now = now ?? DateTime.now,
       _timer = timer ?? Timer.new;

  final CourierPositionSource _positions;
  final Future<void> Function(LocationCaptured fix) _send;
  final DateTime Function() _now;
  final Timer Function(Duration, void Function()) _timer;

  final Duration interval;
  final double minDistanceMetres;

  bool _running = false;
  Timer? _heartbeat;
  StreamSubscription<LocationCaptured>? _movements;
  LocationCaptured? _lastSent;
  DateTime? _lastSentAt;
  bool _sending = false;

  /// Bumped by every start and stop, so a start still waiting on its first
  /// fix knows it was overtaken and does not subscribe a second time.
  int _session = 0;

  bool get isRunning => _running;

  /// Starts reporting. Safe to call repeatedly — a second call while running
  /// does nothing, so the caller can simply call it on every "should run".
  Future<void> start() async {
    if (_running) return;
    _running = true;
    final session = ++_session;

    final fix = await _currentFix();
    // Stopped (or stopped and restarted) while the fix was coming in.
    if (session != _session) return;
    if (fix is! LocationCaptured) {
      // Denied, off, or no fix. Stop rather than retry on a timer: a retry
      // would re-prompt a rider who just said no, every minute.
      _log('no position ($fix); not reporting');
      stop();
      return;
    }
    await _report(fix, force: true);
    if (session != _session) return;

    _movements = _positions
        .movements(distanceFilterMetres: minDistanceMetres.round())
        .listen(
          (moved) => unawaited(_report(moved)),
          onError: (Object error) => _log('position stream: $error'),
        );
    _scheduleHeartbeat();
  }

  /// Stops reporting. The next [start] sends at once rather than waiting out
  /// an interval from before the rider went offline.
  void stop() {
    _running = false;
    _session++;
    _heartbeat?.cancel();
    _heartbeat = null;
    unawaited(_movements?.cancel());
    _movements = null;
    _lastSent = null;
    _lastSentAt = null;
  }

  /// Whether [fix] is worth sending: nothing sent yet, an interval has passed,
  /// or the rider has moved further than [minDistanceMetres].
  bool shouldSend(LocationCaptured fix) {
    final last = _lastSent;
    final lastAt = _lastSentAt;
    if (last == null || lastAt == null) return true;
    if (_now().difference(lastAt) >= interval) return true;
    return distanceBetweenMetres(
          last.latitude,
          last.longitude,
          fix.latitude,
          fix.longitude,
        ) >
        minDistanceMetres;
  }

  Future<void> _report(LocationCaptured fix, {bool force = false}) async {
    if (!_running || _sending) return;
    if (!force && !shouldSend(fix)) return;
    _sending = true;
    _lastSent = fix;
    _lastSentAt = _now();
    try {
      await _send(fix);
    } catch (error) {
      _log('report failed: $error');
    } finally {
      _sending = false;
    }
    // A movement report restarts the clock, so the heartbeat only fills the
    // gaps when the rider is standing still.
    if (_running) _scheduleHeartbeat();
  }

  void _scheduleHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = _timer(interval, () => unawaited(_beat()));
  }

  Future<void> _beat() async {
    if (!_running) return;
    final fix = await _currentFix();
    if (!_running) return;
    switch (fix) {
      case final LocationCaptured captured:
        await _report(captured, force: true);
      case LocationPermissionDenied() ||
          LocationPermissionDeniedForever() ||
          LocationServicesDisabled():
        // Taken away mid-shift. Asking again every minute would nag; the
        // next go-online or return to the app tries once more.
        _log('position no longer available ($fix); stopping');
        stop();
      default:
        // Lost the fix (indoors, say). Keep the heartbeat going; the next
        // one may have it.
        _scheduleHeartbeat();
    }
  }

  /// A throwing position source is treated as "no fix" rather than left to
  /// escape — an exception here would strand [_running] at true and the
  /// reporter could never be started again.
  Future<LocationCaptureResult> _currentFix() async {
    try {
      return await _positions.current();
    } catch (error) {
      return LocationCaptureFailed(error.toString());
    }
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[courier-location] $message');
  }
}
