import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk cache for reel video files.
///
/// Only Instagram reels reach this cache: they are the sole platform the
/// backend resolves a direct `videoCdnUrl` for (`ReelVideoUrlRefreshJob`
/// refreshes Instagram `media_url`s only). YouTube plays through the IFrame
/// player and TikTok/Facebook open externally, so neither has a file to
/// cache.
///
/// **Entries are keyed by the reel's permalink, not its video URL.** The
/// Instagram CDN URL is short-lived and gets rotated by the refresh job every
/// few hours; keying on it would miss on every rotation, re-download the same
/// video, and leave the old copy stranded until it went stale. The permalink
/// is stable for the life of the reel.
class ReelVideoCache {
  ReelVideoCache._();

  static final ReelVideoCache instance = ReelVideoCache._();

  static const _cacheKey = 'smReelVideoCache';

  /// Kept separate from the image cache so a burst of video files cannot
  /// evict thumbnails (and vice versa). Videos are far larger than images,
  /// so the object count is deliberately modest.
  static final CacheManager _manager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 80,
    ),
  );

  /// In-flight prefetches, so the two neighbours of a reel (or a card that
  /// rebuilds) cannot start the same download twice.
  final Map<String, Future<void>> _inFlight = <String, Future<void>>{};

  /// The already-downloaded file for [cacheKey], or null on a miss.
  /// Never touches the network — callers fall back to streaming.
  Future<File?> peek(String cacheKey) async {
    if (cacheKey.isEmpty) return null;
    try {
      final info = await _manager.getFileFromCache(cacheKey);
      final file = info?.file;
      if (file == null) return null;
      return await file.exists() ? file : null;
    } on Exception {
      return null;
    }
  }

  /// Downloads [url] into the cache under [cacheKey] if it isn't there yet.
  ///
  /// Fire-and-forget: failures are swallowed because a missed prefetch only
  /// costs a stream on the next view, and a reel scrolled past is a routine
  /// cancellation rather than an error worth surfacing.
  Future<void> prefetch({required String cacheKey, required String url}) {
    if (cacheKey.isEmpty || url.isEmpty) return Future<void>.value();

    final existing = _inFlight[cacheKey];
    if (existing != null) return existing;

    final future = _run(cacheKey, url).whenComplete(() {
      _inFlight.remove(cacheKey);
    });
    _inFlight[cacheKey] = future;
    return future;
  }

  Future<void> _run(String cacheKey, String url) async {
    try {
      if (await peek(cacheKey) != null) return;
      await _manager.downloadFile(url, key: cacheKey);
    } on Exception {
      // Swallowed by contract — see [prefetch].
    }
  }

  /// Drops a single entry. Use when a cached file fails to play, so the next
  /// attempt re-fetches instead of replaying a truncated download.
  Future<void> evict(String cacheKey) async {
    if (cacheKey.isEmpty) return;
    try {
      await _manager.removeFile(cacheKey);
    } on Exception {
      // Nothing to do — the entry is already gone or was never written.
    }
  }
}
