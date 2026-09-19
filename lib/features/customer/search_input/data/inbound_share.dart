import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An image another app handed to StyleMint through the system share sheet.
///
/// This is how a screenshot usually arrives. The buyer is looking at a
/// product page in a browser, a post in Instagram or a photo in a chat, and
/// shares it to StyleMint rather than saving it and coming back to hunt for
/// it in the gallery.
@immutable
class InboundShare {
  const InboundShare({required this.bytes});

  /// The shared image, read on the platform side and passed straight across
  /// the channel. No copy is written into StyleMint's own storage: the host
  /// reads the content URI into memory and forgets it.
  final Uint8List bytes;
}

/// Where inbound shares come from. A typedef-free interface so tests can
/// drive both the cold-start and the already-running case without the
/// platform channel.
abstract class InboundShareSource {
  /// The share that launched the app, if any. Returns it exactly once: a
  /// cold start must not re-open the same screenshot on every resume.
  Future<InboundShare?> takeLaunchShare();

  /// Shares that arrive while StyleMint is already running.
  Stream<InboundShare> get shares;
}

/// The real source, wired to `MainActivity`'s ACTION_SEND handling.
class PlatformInboundShareSource implements InboundShareSource {
  PlatformInboundShareSource({
    MethodChannel? channel,
    EventChannel? events,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _events = events ?? const EventChannel(_eventsName);

  static const String _channelName = 'app.stylemint/inbound_share';
  static const String _eventsName = 'app.stylemint/inbound_share/events';

  final MethodChannel _channel;
  final EventChannel _events;

  @override
  Future<InboundShare?> takeLaunchShare() async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('takeLaunchShare');
      if (bytes == null || bytes.isEmpty) return null;
      return InboundShare(bytes: bytes);
    } on MissingPluginException catch (_) {
      // iOS has no share extension yet; the picker route still works.
      return null;
    } on PlatformException catch (_) {
      return null;
    }
  }

  @override
  Stream<InboundShare> get shares => _events
      .receiveBroadcastStream()
      .map((event) => event is Uint8List && event.isNotEmpty ? event : null)
      .where((bytes) => bytes != null)
      .map((bytes) => InboundShare(bytes: bytes!))
      .handleError((Object _) {});
}

/// A source that never produces anything, for platforms with no share
/// target wired up. Chosen explicitly rather than letting the channel throw.
class NoInboundShareSource implements InboundShareSource {
  const NoInboundShareSource();

  @override
  Future<InboundShare?> takeLaunchShare() async => null;

  @override
  Stream<InboundShare> get shares => const Stream<InboundShare>.empty();
}
