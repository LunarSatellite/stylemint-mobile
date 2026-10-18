import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One pin on a Services map: a stay's location, a meeting point.
class ServiceMapPin {
  const ServiceMapPin({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.label,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String? label;
}

/// Builds a map with [pins]; tapping a pin reports its id.
typedef ServiceMapBuilder =
    Widget Function(
      BuildContext context,
      List<ServiceMapPin> pins,
      ValueChanged<String>? onPinTap,
    );

/// OpenStreetMap raster tiles, as the address pin map uses. No API key.
const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _osmUserAgent = 'app.stylemint.stylemint_mobile_frontend';

/// The map surface. Widget tests override it with a stand-in so no tile is
/// ever fetched.
final serviceMapBuilderProvider = Provider<ServiceMapBuilder>(
  (ref) => _osmMap,
);

Widget _osmMap(
  BuildContext context,
  List<ServiceMapPin> pins,
  ValueChanged<String>? onPinTap,
) {
  if (pins.isEmpty) return const SizedBox.shrink();
  final points = [for (final p in pins) LatLng(p.latitude, p.longitude)];
  return FlutterMap(
    options: MapOptions(
      initialCenter: points.first,
      initialZoom: 14,
      initialCameraFit: points.length < 2
          ? null
          : CameraFit.coordinates(
              coordinates: points,
              padding: const EdgeInsets.all(40),
              maxZoom: 15,
            ),
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
        errorTileCallback: (_, _, _) {},
      ),
      MarkerLayer(
        markers: [
          for (final pin in pins)
            Marker(
              point: LatLng(pin.latitude, pin.longitude),
              width: 40,
              height: 40,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: onPinTap == null ? null : () => onPinTap(pin.id),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 40,
                  color: DesignTokens.primaryGreen,
                ),
              ),
            ),
        ],
      ),
      // OSM requires the credit to be permanently visible, as on the
      // courier maps.
      const Align(
        alignment: Alignment.bottomRight,
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
    ],
  );
}

/// A rounded map box of [height] with [pins], or nothing without pins.
class ServiceMapBox extends ConsumerWidget {
  const ServiceMapBox({
    required this.pins,
    this.height = 180,
    this.onPinTap,
    super.key,
  });

  static const Key boxKey = Key('service-map');

  final List<ServiceMapPin> pins;
  final double height;
  final ValueChanged<String>? onPinTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pins.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      key: boxKey,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: SizedBox(
        height: height,
        child: ref.watch(serviceMapBuilderProvider)(context, pins, onPinTap),
      ),
    );
  }
}
