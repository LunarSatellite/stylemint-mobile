import 'dart:math' as math;
import 'dart:ui';

import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// Where an embedded reel's player sits on a reel page.
///
/// YouTube's Required Minimum Functionality forbids drawing anything in front
/// of any part of an embedded player and requires a viewport of at least
/// 200x200. So a YouTube reel gets its own rectangle: the full width of the
/// page, with a slim creator-and-actions bar below it. TikTok and Facebook
/// play full-bleed under the reel's overlay UI.
abstract final class EmbedLayoutPolicy {
  static const double minPlayerSide = 200;

  /// Width of a stats rail beside a YouTube player, on screens that keep one.
  static const double railWidth = 64;

  /// The creator-and-actions bar below a YouTube player in the feed.
  static const double compactBarHeight = 64;

  static bool reservesPlayerRect(SocialPlatform? platform) =>
      platform == SocialPlatform.youtube;

  static double panelHeight({double bottomInset = 0}) =>
      compactBarHeight + bottomInset;

  /// The player's rectangle within a page of size [page]. [topInset] is space
  /// kept clear above it (status bar, top bar), [panelHeight] the panel below
  /// it and [rightInset] a rail beside it.
  static Rect playerRect({
    required SocialPlatform? platform,
    required Size page,
    double topInset = 0,
    double panelHeight = 0,
    double rightInset = 0,
  }) {
    if (!reservesPlayerRect(platform)) return Offset.zero & page;
    final width = math.max(minPlayerSide, page.width - rightInset);
    final height = math.max(
      minPlayerSide,
      page.height - topInset - panelHeight,
    );
    return Rect.fromLTWH(0, topInset, width, height);
  }
}
