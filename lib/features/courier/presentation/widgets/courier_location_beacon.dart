import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_location_reporter.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';

/// Keeps the rider's live location reported while they are on shift and the
/// app is in the foreground — the condition the 5 km matching relies on.
///
/// Renders nothing; it sits in the dashboard's tree (like
/// `CourierSigningEnrolment`) so it follows the profile it is given: going
/// online starts the reporter, going offline or backgrounding the app stops
/// it, and coming back to the app restarts it. Foreground only, on purpose —
/// a rider's position is not read when they are not looking at the app.
class CourierLocationBeacon extends ConsumerStatefulWidget {
  const CourierLocationBeacon({required this.profile, super.key});

  final CourierProfile profile;

  @override
  ConsumerState<CourierLocationBeacon> createState() =>
      _CourierLocationBeaconState();
}

class _CourierLocationBeaconState extends ConsumerState<CourierLocationBeacon>
    with WidgetsBindingObserver {
  /// Held rather than re-read so [dispose] can stop it without touching
  /// `ref` after the widget is gone.
  late final CourierLocationReporter _reporter;

  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _reporter = ref.read(courierLocationReporterProvider);
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(CourierLocationBeacon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.isOnline != widget.profile.isOnline) _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _foreground = false;
      case AppLifecycleState.inactive:
        // A notification shade or a phone call — transient, and stopping on
        // it would churn the GPS for nothing.
        return;
    }
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    if (widget.profile.isOnline && _foreground) {
      unawaited(_reporter.start());
    } else {
      _reporter.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reporter.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
