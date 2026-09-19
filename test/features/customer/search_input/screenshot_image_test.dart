import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_image.dart';

/// A real, decodable PNG of [width] x [height], so the normaliser is tested
/// against the actual `dart:ui` codec rather than a stub of it.
Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFF00695C),
    )
    ..drawRect(
      Rect.fromLTWH(0, 0, width / 2, height / 2),
      Paint()..color = const Color(0xFFFFC107),
    );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a large screenshot is downscaled before it can be uploaded',
      () async {
    final raw = await _png(2400, 1080);
    final normalized = await normalizeScreenshot(raw);

    expect(normalized.width, kScreenshotMaxEdge);
    // The aspect ratio is kept; a squashed screenshot searches worse.
    expect(normalized.height, closeTo(1080 * kScreenshotMaxEdge / 2400, 1));
    // Smaller on the wire than what came off the device.
    expect(normalized.bytes.length, lessThan(raw.length));
  });

  test('a small screenshot is not blown up', () async {
    final raw = await _png(200, 320);
    final normalized = await normalizeScreenshot(raw);

    expect(normalized.width, 200);
    expect(normalized.height, 320);
  });

  test('the result is a freshly encoded PNG, so nothing rides along',
      () async {
    // A JPEG's EXIF block — where a phone writes GPS, the capture time and
    // the device name — cannot survive a decode to pixels and a re-encode.
    // This asserts the mechanism: the output is PNG regardless of input, so
    // there is no container left to carry the original's metadata.
    final normalized = await normalizeScreenshot(await _png(64, 64));

    expect(normalized.mimeType, 'image/png');
    expect(
      normalized.bytes.sublist(0, 8),
      // The PNG signature, byte for byte.
      const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    );
    expect(normalized.toDataUri(), startsWith('data:image/png;base64,'));
  });

  test('bytes that are not an image are refused, not guessed at', () async {
    expect(
      () => normalizeScreenshot(Uint8List.fromList(const [1, 2, 3])),
      throwsA(isA<ScreenshotDecodeException>()),
    );
    expect(
      () => normalizeScreenshot(Uint8List(0)),
      throwsA(isA<ScreenshotDecodeException>()),
    );
  });
}
