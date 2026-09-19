import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// One screenshot, held in memory only, already stripped and downscaled.
///
/// Nothing in this feature ever holds a path. A screenshot can contain a
/// private chat, a bank balance or someone else's face, so the bytes are
/// normalised the moment they arrive and the original — the picker's temp
/// file, the share's content URI — is dropped without being copied anywhere
/// StyleMint controls.
@immutable
class ScreenshotImage {
  const ScreenshotImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  /// Always PNG: [normalizeScreenshot] re-encodes, so the mime is not a
  /// guess from a filename the buyer's other app chose.
  String get mimeType => 'image/png';

  /// The single field the search request carries. Built on demand and not
  /// cached, so the base64 copy is as short-lived as the request itself.
  String toDataUri() => 'data:$mimeType;base64,${base64Encode(bytes)}';
}

/// Raised when bytes cannot be read as an image at all.
class ScreenshotDecodeException implements Exception {
  const ScreenshotDecodeException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Turns arbitrary incoming bytes into a [ScreenshotImage].
typedef ScreenshotNormalizer =
    Future<ScreenshotImage> Function(Uint8List raw);

/// The longest edge a screenshot is reduced to before it leaves the device.
///
/// A phone screenshot is typically 1080x2400. Product text and a logo stay
/// legible at 1280, and the upload is a fraction of the original — the
/// search needs the picture, not the pixels.
const int kScreenshotMaxEdge = 1280;

/// Decodes, downscales and re-encodes [raw] as PNG.
///
/// Re-encoding is the privacy step, not a formatting one. `dart:ui` decodes
/// to a raw bitmap and [ui.Image.toByteData] writes a fresh PNG from those
/// pixels, so EXIF — GPS coordinates, the capture time, the device name,
/// the original filename — cannot survive the round trip. A shared image
/// that began life as a geotagged photo arrives at the server as pixels and
/// nothing else.
Future<ScreenshotImage> normalizeScreenshot(Uint8List raw) async {
  if (raw.isEmpty) {
    throw const ScreenshotDecodeException('That image was empty.');
  }
  final ui.Codec codec;
  try {
    codec = await ui.instantiateImageCodec(
      raw,
      targetWidth: kScreenshotMaxEdge,
      allowUpscaling: false,
    );
  } on Object catch (_) {
    throw const ScreenshotDecodeException(
      'StyleMint could not read that image.',
    );
  }
  final frame = await codec.getNextFrame();
  final image = frame.image;
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw const ScreenshotDecodeException(
        'StyleMint could not read that image.',
      );
    }
    return ScreenshotImage(
      bytes: data.buffer.asUint8List(),
      width: image.width,
      height: image.height,
    );
  } finally {
    // The decoded bitmap is the largest thing this feature allocates.
    image.dispose();
    codec.dispose();
  }
}
