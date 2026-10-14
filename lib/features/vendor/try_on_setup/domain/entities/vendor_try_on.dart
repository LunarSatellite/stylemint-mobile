/// The vendor side of virtual try-on: readiness, the overlay image, and the
/// checks the app runs on an image before uploading it. Pure Dart.
library;

import 'dart:typed_data';

import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/size_chart.dart';

export 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/size_chart.dart';

/// `GET /v1/vendor/products/{id}/try-on`.
class TryOnReadiness {
  const TryOnReadiness({
    required this.productId,
    required this.hasSizeChart,
    required this.hasTryOnImage,
    required this.ready,
    this.garmentType,
    this.imageUrl,
    this.problems = const <String>[],
  });

  final String productId;
  final bool hasSizeChart;
  final bool hasTryOnImage;
  final bool ready;
  final GarmentType? garmentType;
  final String? imageUrl;

  /// Human sentences from the server.
  final List<String> problems;
}

class TryOnImage {
  const TryOnImage({
    required this.productId,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.updatedUtc,
  });

  final String productId;
  final String imageUrl;
  final int width;
  final int height;
  final DateTime? updatedUtc;
}

enum TryOnImageFormat { png, webp, other }

/// What the app could tell about an image from its header, before upload.
class TryOnImageCheck {
  const TryOnImageCheck({
    required this.format,
    required this.problems,
    this.width,
    this.height,
    this.hasAlpha,
  });

  final TryOnImageFormat format;
  final int? width;
  final int? height;

  /// Null when the header does not say (the server still checks).
  final bool? hasAlpha;

  /// Blocking problems; empty when the image may be uploaded.
  final List<String> problems;

  bool get ok => problems.isEmpty;
}

abstract final class TryOnImageRules {
  static const int maxBytes = 5 * 1024 * 1024;
  static const int minSide = 600;
  static const double minTransparent = 0.15;
  static const double maxTransparent = 0.98;

  /// Reads PNG / WebP headers: format, size and whether there is an alpha
  /// channel. Mirrors the server's rules (PNG or WebP with alpha, ≤ 5 MB,
  /// shortest side ≥ 600 px).
  static TryOnImageCheck inspect(Uint8List bytes, {int? fileSize}) {
    final size = fileSize ?? bytes.length;
    final problems = <String>[];
    if (size > maxBytes) {
      problems.add(
        'The image is ${(size / (1024 * 1024)).toStringAsFixed(1)} MB — '
        'the limit is 5 MB.',
      );
    }

    final header = _readHeader(bytes);
    if (header == null) {
      problems.add(
        'Use a PNG or WebP with a transparent background (JPEG cannot be '
        'transparent).',
      );
      return TryOnImageCheck(
        format: TryOnImageFormat.other,
        problems: problems,
      );
    }
    final (format, w, h, alpha) = header;
    if (w != null && h != null && (w < minSide || h < minSide)) {
      problems.add(
        'The image is $w×$h px — the shortest side must be at least '
        '$minSide px.',
      );
    }
    if (alpha == false) {
      problems.add(
        'This image has no transparency. Remove the background and export '
        'it as a transparent PNG.',
      );
    }
    return TryOnImageCheck(
      format: format,
      width: w,
      height: h,
      hasAlpha: alpha,
      problems: problems,
    );
  }

  /// The share of fully transparent pixels in raw RGBA bytes, sampled.
  static double transparentShare(Uint8List rgba, {int samples = 40000}) {
    final pixels = rgba.length ~/ 4;
    if (pixels == 0) return 0;
    final step = pixels <= samples ? 1 : pixels ~/ samples;
    var transparent = 0;
    var n = 0;
    for (var p = 0; p < pixels; p += step) {
      if (rgba[p * 4 + 3] == 0) transparent++;
      n++;
    }
    return transparent / n;
  }

  /// A problem with the transparent share, or null when it is in range.
  static String? transparencyProblem(double share) {
    if (share < minTransparent) {
      return 'Only ${(share * 100).toStringAsFixed(0)}% of the image is '
          'transparent — the background does not look removed. At least 15% '
          'must be fully transparent.';
    }
    if (share > maxTransparent) {
      return 'The image is almost entirely transparent — the garment is '
          'missing or tiny.';
    }
    return null;
  }

