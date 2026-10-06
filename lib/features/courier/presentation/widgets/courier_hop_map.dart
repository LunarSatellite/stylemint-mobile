import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/geohash.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/location_capture_service.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgent = 'app.stylemint.stylemint_mobile_frontend';

/// The rider's map: where they are, and — once there is work — where the
/// parcel has to go and what the run pays.
///
/// Always on screen, with or without a parcel. An earlier version only
/// appeared when a hop was assigned, which meant a courier with no work saw
/// no map at all and had no way to tell whether the feature existed. A rider
/// opening the app wants to see themselves on the map first; the job is
/// drawn on top of that when it arrives.
///
/// Location comes through the app's existing [LocationCaptureService], which
/// already handles the four ways this goes wrong — services off, denied,
/// denied-forever, timeout — and each is reported as itself rather than as a
/// blank map.
class CourierHopMap extends ConsumerStatefulWidget {
  const CourierHopMap({this.hop, super.key});

  /// The active hop, or null when the rider has no parcel.
  final DeliveryHop? hop;

  static const double height = 220;

  @override
  ConsumerState<CourierHopMap> createState() => _CourierHopMapState();
}

class _CourierHopMapState extends ConsumerState<CourierHopMap> {
  LocationCaptureResult? _location;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // Asked on open rather than behind a button: a delivery app without the
    // rider's position cannot do its main job, so the permission prompt
    // belongs at the point the map appears.
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
  }

  Future<void> _locate() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await ref.read(locationCaptureServiceProvider).capture();
    if (!mounted) return;
    setState(() {
      _location = result;
      _locating = false;
    });
  }

  LatLng? get _me {
    final result = _location;
    return result is LocationCaptured
        ? LatLng(result.latitude, result.longitude)
        : null;
  }

  /// True once the parcel is with the rider, so the drop-off is what they are
  /// travelling to.
  bool get _headingToDropoff =>
      widget.hop?.state == HopState.pickedUp ||
      widget.hop?.state == HopState.enRouteHandoff;

  @override
  Widget build(BuildContext context) {
    final hop = widget.hop;
    final pickup = hop == null ? null : decodeGeohash(hop.fromGeohash);
    final dropoff = hop == null ? null : decodeGeohash(hop.toGeohash);

    final pickupPoint = pickup == null
        ? null
        : LatLng(pickup.latitude, pickup.longitude);
    final dropoffPoint = dropoff == null
        ? null
        : LatLng(dropoff.latitude, dropoff.longitude);

    final target = _headingToDropoff
        ? (dropoffPoint ?? pickupPoint)
        : (pickupPoint ?? dropoffPoint);

    // Centre on the job when there is one, otherwise on the rider. With
    // neither, the map still renders over its own background rather than
    // dropping to (0,0) in the Atlantic.
    final centre = target ?? _me;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: CourierHopMap.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DesignTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              child: centre == null
                  ? _Placeholder(
                      locating: _locating,
                      location: _location,
                      onRetry: _locate,
                      onOpenSettings: _openSettings,
                    )
                  : _map(centre, pickupPoint, dropoffPoint),
            ),
          ),
        ),
        if (hop != null) ...[
          const SizedBox(height: DesignTokens.s8),
          _JobBar(
            hop: hop,
            headingToDropoff: _headingToDropoff,
            onNavigate: target == null ? null : () => _navigate(target),
          ),
        ] else ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            _me == null
                ? 'Your location is needed so parcels near you can be offered.'
                : 'No parcel right now. When one is offered, the pick-up and '
                      'drop-off appear here with what the run pays.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _map(LatLng centre, LatLng? pickup, LatLng? dropoff) {
    final pins = [
      if (pickup != null) pickup,
      if (dropoff != null) dropoff,
    ];

    return FlutterMap(
      options: MapOptions(
        initialCenter: centre,
        // Tighter on a single point, pulled back when both ends of a run are
        // on screen and the distance between them is unknown.
        initialZoom: pins.length < 2 ? 15 : 12.5,
        backgroundColor: DesignTokens.surfaceRaised,
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _osmTileUrl,
          userAgentPackageName: _osmUserAgent,
          // OSM's tile policy forbids prefetching and bulk download.
          panBuffer: 0,
          keepBuffer: 1,
          tileDisplay: const TileDisplay.instantaneous(),
          // Offline or a 4xx must leave the pins and the Navigate button
          // working over the plain background, not paint an error box.
          errorTileCallback: (_, _, _) {},
        ),
        MarkerLayer(
          markers: [
            if (_me != null)
              Marker(
                point: _me!,
                width: 22,
                height: 22,
                child: const _MeDot(),
              ),
            if (pickup != null)
              _pin(
                pickup,
                Icons.store_mall_directory_rounded,
                active: !_headingToDropoff,
              ),
            if (dropoff != null)
              _pin(
                dropoff,
                Icons.location_on_rounded,
                active: _headingToDropoff,
              ),
          ],
        ),
        // OSM requires the credit to be permanently visible, not folded
        // behind a tap — hence a plain attribution, not RichAttributionWidget.
        const Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(left: 24, right: 4, bottom: 2),
            child: ColoredBox(
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
    );
  }

  /// The end the rider is travelling to is solid; the other is dimmed, so
  /// which one is live reads without reading the caption.
  Marker _pin(LatLng at, IconData icon, {required bool active}) => Marker(
    point: at,
    width: 36,
    height: 36,
    alignment: Alignment.topCenter,
    child: Icon(
      icon,
      size: 32,
      color: active
          ? DesignTokens.primaryGreen
          : DesignTokens.textMuted.withValues(alpha: 0.7),
    ),
  );

  Future<void> _openSettings() async {
    final service = ref.read(locationCaptureServiceProvider);
    if (_location is LocationServicesDisabled) {
      await service.openLocationSettings();
    } else {
      await service.openAppSettings();
    }
  }

  /// Hands the point to the phone's maps app.
  ///
  /// A `geo:` URI is the Android convention and iOS resolves it through Apple
  /// Maps. Where neither is installed the launch fails, so this reports
  /// rather than throws — the rider still has the map above.
  Future<void> _navigate(LatLng to) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final uri = Uri.parse(
      'geo:${to.latitude},${to.longitude}'
      '?q=${to.latitude},${to.longitude}',
    );

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('No maps app on this phone to open directions in.'),
        ),
      );
    }
  }
}

