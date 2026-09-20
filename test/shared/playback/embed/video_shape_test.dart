import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/video_shape.dart';

void main() {
  /// An RGBA thumbnail whose top and bottom [bars] rows are [barValue] grey
  /// and the rest [pictureValue], with optional darker side panels.
  Uint8List thumbnail(
    int width,
    int height, {
    int bars = 0,
    int barValue = 0,
    int pictureValue = 200,
    int sidePanelValue = -1,
  }) {
    final rgba = Uint8List(width * height * 4);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final isBar = y < bars || y >= height - bars;
        final isSide =
            sidePanelValue >= 0 && (x < width ~/ 4 || x >= width * 3 ~/ 4);
        final value = isBar
            ? barValue
            : (isSide ? sidePanelValue : pictureValue);
        final i = (y * width + x) * 4;
        rgba
          ..[i] = value
          ..[i + 1] = value
          ..[i + 2] = value
          ..[i + 3] = 255;
      }
    }
    return rgba;
  }

  test('a wide video letterboxed with black bars reads as its own shape', () {
    final aspect = VideoShape.letterboxedAspect(
      thumbnail(160, 120, bars: 15),
      160,
      120,
    );

    expect(aspect, closeTo(16 / 9, 0.01));
  });

  test('a thumbnail without black bars has no letterboxed shape', () {
    expect(VideoShape.letterboxedAspect(thumbnail(160, 120), 160, 120), isNull);
  });

  test("a Short's soft grey side panels are not bars", () {
    final short = thumbnail(160, 120, sidePanelValue: 70);

    expect(VideoShape.letterboxedAspect(short, 160, 120), isNull);
    expect(VideoShape.aspectFromBlackBars(short, 160, 120), isNull);
  });

  test('a narrow video between black side bars reads as its own shape', () {
    final narrow = thumbnail(160, 120, sidePanelValue: 0);

    expect(
      VideoShape.pillarboxedAspect(narrow, 160, 120),
      closeTo(80 / 120, 0.02),
    );
    expect(
      VideoShape.aspectFromBlackBars(narrow, 160, 120),
      closeTo(80 / 120, 0.02),
    );
  });

  test('a letterboxed wide video is read from its top and bottom bars', () {
    final wide = thumbnail(160, 120, bars: 15);

    expect(
      VideoShape.aspectFromBlackBars(wide, 160, 120),
      closeTo(16 / 9, 0.01),
    );
  });

  test('a thin dark edge line is not a letterbox', () {
    expect(
      VideoShape.letterboxedAspect(thumbnail(160, 120, bars: 2), 160, 120),
      isNull,
    );
  });

  test('an all-black thumbnail is not read as letterboxed', () {
    final black = thumbnail(160, 120, pictureValue: 0);

    expect(VideoShape.letterboxedAspect(black, 160, 120), isNull);
  });

  test('a buffer smaller than the stated size is rejected', () {
    expect(VideoShape.letterboxedAspect(Uint8List(10), 160, 120), isNull);
  });
}
