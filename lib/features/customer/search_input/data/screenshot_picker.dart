import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';

/// What came back from asking the buyer for a screenshot.
@immutable
sealed class ScreenshotPick {
  const ScreenshotPick();
}

/// Raw bytes, straight from the chooser and not yet normalised.
@immutable
final class ScreenshotPicked extends ScreenshotPick {
  const ScreenshotPicked(this.bytes);
  final Uint8List bytes;
}

/// The buyer backed out. Not an error and never shown as one.
@immutable
final class ScreenshotPickCancelled extends ScreenshotPick {
  const ScreenshotPickCancelled();
}

/// The gallery is not reachable, and [status] says whether that can still be
/// undone by the buyer, by an administrator, or not at all.
@immutable
final class ScreenshotPickBlocked extends ScreenshotPick {
  const ScreenshotPickBlocked(this.status, {this.detail});
  final SearchInputStatus status;
  final String? detail;
}

typedef ScreenshotPicker = Future<ScreenshotPick> Function();

/// Opens the system photo chooser and reads the chosen file into memory.
///
/// No quality or size arguments are passed: `image_picker` would re-encode
/// into another temp file to honour them, which means a second copy of a
/// private screenshot on disk. The bytes are read once and the picker's own
/// temp file is deleted immediately, so nothing outlives this call.
///
/// On Android 13+ and iOS 14+ the chooser is the system photo picker, which
/// hands back exactly one image and needs no gallery permission at all —
/// so the common path raises no prompt. The older permission-backed pickers
/// still can, and their refusals are mapped onto [SearchInputStatus] rather
/// than surfacing as a raw platform exception.
Future<ScreenshotPick> pickScreenshotFromGallery() async {
  XFile? picked;
  try {
    picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  } on PlatformException catch (error) {
    return ScreenshotPickBlocked(
      _statusForPlatformCode(error.code),
      detail: error.code,
    );
  } on MissingPluginException catch (_) {
    return const ScreenshotPickBlocked(SearchInputStatus.unsupported);
  }
  if (picked == null) return const ScreenshotPickCancelled();
  final bytes = await picked.readAsBytes();
  await _discardTempFile(picked.path);
  return ScreenshotPicked(bytes);
}

SearchInputStatus _statusForPlatformCode(String code) => switch (code) {
  // iOS: the buyer denied the photo library and the OS will not ask again.
  'photo_access_denied' => SearchInputStatus.deniedForever,
  // iOS: a device policy or Screen Time is blocking the library.
  'photo_access_restricted' => SearchInputStatus.restricted,
  // Android: the read-media permission was refused for this attempt.
  'permission' || 'camera_access_denied' => SearchInputStatus.denied,
  // No chooser activity at all — a stripped ROM or a kiosk device.
  'no_available_camera' ||
  'invalid_image' ||
  'multiple_request' => SearchInputStatus.unsupported,
  _ => SearchInputStatus.denied,
};

/// Best effort: a temp file we cannot delete is the platform's to clean up,
/// but it must never be the reason a search fails.
Future<void> _discardTempFile(String path) async {
  try {
    final file = File(path);
    if (file.existsSync()) await file.delete();
  } on Object catch (_) {
    // Nothing to do, and nothing worth interrupting the search for.
  }
}
