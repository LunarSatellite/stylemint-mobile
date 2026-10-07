import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';
import 'package:video_player/video_player.dart';

/// A photo or video the composer picked, with whatever size/length could be
/// read on the device. Null fields are filled from the upload response.
class PickedPostMedia {
  const PickedPostMedia({
    required this.path,
    required this.kind,
    this.width,
    this.height,
    this.duration,
  });

  final String path;
  final PostMediaKind kind;
  final int? width;
  final int? height;
  final Duration? duration;

  bool get isVideo => kind == PostMediaKind.video;
}

/// The device pickers behind the post composer. An interface so widget
/// tests can hand the composer files without the platform plugins.
///
/// Like the stories composer, a refused camera/photo permission surfaces as
/// the plugin's `PlatformException` (`camera_access_denied`,
/// `photo_access_denied`); the screen turns it into a "turn it on in
/// Settings" message.
abstract interface class PostMediaPicker {
  /// Up to [limit] photos from the gallery, re-encoded as JPEG.
  Future<List<PickedPostMedia>> pickPhotos({required int limit});

  /// One photo from the camera; null when cancelled.
  Future<PickedPostMedia?> takePhoto();

  /// One video from the gallery; null when cancelled.
  Future<PickedPostMedia?> pickVideo();
}

class ImagePickerPostMediaPicker implements PostMediaPicker {
  ImagePickerPostMediaPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  // Bounded and re-encoded so a full-resolution camera photo lands well under
  // the 10 MB upload limit, as a JPEG the upload accepts (no HEIC).
  static const int _imageQuality = 85;
  static const double _maxWidth = 1440;
  static const double _maxHeight = 2560;

  @override
  Future<List<PickedPostMedia>> pickPhotos({required int limit}) async {
    if (limit <= 0) return const [];
    final files = await _picker.pickMultiImage(
      imageQuality: _imageQuality,
      maxWidth: _maxWidth,
      maxHeight: _maxHeight,
      // The plugin refuses a limit below 2; a single slot is trimmed below.
      limit: limit >= 2 ? limit : null,
    );
    final picked = <PickedPostMedia>[];
    for (final file in files.take(limit)) {
      picked.add(await _photo(file.path));
    }
    return picked;
  }

  @override
  Future<PickedPostMedia?> takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: _imageQuality,
      maxWidth: _maxWidth,
      maxHeight: _maxHeight,
    );
    return file == null ? null : _photo(file.path);
  }

  @override
  Future<PickedPostMedia?> pickVideo() async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: PostMediaLimits.maxVideoDuration,
    );
    if (file == null) return null;
    // The size and length come from the platform player; a clip it can't
    // open still goes up — the server reads the same facts from the file.
    final controller = VideoPlayerController.file(File(file.path));
    try {
      await controller.initialize();
      final value = controller.value;
      return PickedPostMedia(
        path: file.path,
        kind: PostMediaKind.video,
        width: value.size.width > 0 ? value.size.width.round() : null,
        height: value.size.height > 0 ? value.size.height.round() : null,
        duration: value.duration > Duration.zero ? value.duration : null,
      );
    } on Object {
      return PickedPostMedia(path: file.path, kind: PostMediaKind.video);
    } finally {
      unawaited(controller.dispose());
    }
  }

  /// Decodes the photo once for its displayed size. The decoder applies EXIF
  /// orientation, which the server's header read cannot.
  static Future<PickedPostMedia> _photo(String path) async {
    int? width;
    int? height;
    try {
      final codec = await ui.instantiateImageCodec(
        await File(path).readAsBytes(),
      );
      final frame = await codec.getNextFrame();
      width = frame.image.width;
      height = frame.image.height;
      frame.image.dispose();
      codec.dispose();
    } on Object {
      // Unreadable here; the upload response carries the header size.
    }
    return PickedPostMedia(
      path: path,
      kind: PostMediaKind.image,
      width: width,
      height: height,
    );
  }
}

/// Overridden in tests with a fake picker.
final postMediaPickerProvider = Provider<PostMediaPicker>(
  (ref) => ImagePickerPostMediaPicker(),
);
