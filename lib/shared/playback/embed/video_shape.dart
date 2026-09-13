import 'dart:typed_data';

/// Reads a video's shape from a YouTube thumbnail.
///
/// YouTube's 4:3 `hqdefault` thumbnail fits a video wider than 4:3 between
/// black bars above and below it, while a Short sits between soft blurred
/// panels. So black bars above and below mean the video is wide, and their
/// height gives its shape.
abstract final class VideoShape {
  /// A pixel at or below this brightness (0-255) counts as black.
  static const int darkLuma = 24;

  /// Share of a row's pixels that must be black for the row to be a bar.
  static const double darkShare = 0.96;

  /// Bars thinner than this share of the height are ignored (image edges).
  static const double minBarShare = 0.04;

  /// Width / height of the picture in an RGBA thumbnail of [width] x [height]
  /// pixels when black bars sit above and below it; null without such bars.
  static double? letterboxedAspect(Uint8List rgba, int width, int height) {
    if (width <= 0 || height <= 0 || rgba.length < width * height * 4) {
      return null;
    }

    bool isBar(int y) {
      var dark = 0;
      var sampled = 0;
      for (var x = 0; x < width; x += 2) {
        final i = (y * width + x) * 4;
        final luma =
            (rgba[i] * 299 + rgba[i + 1] * 587 + rgba[i + 2] * 114) ~/ 1000;
        sampled++;
        if (luma <= darkLuma) dark++;
      }
      return dark >= sampled * darkShare;
    }

    var top = 0;
    while (top < height ~/ 2 && isBar(top)) {
      top++;
    }
    var bottom = 0;
    while (bottom < height ~/ 2 && isBar(height - 1 - bottom)) {
      bottom++;
    }

    final minBar = height * minBarShare;
    final picture = height - top - bottom;
    if (top < minBar || bottom < minBar || picture < height * 0.2) return null;
    return width / picture;
  }
}
