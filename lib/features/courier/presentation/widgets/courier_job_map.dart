import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/location_capture_service.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgent = 'app.stylemint.stylemint_mobile_frontend';

/// The job, drawn on the app's own map: the shop, the recipient's door, the
/// rider, and the way between them.
///
/// This replaced handing the rider to an external maps app. That hand-off
/// (`geo:` URIs) did nothing on phones without a maps app registered for the
/// scheme, which is how "Navigate is not working" was reported — and a rider
/// bounced out of StyleMint also loses the package number and the call
/// buttons. Everything needed to do the run is now on one screen; "Open in
/// Google Maps" survives only as an optional extra.
///
/// The route line comes from the public OSRM server when it answers within a
/// few seconds, with its distance and time. When it does not, straight dashed
/// lines stand in — routing is a convenience, never what makes this usable.
class CourierJobMap extends ConsumerStatefulWidget {
  const CourierJobMap({
    required this.job,
    this.topInset = 0,
    this.bottomInset = 0,
    super.key,
  });

  final CourierJob job;

  /// Space covered by chrome at the top (the app bar) and the bottom (the
  /// job sheet at rest), so the camera frames the run in what is visible.
  final double topInset;
  final double bottomInset;

  static const recenterKey = ValueKey<String>('courier-job-recenter');
  static const openExternalKey = ValueKey<String>('courier-job-open-external');
  static const routeSummaryKey = ValueKey<String>('courier-job-route-summary');

  /// Google Maps directions for [job]: to the door, through the shop while
  /// the parcel is still to be collected. Null when there is nowhere to go.
  @visibleForTesting
  static Uri? externalDirectionsUri(CourierJob job) {
    final pickup = job.pickup.point;
    final dropoff = job.dropoff.point;
    final heading = job.status.headingToDropoff;
    final finalStop = dropoff ?? (heading ? null : pickup);
    if (finalStop == null) return null;
    final via = !heading && pickup != null && dropoff != null ? pickup : null;
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'travelmode': 'driving',
      'destination': '${finalStop.latitude},${finalStop.longitude}',
      if (via != null) 'waypoints': '${via.latitude},${via.longitude}',
    });
  }

  @override
  ConsumerState<CourierJobMap> createState() => _CourierJobMapState();
}

class _CourierJobMapState extends ConsumerState<CourierJobMap> {
  final MapController _controller = MapController();
  StreamSubscription<LocationCaptured>? _follow;

  LocationCaptureResult? _location;
  LatLng? _me;
  bool _mapReady = false;

  /// Framed once the rider's own position first arrives, after which the
  /// camera is theirs — re-framing on every GPS update would fight their
  /// panning.
  bool _framedWithMe = false;

  CourierRoute? _route;

  /// Where the current route was planned from, so a route is re-planned when
  /// the rider has actually moved, not on every fix.
  LatLng? _plannedFrom;
  int _planGeneration = 0;

