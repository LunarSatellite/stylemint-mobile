import 'dart:math' as math;
import 'dart:ui';

import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// Where an embedded reel's player sits on a reel page.
///
/// A YouTube player is sized to the shape of a Short at the page's width, so
/// YouTube draws the video edge to edge without cropping or black bars; the
/// page's overlay UI sits on top as for every other reel. (Owner decision,
/// 2026-09-13: full-screen overlays on YouTube reels, accepting that
/// YouTube's Required Minimum Functionality forbids drawing over its player.)
/// TikTok and Facebook players fill the page and letterbox themselves.
abstract final class EmbedLayoutPolicy {
  static const double minPlayerSide = 200;

  /// Width of a stats rail beside a YouTube player, on screens that keep one.
  static const double railWidth = 64;

  /// Shape of a Short.
  static const double shortsAspectRatio = 9 / 16;

  static bool reservesPlayerRect(SocialPlatform? platform) =>
      platform == SocialPlatform.youtube;

  /// The player's rectangle within a page of size [page]. [topInset] is space
  /// kept clear above it, [panelHeight] a panel below it and [rightInset] a
  /// rail beside it. With [aspectRatio] the player is no taller than that
  /// shape needs at its width.
  static Rect playerRect({
    required SocialPlatform? platform,
    required Size page,
    double topInset = 0,
    double panelHeight = 0,
    double rightInset = 0,
    double? aspectRatio,
  }) {
    if (!reservesPlayerRect(platform)) return Offset.zero & page;
    final width = math.max(minPlayerSide, page.width - rightInset);
    var height = page.height - topInset - panelHeight;
    if (aspectRatio != null) height = math.min(height, width / aspectRatio);
    return Rect.fromLTWH(0, topInset, width, math.max(minPlayerSide, height));
  }
}
