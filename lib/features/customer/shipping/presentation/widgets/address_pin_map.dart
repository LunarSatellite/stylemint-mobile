import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Signature for the map surface inside [AddressPinMap].
typedef PinMapBuilder =
    Widget Function(
      BuildContext context,
      double latitude,
      double longitude,
      void Function(double latitude, double longitude) onPinMoved,
    );

/// Builds the map surface. Overridden in widget tests with a lightweight
/// stand-in, so the pin-drag behaviour can be exercised without spinning up a
/// real platform view (and without needing a Maps API key on CI).
final pinMapBuilderProvider = Provider<PinMapBuilder>(
  (ref) => _buildGoogleMap,
);

Widget _buildGoogleMap(
  BuildContext context,
  double latitude,
  double longitude,
  void Function(double latitude, double longitude) onPinMoved,
) {
  final target = LatLng(latitude, longitude);
  return GoogleMap(
    initialCameraPosition: CameraPosition(target: target, zoom: 17),
    markers: {
      Marker(
        markerId: const MarkerId('address-pin'),
        position: target,
        draggable: true,
        onDragEnd: (position) =>
            onPinMoved(position.latitude, position.longitude),
      ),
    },
    // Deliberately minimal: this is a pin corrector, not a map browser.
    myLocationButtonEnabled: false,
    zoomControlsEnabled: false,
    mapToolbarEnabled: false,
    compassEnabled: false,
    onTap: (position) => onPinMoved(position.latitude, position.longitude),
  );
}

/// A small, fixed-height map for nudging the pin onto the right building.
///
/// Intentionally not a full map UI — drag the marker (or tap a spot) and the
/// point moves; nothing else.
class AddressPinMap extends ConsumerWidget {
  const AddressPinMap({
    required this.latitude,
    required this.longitude,
    required this.onPinMoved,
    super.key,
  });

  final double latitude;
  final double longitude;
  final void Function(double latitude, double longitude) onPinMoved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builder = ref.watch(pinMapBuilderProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Not quite right? Drag the pin onto your building.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.s8),
          child: SizedBox(
            key: const Key('address_pin_map'),
            height: 180,
            width: double.infinity,
            child: builder(context, latitude, longitude, onPinMoved),
          ),
        ),
      ],
    );
  }
}