  static const _replanAfterMetres = 300.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_locate());
      // Planned straight away from the stops alone; re-planned from the
      // rider once a fix lands.
      unawaited(_plan());
    });
  }

  @override
  void didUpdateWidget(covariant CourierJobMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Picking up changes the leg the route should show — and the camera
    // should frame the new leg rather than stay where the old one left it.
    if (oldWidget.job.status != widget.job.status) {
      unawaited(_plan());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fit();
      });
    }
  }

  @override
  void dispose() {
    unawaited(_follow?.cancel());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final locator = ref.read(riderLocatorProvider);
    final result = await locator.locate();
    if (!mounted) return;
    setState(() => _location = result);
    if (result is! LocationCaptured) return;
    _moveTo(LatLng(result.latitude, result.longitude));
    await _follow?.cancel();
    _follow = locator.follow().listen(
      (fix) => _moveTo(LatLng(fix.latitude, fix.longitude)),
      // A dropped GPS stream leaves the last known dot in place.
      onError: (Object _) {},
    );
  }

  void _moveTo(LatLng position) {
    if (!mounted) return;
    setState(() => _me = position);
    if (!_framedWithMe && _mapReady) {
      _framedWithMe = true;
      _fit();
    }
    final from = _plannedFrom;
    if (from == null ||
        distanceBetweenMetres(
              from.latitude,
              from.longitude,
              position.latitude,
              position.longitude,
            ) >
            _replanAfterMetres) {
      unawaited(_plan());
    }
  }

  LatLng? _point(CourierJobStop stop) {
    final point = stop.point;
    return point == null ? null : LatLng(point.latitude, point.longitude);
  }

  /// The stops still ahead: the shop only until the parcel is collected.
  ///
  /// After pick-up the leg is rider → door. Without a GPS fix that is one
  /// point, which used to leave no line at all — the shop-to-door link the
  /// rider had been following vanished the moment they tapped "Picked up".
  /// So with no fix the line stays shop → door until the rider's dot lands.
  List<LatLng> get _stopsAhead {
    final job = widget.job;
    if (job.status.isFinished) return const [];
    final pickup = _point(job.pickup);
    final dropoff = _point(job.dropoff);
    final ahead = [
      ?_me,
      if (!job.status.headingToDropoff) ?pickup,
      ?dropoff,
    ];
    return ahead.length >= 2 ? ahead : [?pickup, ?dropoff];
  }

  /// Everything the camera should frame.
  List<LatLng> get _framePoints => [
    ?_me,
    ?_point(widget.job.pickup),
    ?_point(widget.job.dropoff),
  ];

  Future<void> _plan() async {
    final stops = _stopsAhead;
    final generation = ++_planGeneration;
    _plannedFrom = _me;
    if (stops.length < 2) {
      if (mounted) setState(() => _route = null);
      return;
    }
    final route = await ref
        .read(courierRoutePlannerProvider)
        .plan(
          stops
              .map((p) => GeoPoint(p.latitude, p.longitude))
              .toList(growable: false),
        );
    if (!mounted || generation != _planGeneration) return;
    setState(() => _route = route);
  }

  EdgeInsets get _framePadding => EdgeInsets.fromLTRB(
    56,
    widget.topInset + 72,
    56,
    widget.bottomInset + 40,
  );

  void _fit() {
    final points = _framePoints;
    if (!_mapReady || points.isEmpty) return;
    _controller.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: _framePadding,
        maxZoom: 16.5,
      ),
    );
  }

  /// The optional hand-off: Google Maps directions in the browser or app,
  /// through the pick-up while it is still ahead. The screen is complete
  /// without it.
  Future<void> _openExternal() async {
    final uri = CourierJobMap.externalDirectionsUri(widget.job);
    if (uri == null) {
      SmSnackbar.error(context, 'No drop-off location for this delivery.');
      return;
    }

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      launched = false;
    }
    if (!launched && mounted) {
      SmSnackbar.error(
        context,
        "Couldn't open Google Maps. The route is on this map.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _point(widget.job.pickup);
    final dropoff = _point(widget.job.dropoff);
    final frame = _framePoints;
    final tiles = ref.watch(courierMapTilesEnabledProvider);

    if (frame.isEmpty) {
      return _NoPoints(
        locating: _location == null,
        location: _location,
        onRetry: _locate,
      );
    }

    final heading = widget.job.status.headingToDropoff;
    final route = _route;
    final stops = _stopsAhead;

    return Stack(
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: frame.first,
            initialZoom: 15,
            initialCameraFit: frame.length < 2
                ? null
                : CameraFit.coordinates(
                    coordinates: frame,
                    padding: _framePadding,
                    maxZoom: 16.5,
                  ),
            backgroundColor: DesignTokens.surfaceRaised,
            onMapReady: () {
              _mapReady = true;
              if (_me != null && !_framedWithMe) {
                _framedWithMe = true;
                _fit();
              }
            },
            interactionOptions: const InteractionOptions(
              flags:
                  InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            if (tiles)
              TileLayer(
                urlTemplate: _osmTileUrl,
                userAgentPackageName: _osmUserAgent,
                // OSM's tile policy forbids prefetching and bulk download.
                panBuffer: 0,
                keepBuffer: 1,
                tileDisplay: const TileDisplay.instantaneous(),
                errorTileCallback: (_, _, _) {},
              ),
            PolylineLayer(
              polylines: [
                if (route != null)
                  Polyline(
                    points: route.path
                        .map((p) => LatLng(p.latitude, p.longitude))
                        .toList(growable: false),
                    color: DesignTokens.primaryGreen,
                    strokeWidth: 5,
                  )
                else if (stops.length >= 2)
                  // No road route: straight, dashed, so it never reads as
                  // the way to ride.
                  Polyline(
                    points: stops,
                    color: DesignTokens.primaryGreen.withValues(alpha: 0.8),
                    strokeWidth: 3,
                    pattern: StrokePattern.dashed(segments: const [12, 8]),
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                if (pickup != null)
                  Marker(
                    point: pickup,
                    width: 44,
                    height: 44,
                    child: _StopPin(
                      icon: Icons.storefront_rounded,
                      color: DesignTokens.primaryGreen,
                      dimmed: heading,
                      semanticLabel: 'Pick-up',
                    ),
                  ),
                if (dropoff != null)
                  Marker(
                    point: dropoff,
                    width: 44,
                    height: 44,
                    child: const _StopPin(
                      icon: Icons.home_rounded,
                      color: DesignTokens.colorError,
                      dimmed: false,
                      semanticLabel: 'Drop-off',
                    ),
                  ),
                if (_me != null)
                  Marker(
                    point: _me!,
                    width: 22,
                    height: 22,
                    child: const _MeDot(),
                  ),
              ],
            ),
            // OSM requires the credit to stay visible.
            if (tiles)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 4,
                    bottom: widget.bottomInset + 2,
                  ),
                  child: const ColoredBox(
                    color: Color(0xCC000000),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 9, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Distance and time, when OSRM answered; a location prompt when the
        // rider's own dot is missing for a reason they can fix.
        Positioned(
          top: widget.topInset + DesignTokens.s8,
          left: DesignTokens.s16,
          right: DesignTokens.s16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (route != null &&
                  (route.distanceMetres != null ||
                      route.durationSeconds != null))
                _Chip(
                  key: CourierJobMap.routeSummaryKey,
                  icon: Icons.route_rounded,
                  text: routeSummary(route),
                ),
              if (_locationProblem case final problem?) ...[
                const SizedBox(height: DesignTokens.s8),
                _LocationProblem(
                  message: problem,
                  onFix: _location is LocationPermissionDenied ||
                          _location is LocationTimedOut ||
                          _location is LocationCaptureFailed
                      ? _locate
                      : () => ref
                            .read(riderLocatorProvider)
                            .openSettings(_location),
                ),
              ],
            ],
          ),
        ),

        Positioned(
          right: DesignTokens.s16,
          bottom: widget.bottomInset + DesignTokens.s16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                key: CourierJobMap.openExternalKey,
                heroTag: 'courier-job-external',
                tooltip: 'Open in Google Maps',
                backgroundColor: DesignTokens.bgAppBody,
                foregroundColor: DesignTokens.textLight,
                onPressed: _openExternal,
                child: const Icon(Icons.open_in_new_rounded, size: 18),
              ),
              const SizedBox(height: DesignTokens.s8),
              FloatingActionButton.small(
                key: CourierJobMap.recenterKey,
                heroTag: 'courier-job-recenter',
                tooltip: 'Show the whole run',
                backgroundColor: DesignTokens.bgAppBody,
                foregroundColor: DesignTokens.primaryGreen,
                onPressed: _fit,
                child: const Icon(Icons.center_focus_strong_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Why the rider's dot is missing, when it is something they can fix.
  String? get _locationProblem => switch (_location) {
    LocationPermissionDenied() => 'Allow location to see yourself on the map',
    LocationPermissionDeniedForever() =>
      'Location is blocked for StyleMint — turn it on in Settings',
    LocationServicesDisabled() => 'Location is off on this phone',
    LocationTimedOut() => 'No GPS fix yet',
    LocationCaptureFailed() => 'Could not get your location',
    _ => null,
  };
}

/// "4.2 km · 12 min" from an OSRM route.
String routeSummary(CourierRoute route) {
  final parts = <String>[];
  final metres = route.distanceMetres;
  if (metres != null) {
    parts.add(
      metres < 1000
          ? '${metres.round()} m'
          : '${(metres / 1000).toStringAsFixed(1)} km',
    );
  }
  final seconds = route.durationSeconds;
  if (seconds != null) {
    final minutes = (seconds / 60).ceil();
    parts.add(
      minutes < 60
          ? '$minutes min'
          : '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min',
    );
  }
  return parts.join(' · ');
}

class _StopPin extends StatelessWidget {
  const _StopPin({
    required this.icon,
    required this.color,
    required this.dimmed,
    required this.semanticLabel,
  });

  final IconData icon;
  final Color color;

  /// The shop, once the parcel is collected: still shown, no longer where
  /// the rider is going.
  final bool dimmed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 6),
          ],
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 22)),
      ),
    ),
  );
}

