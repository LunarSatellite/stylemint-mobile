import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_pool.dart';

/// Makes a feed's [EmbedPlayerPool] available to the reel pages under it.
///
/// A `ReelPlayer` inside a scope uses the pool's players, which the feed
/// hosts beneath its pages, instead of creating a WebView of its own.
class EmbedPlayerScope extends InheritedWidget {
  const EmbedPlayerScope({required this.pool, required super.child, super.key});

  final EmbedPlayerPool pool;

  static EmbedPlayerPool? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EmbedPlayerScope>()?.pool;

  @override
  bool updateShouldNotify(EmbedPlayerScope oldWidget) =>
      !identical(pool, oldWidget.pool);
}
