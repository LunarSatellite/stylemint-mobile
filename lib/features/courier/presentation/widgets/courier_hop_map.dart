import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/geohash.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgent = 'app.stylemint.stylemint_mobile_frontend';

/// Where the parcel has to go, and which end of it the rider is heading for.
///
/// A hop stores its endpoints as geohashes and nothing else — there is no
/// street address on the courier's view of it — so this decodes them and
/// draws the two points. That is genuinely all the location data there is;
/// pretending otherwise would mean inventing an address.
///
/// The leg that matters changes as the job progresses: before collection the
/// rider is going to the pickup, after it they are going to the dropoff. The
/// map says which, and the Navigate button hands that one point to whichever
/// maps app the phone has, because turn-by-turn is not something to reimplement
/// inside a delivery app.
class CourierHopMap extends StatelessWidget {
  const CourierHopMap({required this.hop, super.key});

  final DeliveryHop hop;

  /// Height chosen so the map is usable at a glance without pushing the work
  /// list below the fold on a small phone.
  static const double height = 200;

  /// True once the parcel is with the rider, so the destination is what they
  /// are travelling to.
  bool get _headingToDropoff =>
      hop.state == HopState.pickedUp || hop.state == HopState.enRouteHandoff;

  @override
  Widget build(BuildContext context) {
    final pickup = decodeGeohash(hop.fromGeohash);
    final dropoff = decodeGeohash(hop.toGeohash);

    // Neither endpoint is placeable. Say so rather than drawing an empty map
    // of the Atlantic, which is where a failed decode would otherwise centre.
    if (pickup == null && dropoff == null) {
      return _Surface(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Text(
              'No location on this parcel yet.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final pickupPoint = pickup == null
        ? null
        : LatLng(pickup.latitude, pickup.longitude);
    final dropoffPoint = dropoff == null
        ? null
        : LatLng(dropoff.latitude, dropoff.longitude);

    final target = _headingToDropoff
        ? (dropoffPoint ?? pickupPoint)
        : (pickupPoint ?? dropoffPoint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Surface(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            child: _map(pickupPoint, dropoffPoint, target!),
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Row(
          children: [
            Expanded(
              child: Text(
                _headingToDropoff
                    ? 'Heading to the drop-off'
                    : 'Heading to the pick-up',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _navigate(context, target),
              icon: const Icon(Icons.navigation_rounded, size: 18),
              label: const Text('Navigate'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _map(LatLng? pickup, LatLng? dropoff, LatLng target) {
    final points = [
      if (pickup != null) pickup,
      if (dropoff != null) dropoff,
    ];

    // Centred between the two ends when there are two, so both are on screen,
    // and pulled back a little because the gap between them is unknown. Done
    // with plain centre and zoom rather than a camera fit: this widget cannot
    // be compiled here, so it stays on the map API the app already uses.
    final centre = points.length < 2
        ? target
        : LatLng(
            (points[0].latitude + points[1].latitude) / 2,
            (points[0].longitude + points[1].longitude) / 2,
          );

    return FlutterMap(
      options: MapOptions(
        initialCenter: centre,
        initialZoom: points.length < 2 ? 15 : 12.5,
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
          // OSM's tile policy forbids prefetching and bulk download, so only
          // what the viewport needs.
          panBuffer: 0,
          keepBuffer: 1,
          tileDisplay: const TileDisplay.instantaneous(),
          // Offline, or a 4xx from the tile server, must leave the pins and
          // the Navigate button working over the plain background rather than
          // painting an error box.
          errorTileCallback: (_, _, _) {},
        ),
        MarkerLayer(
          markers: [
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
        // behind a tap, which is why this is a plain attribution and not
        // RichAttributionWidget.
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

  /// The leg the rider is on is drawn solid; the other is dimmed, so which end
  /// they are going to is readable without reading the caption.
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

  /// Hands the point to the phone's maps app.
  ///
  /// A `geo:` URI with a `q` label is the Android convention and iOS resolves
  /// it through Apple Maps; where neither is installed the launch fails and
  /// the courier keeps the map above, so this reports rather than throws.
  Future<void> _navigate(BuildContext context, LatLng to) async {
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

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: CourierHopMap.height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: child,
    ),
  );
}