/// The rider: a dot, deliberately unlike the stop pins.
class _MeDot extends StatelessWidget {
  const _MeDot();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: DesignTokens.colorInfo,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DesignTokens.primaryGreen),
          const SizedBox(width: DesignTokens.s6),
          Text(text, style: DesignTokens.mediumSemibold),
        ],
      ),
    ),
  );
}

class _LocationProblem extends StatelessWidget {
  const _LocationProblem({required this.message, required this.onFix});

  final String message;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) => Material(
    color: DesignTokens.bgAppBody.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    child: InkWell(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      onTap: onFix,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 16,
              color: DesignTokens.colorWarning,
            ),
            const SizedBox(width: DesignTokens.s8),
            Flexible(child: Text(message, style: DesignTokens.tiny)),
            const SizedBox(width: DesignTokens.s8),
            Text(
              'Fix',
              style: DesignTokens.tiny.copyWith(
                color: DesignTokens.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Neither stop has coordinates and the rider's position is unknown. The
/// sheet below still has the addresses and call buttons.
class _NoPoints extends StatelessWidget {
  const _NoPoints({
    required this.locating,
    required this.location,
    required this.onRetry,
  });

  final bool locating;
  final LocationCaptureResult? location;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: DesignTokens.surfaceRaised,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, color: DesignTokens.textMuted),
            const SizedBox(height: DesignTokens.s8),
            Text(
              locating
                  ? 'Finding your location…'
                  : 'This job has no map location. Use the addresses below.',
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            if (!locating && location is! LocationCaptured)
              TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}
