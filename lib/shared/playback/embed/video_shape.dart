import 'dart:typed_data';

/// Reads a video's shape from a YouTube thumbnail.
///
/// YouTube's 4:3 `hqdefault` thumbnail fits a regular video between black
/// bars — above and below a wide one, either side of a narrow one — while a
/// Short sits between soft blurred panels. So black bars mean the video isn't
/// a Short, and their size gives its shape.
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

  /// Width / height of the picture when black bars sit on either side of it,
  /// the way YouTube fits a narrower video that isn't a Short (a Short gets
  /// soft blurred panels instead); null without such bars.
  static double? pillarboxedAspect(Uint8List rgba, int width, int height) {
    if (width <= 0 || height <= 0 || rgba.length < width * height * 4) {
      return null;
    }

    bool isBar(int x) {
      var dark = 0;
      var sampled = 0;
      for (var y = 0; y < height; y += 2) {
        final i = (y * width + x) * 4;
        final luma =
            (rgba[i] * 299 + rgba[i + 1] * 587 + rgba[i + 2] * 114) ~/ 1000;
        sampled++;
        if (luma <= darkLuma) dark++;
      }
      return dark >= sampled * darkShare;
    }

    var left = 0;
    while (left < width ~/ 2 && isBar(left)) {
      left++;
    }
    var right = 0;
    while (right < width ~/ 2 && isBar(width - 1 - right)) {
      right++;
    }

    final minBar = width * minBarShare;
    final picture = width - left - right;
    if (left < minBar || right < minBar || picture < width * 0.2) return null;
    return picture / height;
  }

  /// The picture's shape from whichever black bars the thumbnail has; null
  /// when it has none, as for a Short.
  static double? aspectFromBlackBars(Uint8List rgba, int width, int height) =>
      letterboxedAspect(rgba, width, height) ??
      pillarboxedAspect(rgba, width, height);
}