  static (TryOnImageFormat, int?, int?, bool?)? _readHeader(Uint8List b) {
    // PNG: 89 50 4E 47 0D 0A 1A 0A, then IHDR.
    if (b.length >= 26 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47) {
      final w = _u32be(b, 16);
      final h = _u32be(b, 20);
      final colorType = b[25];
      // 4 = grey+alpha, 6 = RGBA; 3 = palette, alpha only with tRNS.
      final bool alpha =
          colorType == 4 || colorType == 6 || _hasChunk(b, 'tRNS');
      return (TryOnImageFormat.png, w, h, alpha);
    }
    // WebP: RIFF....WEBP
    if (b.length >= 30 &&
        _ascii(b, 0, 4) == 'RIFF' &&
        _ascii(b, 8, 4) == 'WEBP') {
      final chunk = _ascii(b, 12, 4);
      switch (chunk) {
        case 'VP8X':
          final alpha = (b[20] & 0x10) != 0;
          final w = 1 + (b[24] | (b[25] << 8) | (b[26] << 16));
          final h = 1 + (b[27] | (b[28] << 8) | (b[29] << 16));
          return (TryOnImageFormat.webp, w, h, alpha);
        case 'VP8L':
          // Signature 0x2f at 20, then 14 bits w-1, 14 bits h-1, 1 bit alpha.
          final bits = b[21] | (b[22] << 8) | (b[23] << 16) | (b[24] << 24);
          final w = (bits & 0x3FFF) + 1;
          final h = ((bits >> 14) & 0x3FFF) + 1;
          final alpha = ((bits >> 28) & 1) == 1;
          return (TryOnImageFormat.webp, w, h, alpha);
        case 'VP8 ':
          final w = (b[26] | (b[27] << 8)) & 0x3FFF;
          final h = (b[28] | (b[29] << 8)) & 0x3FFF;
          // Simple lossy WebP has no alpha channel.
          return (TryOnImageFormat.webp, w, h, false);
      }
      return (TryOnImageFormat.webp, null, null, null);
    }
    return null;
  }

  static int _u32be(Uint8List b, int o) =>
      (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];

  static String _ascii(Uint8List b, int o, int n) =>
      String.fromCharCodes(b.sublist(o, o + n));

  /// Walks PNG chunks up to the first IDAT looking for [type].
  static bool _hasChunk(Uint8List b, String type) {
    var o = 8;
    while (o + 8 <= b.length) {
      final len = _u32be(b, o);
      final t = _ascii(b, o + 4, 4);
      if (t == type) return true;
      if (t == 'IDAT' || t == 'IEND') return false;
      o += 12 + len;
    }
    return false;
  }
}

/// Whether a product is clothing/footwear sold in sizes — those must carry
/// a size chart before the app lets the vendor publish them. The wizard has
/// no size variants of its own, so this reads the category (and name) the
/// vendor chose.
bool isSizedApparel({String? categoryName, String? productName}) {
  final text = '${categoryName ?? ''} ${productName ?? ''}'.toLowerCase();
  if (text.trim().isEmpty) return false;
  const keywords = [
    'apparel',
    'clothing',
    'clothes',
    'fashion',
    'wear',
    'shirt',
    't-shirt',
    'tshirt',
    'top',
    'blouse',
    'kurta',
    'kurti',
    'saree',
    'sari',
    'dress',
    'gown',
    'skirt',
    'trouser',
    'pant',
    'jean',
    'short',
    'legging',
    'jacket',
    'coat',
    'hoodie',
    'sweater',
    'sweatshirt',
    'blazer',
    'suit',
    'lehenga',
    'shoe',
    'sneaker',
    'boot',
    'sandal',
    'heel',
    'footwear',
    'slipper',
    'jumpsuit',
    'romper',
    'tracksuit',
  ];
  final words = text.split(RegExp('[^a-z-]+'));
  return words.any(
    (w) =>
        w.isNotEmpty &&
        keywords.any((k) => w == k || w == '${k}s' || w == '${k}es'),
  );
}
