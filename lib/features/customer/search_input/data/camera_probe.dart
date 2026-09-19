import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// Answers "is there a camera worth offering?" without asking for the camera
/// permission.
///
/// `availableCameras()` enumerates hardware through `CameraManager` on
/// Android and `AVCaptureDevice` on iOS; neither needs the permission, so
/// this is safe to run while Discover paints. A device with no camera — an
/// emulator, a locked-down work handset, some tablets — reports an empty
/// list and the scan button is never drawn.
typedef CameraProbe = Future<bool> Function();

Future<bool> deviceHasCamera() async {
  try {
    final cameras = await availableCameras();
    return cameras.isNotEmpty;
  } on CameraException catch (_) {
    return false;
  } on MissingPluginException catch (_) {
    return false;
  } on Object catch (_) {
    return false;
  }
}
