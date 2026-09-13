import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/video_shape.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';

typedef ThumbnailLoader = Future<Uint8List?> Function(Uri url);
typedef ShapeReader = Future<double?> Function(Uint8List imageBytes);

/// The shape of each YouTube reel's video.
///
/// A YouTube reel is laid out as a Short until its shape is known. The shape
/// is read once from YouTube's public `hqdefault` thumbnail (see
/// [VideoShape]). Only videos that aren't Shorts get a shape, so a Short, or
/// a thumbnail that can't be read, keeps the Short layout.
class ReelShapes extends ChangeNotifier {
  ReelShapes({ThumbnailLoader? loadThumbnail, ShapeReader? readShape})
    : _loadThumbnail = loadThumbnail ?? _download,
      _readShape = readShape ?? _letterboxedAspect;

  static final ReelShapes instance = ReelShapes();

  final ThumbnailLoader _loadThumbnail;
  final ShapeReader _readShape;
  final Map<String, double?> _known = {};
  final Set<String> _learning = {};

  /// Width / height of [reel]'s video when it is a YouTube video that isn't a
  /// Short; null otherwise, or until it has been learned.
  double? aspectOf(ReelMedia reel) {
    final id = _youTubeId(reel);
    return id == null ? null : _known[id];
  }

  /// Learns [reel]'s shape once. A failure leaves it unknown, to try again
  /// the next time the reel is shown.
  Future<void> learnReel(ReelMedia reel) async {
    final id = _youTubeId(reel);
    if (id == null || _known.containsKey(id) || !_learning.add(id)) return;
    try {
      final bytes = await _loadThumbnail(
        Uri.parse(
          'https://i.ytimg.com/vi/${Uri.encodeComponent(id)}/hqdefault.jpg',
        ),
      );
      if (bytes == null) return;
      final aspect = await _readShape(bytes);
      _known[id] = aspect;
      if (aspect != null) notifyListeners();
    } on Object {
      // Unknown for now; the reel keeps the Short layout.
    } finally {
      _learning.remove(id);
    }
  }

  static String? _youTubeId(ReelMedia reel) {
    final id = reel.platformVideoId;
    return reel.platform == SocialPlatform.youtube &&
            id != null &&
            id.isNotEmpty
        ? id
        : null;
  }

  static Future<Uint8List?> _download(Uri url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final response = await (await client.getUrl(url)).close();
      if (response.statusCode != HttpStatus.ok) return null;
      final bytes = BytesBuilder(copy: false);
      await response.forEach(bytes.add);
      return bytes.takeBytes();
    } finally {
      client.close();
    }
  }

  static Future<double?> _letterboxedAspect(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    try {
      final image = (await codec.getNextFrame()).image;
      try {
        final pixels = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        return pixels == null
            ? null
            : VideoShape.aspectFromBlackBars(
                pixels.buffer.asUint8List(),
                image.width,
                image.height,
              );
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}
