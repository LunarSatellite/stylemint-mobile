import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// Signature for the map surface inside [AddressPinMap].
typedef PinMapBuilder =
    Widget Function(
      BuildContext context,
      double latitude,
      double longitude,
      void Function(double latitude, double longitude) onPinMoved,
    );

/// OpenStreetMap standard raster tiles. No API key, no billing account.
const _osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Sent as the `User-Agent` on every tile request. OSM's tile usage policy
/// blocks anonymous / default agents, so this must stay a real, identifying
/// package id.
const _osmUserAgent = 'app.stylemint.stylemint_mobile_frontend';

/// Edge length of the pin glyph and of its drag hit area.
const double _pinSize = 44;

/// OSM's own credit page, opened from the attribution line.
final Uri _osmCopyrightUri = Uri.parse(
  'https://www.openstreetmap.org/copyright',
);

/// Builds the map surface. Overridden in widget tests with a lightweight
/// stand-in, so the pin-drag behaviour can be exercised without spinning up a
/// real tile fetch.
final pinMapBuilderProvider = Provider<PinMapBuilder>(
  (ref) => _buildOsmMap,
);

Widget _buildOsmMap(
  BuildContext context,
  double latitude,
  double longitude,
  void Function(double latitude, double longitude) onPinMoved,
) {
  return _OsmPinMap(
    latitude: latitude,
    longitude: longitude,
    onPinMoved: onPinMoved,
  );
}

/// The OpenStreetMap surface: raster tiles, one draggable pin, tap-to-move.
///
/// Deliberately minimal — this is a pin corrector, not a map browser. No
/// compass, no zoom buttons, no locate button, and no rotation.
class _OsmPinMap extends StatefulWidget {
  const _OsmPinMap({
    required this.latitude,
    required this.longitude,
    required this.onPinMoved,
  });

  final double latitude;
  final double longitude;
  final void Function(double latitude, double longitude) onPinMoved;

  @override
  State<_OsmPinMap> createState() => _OsmPinMapState();
}

class _OsmPinMapState extends State<_OsmPinMap> {
  late LatLng _pin = LatLng(widget.latitude, widget.longitude);

  /// The live camera, republished on every pan/zoom. Null until the map's
  /// first frame, when the pin is by definition still at [_pin].
  final ValueNotifier<MapCamera?> _camera = ValueNotifier(null);

  final MapController _mapController = MapController();

  @override
  void dispose() {
    _camera.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _OsmPinMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The owning form is the source of truth: if it re-geocodes, follow it.
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _pin = LatLng(widget.latitude, widget.longitude);
    }
  }

  /// Reports the pin's resting place. Called once per gesture (on tap, or at
  /// the end of a drag) — never on every frame of a drag.
  void _report() => widget.onPinMoved(_pin.latitude, _pin.longitude);

  void _onPanUpdate(MapCamera camera, DragUpdateDetails details) {
    final moved = camera.latLngToScreenOffset(_pin) + details.delta;
    setState(() => _pin = camera.screenOffsetToLatLng(moved));
  }

  @override
  Widget build(BuildContext context) {
    // The pin is a sibling *above* the map, not a Marker inside it. A marker's
    // own gesture detector loses the arena to the map's scale recogniser, so
    // the pin would pan the map instead of moving; as the topmost hit Stack
    // child it wins outright and the map never sees the pointer.
    return Stack(
      children: [
        _buildMap(),
        // Only the pin itself takes hits: both the Align and the inner Stack
        // defer hit testing to their child, so everywhere else falls through
        // to the map below and pan/zoom still work.
        Positioned.fill(
          child: ValueListenableBuilder(
            valueListenable: _camera,
            builder: (context, camera, _) => _buildPin(camera),
          ),
        ),
      ],
    );
  }

  /// The draggable pin, laid over the map at [_pin]'s screen offset. Before
  /// the map's first frame there is no camera yet — but the map opens centred
  /// on [_pin], so the centre of the box is the right place.
  Widget _buildPin(MapCamera? camera) {
    final pin = Semantics(
      label: 'Address pin. Drag onto your building.',
      child: GestureDetector(
        key: const Key('address_pin_marker'),
        behavior: HitTestBehavior.opaque,
        onPanUpdate: camera == null
            ? null
            : (details) => _onPanUpdate(camera, details),
        onPanEnd: (_) => _report(),
        child: const Icon(
          Icons.location_pin,
          size: _pinSize,
          color: DesignTokens.primaryGreen,
          shadows: [Shadow(blurRadius: 4, color: Color(0x80000000))],
        ),
      ),
    );

    if (camera == null) {
      return Align(
        child: Transform.translate(
          offset: const Offset(0, -_pinSize / 2),
          child: pin,
        ),
      );
    }

    final offset = camera.latLngToScreenOffset(_pin);
    return Stack(
      children: [
        Positioned(
          left: offset.dx - _pinSize / 2,
          // The glyph's tip is its bottom edge; sit it on the point.
          top: offset.dy - _pinSize,
          width: _pinSize,
          height: _pinSize,
          child: pin,
        ),
      ],
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _pin,
        initialZoom: 17,
        onMapReady: () => _camera.value = _mapController.camera,
        onPositionChanged: (camera, _) => _camera.value = camera,
        // Shown wherever a tile hasn't arrived — including "no network at
        // all", where it is the entire map. Never a raw error surface.
        backgroundColor: DesignTokens.surfaceRaised,
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom,
        ),
        onTap: (_, point) {
          setState(() => _pin = point);
          _report();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: _osmTileUrl,
          userAgentPackageName: _osmUserAgent,
          // Only the tiles the visible viewport needs — no prefetching, no
          // bulk scraping. OSM's tile policy forbids both.
          panBuffer: 0,
          keepBuffer: 1,
          // No fade: matches the previous surface and keeps the widget
          // animation-free for reduced-motion users.
          tileDisplay: const TileDisplay.instantaneous(),
          // Offline or a 4xx from the tile server must not throw or paint an
          // error box — the pin, the drag and the coordinates still work over
          // the plain background.
          errorTileCallback: (_, _, _) {},
        ),
        // OSM tile policy: the credit must be permanently visible, not folded
        // behind a tap. RichAttributionWidget only shows an "i" button until
        // it is opened, so its TextSourceAttribution is placed directly —
        // same shipped widget, same "© OpenStreetMap contributors" string,
        // always on screen. Laid out to fit a 180px-tall map: inset clear of
        // the 8px corner round, small type, and free to wrap rather than
        // overflow at a large text scale.
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 4, bottom: 4),
            child: ColoredBox(
              color: DesignTokens.surfaceRaised.withValues(alpha: 0.85),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: TextSourceAttribution(
                  'OpenStreetMap contributors',
                  textStyle: DesignTokens.smallRegular.copyWith(
                    fontSize: 10,
                    color: DesignTokens.textMuted,
                    decoration: TextDecoration.underline,
                    decorationColor: DesignTokens.textMuted,
                  ),
                  onTap: _openOsmCopyright,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Opens OSM's credit page, swallowing any failure — a browser that won't
/// open is never worth an error in the middle of an address form.
void _openOsmCopyright() {
  launchUrl(_osmCopyrightUri, mode: LaunchMode.externalApplication).ignore();
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