/// The rider's own position. Deliberately a different shape from the job
/// pins — a dot, not a teardrop — so "me" is never mistaken for a
/// destination.
class _MeDot extends StatelessWidget {
  const _MeDot();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: DesignTokens.primaryGreen,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    ),
  );
}

/// What the run pays, and where the rider is headed.
///
/// The payout is on the map card rather than only in the parcel list,
/// because "is this worth the trip" is the question a rider asks while
/// looking at the distance.
class _JobBar extends StatelessWidget {
  const _JobBar({
    required this.hop,
    required this.headingToDropoff,
    required this.onNavigate,
  });

  final DeliveryHop hop;
  final bool headingToDropoff;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headingToDropoff
                  ? 'Heading to the drop-off'
                  : 'Heading to the pick-up',
              style: DesignTokens.mediumSemibold,
            ),
            Text(
              'You earn ${formatMoney(Money(amount: hop.payoutAmount, currency: hop.payoutCurrency))} '
              'when this run is complete',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ],
        ),
      ),
      TextButton.icon(
        onPressed: onNavigate,
        icon: const Icon(Icons.navigation_rounded, size: 18),
        label: const Text('Navigate'),
      ),
    ],
  );
}

/// Shown while locating, and when location cannot be had.
///
/// Each failure says what went wrong and offers the one action that fixes
/// it, because "map didn't load" is indistinguishable between a denied
/// permission, location services switched off at the OS level, and a slow
/// GPS fix — and the recovery differs for each.
class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.locating,
    required this.location,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final bool locating;
  final LocationCaptureResult? location;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (locating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.s16),
          child: Text('Finding your location…'),
        ),
      );
    }

    final (message, actionLabel, settings) = switch (location) {
      LocationPermissionDenied() => (
        'Allow location so parcels near you can be offered.',
        'Allow',
        false,
      ),
      LocationPermissionDeniedForever() => (
        'Location is blocked for this app. Turn it on in Settings to get '
            'parcels near you.',
        'Open settings',
        true,
      ),
      LocationServicesDisabled() => (
        'Location services are off on this phone.',
        'Open settings',
        true,
      ),
      LocationTimedOut() => (
        'Could not get a GPS fix. Try again outdoors.',
        'Try again',
        false,
      ),
      LocationCaptureFailed(message: final detail) => (detail, 'Try again', false),
      _ => ('Your location is needed to show the map.', 'Allow', false),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.my_location_rounded,
              color: DesignTokens.textMuted,
              size: 28,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              message,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.s4),
            TextButton(
              onPressed: settings ? onOpenSettings : onRetry,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
