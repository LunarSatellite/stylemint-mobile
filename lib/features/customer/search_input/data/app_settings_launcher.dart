import 'package:geolocator/geolocator.dart';

/// Opens this app's own page in the system settings, so a buyer who blocked
/// the microphone or the camera for good has somewhere to go.
///
/// The app carries no permission plugin. Geolocator is used purely as the
/// platform channel for `ACTION_APPLICATION_DETAILS_SETTINGS` on Android and
/// `UIApplication.openSettingsURLString` on iOS — both open the app's whole
/// permission list, nothing location-specific is read or requested. The same
/// call already backs the address screen's location recovery.
typedef AppSettingsLauncher = Future<bool> Function();

Future<bool> openSystemAppSettings() async {
  try {
    return await Geolocator.openAppSettings();
  } on Object catch (_) {
    // Some OEM builds have no settings activity to open. The caller keeps
    // its "type your search instead" way out either way.
    return false;
  }
}
