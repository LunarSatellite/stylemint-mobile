import 'dart:collection';

import 'package:flutter/foundation.dart';

/// How long one embedded reel took to show moving frames.
///
/// Measured by its `EmbedSlot` from the commands it sent and the events its
/// host page reported, so it covers the WebView, the platform player and the
/// network, but not the swipe animation before the feed settled.
@immutable
final class EmbedStartupSample {
  const EmbedStartupSample({
    required this.key,
    required this.warm,
    required this.prerolled,
    required this.assignToFirstFrame,
    required this.playToFirstFrame,
    this.assignToReady,
    this.startRetry,
  });

  /// The reel's embed key, e.g. `tiktok:7000000000000000001`.
  final String key;

  /// The player had reported ready before the reel was asked to play: it was
  /// pre-loaded while the reel was still a neighbour.
  final bool warm;

  /// The player had already fetched and held its first frames (pre-roll).
  final bool prerolled;

  /// From loading the reel into the slot until its player reported ready.
  final Duration? assignToReady;

  /// From loading the reel into the slot until the first moving frame.
  final Duration assignToFirstFrame;

  /// From asking the reel to play (the feed settling on it) until the first
  /// moving frame: the wait a viewer sees after a swipe.
  final Duration playToFirstFrame;

  /// Why the start had to be retried (`timeout` or `paused`), if it was.
  final String? startRetry;

  /// The platform part of [key].
  String get platform {
    final colon = key.indexOf(':');
    return colon < 0 ? key : key.substring(0, colon);
  }

  @override
  String toString() =>
      '$key ${warm ? 'warm' : 'cold'}${prerolled ? '+prerolled' : ''}: '
      'play->frames ${playToFirstFrame.inMilliseconds}ms, '
      'assign->ready ${assignToReady?.inMilliseconds ?? '-'}ms, '
      'assign->frames ${assignToFirstFrame.inMilliseconds}ms'
      '${startRetry == null ? '' : ', start retried ($startRetry)'}';
}

/// Whether embed start-up is traced to the log: always in debug builds, and in
/// release builds built with `--dart-define=EMBED_TRACE=true` (for measuring
/// on a phone).
const bool embedTrace = kDebugMode || bool.fromEnvironment('EMBED_TRACE');

/// The last few [EmbedStartupSample]s, kept in memory for tuning reel start-up
/// on a device. Samples and start retries are also printed when [embedTrace]
/// is on, tagged `[embed-startup]`.
class EmbedStartupMetrics {
  EmbedStartupMetrics({Duration Function()? clock, this.capacity = 64})
    : _clock = clock ?? _monotonicClock();

  /// How many samples are kept; older ones are dropped.
  final int capacity;

  final Duration Function() _clock;
  final ListQueue<EmbedStartupSample> _samples = ListQueue();
  int _startRetries = 0;

  /// Monotonic time the slots stamp their events with.
  Duration now() => _clock();

  /// Oldest first.
  List<EmbedStartupSample> get samples => List.unmodifiable(_samples);

  /// How many starts showed no frames in time and were retried muted.
  int get startRetries => _startRetries;

  void record(EmbedStartupSample sample) {
    _samples.addLast(sample);
    while (_samples.length > capacity) {
      _samples.removeFirst();
    }
    if (embedTrace) debugPrint('[embed-startup] $sample');
  }

  /// A reel asked to play showed no frames in time ([reason]: `timeout` or
  /// `paused`), [sincePlay] after it was asked, and is started again muted.
  void recordStartRetry(String key, String reason, Duration sincePlay) {
    _startRetries++;
    if (embedTrace) {
      debugPrint(
        '[embed-startup] $key no frames ${sincePlay.inMilliseconds}ms after '
        'play ($reason); retrying muted',
      );
    }
  }

  /// Median [EmbedStartupSample.playToFirstFrame], optionally only for one
  /// [platform] (`tiktok`, `youtube`, `facebook`) or for [warm] or cold
  /// starts. Null when no sample matches.
  Duration? medianPlayToFirstFrame({String? platform, bool? warm}) {
    final values = [
      for (final s in _samples)
        if ((platform == null || s.platform == platform) &&
            (warm == null || s.warm == warm))
          s.playToFirstFrame,
    ]..sort();
    if (values.isEmpty) return null;
    final middle = values.length ~/ 2;
    if (values.length.isOdd) return values[middle];
    return (values[middle - 1] + values[middle]) ~/ 2;
  }

  static Duration Function() _monotonicClock() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }
}
