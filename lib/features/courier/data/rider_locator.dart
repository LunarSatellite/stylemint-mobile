import 'package:stylemint_mobile_frontend/features/courier/data/courier_location_reporter.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/location_capture_service.dart';

/// The rider's position for the job map: one fix (asking for permission if
/// it has not been settled), then updates as they move.
///
/// An interface so the job screen can be tested without a GPS or a platform
/// channel; the real one is [DeviceRiderLocator].
abstract interface class RiderLocator {
  /// One fix now. May show the OS permission prompt — the map is where the
  /// rider expects to be asked.
  Future<LocationCaptureResult> locate();

  /// Fixes as the rider moves. Only listened to after [locate] succeeded.
  Stream<LocationCaptured> follow();

  /// Sends the rider to whichever settings page fixes [reason].
  Future<void> openSettings(LocationCaptureResult? reason);
}

/// Built from the two location services the app already has, so the job map
/// handles services-off, denied, denied-forever and timeouts exactly as the
/// dashboard map does.
class DeviceRiderLocator implements RiderLocator {
  const DeviceRiderLocator({
    required LocationCaptureService capture,
    required CourierPositionSource positions,
  }) : _capture = capture,
       _positions = positions;

  final LocationCaptureService _capture;
  final CourierPositionSource _positions;

  /// Small enough that the dot keeps up with a rider on a bike, large enough
  /// that a phone lying still does not redraw the map every second.
  static const int _followMetres = 15;

  @override
  Future<LocationCaptureResult> locate() => _capture.capture();

  @override
  Stream<LocationCaptured> follow() =>
      _positions.movements(distanceFilterMetres: _followMetres);

  @override
  Future<void> openSettings(LocationCaptureResult? reason) async {
    if (reason is LocationServicesDisabled) {
      await _capture.openLocationSettings();
    } else {
      await _capture.openAppSettings();
    }
  }
}
