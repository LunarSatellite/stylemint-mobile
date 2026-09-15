import 'dart:math' as math;
import 'dart:ui';

import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// Where an embedded reel's player sits on a reel page.
///
/// A vertical reel fills the whole screen with no bars (see [coverRect]); a
/// square or landscape video shows whole, the way it was made, with the
/// platform fitting it inside a page-sized player. The page's overlay UI sits
/// on top as for every reel. (Owner decisions, 2026-09-13: full-screen
/// overlays, vertical reels fill the screen, other shapes stay as made —
/// accepting that YouTube's Required Minimum Functionality forbids drawing
/// over or cropping its player.)
abstract final class EmbedLayoutPolicy {
  static const double minPlayerSide = 200;

  /// Width of a stats rail beside a YouTube player, on screens that keep one.
  static const double railWidth = 64;

  /// Shape of a Short.
  static const double shortsAspectRatio = 9 / 16;

  /// Widest shape (width / height) that fills the screen: vertical reels, up
  /// to 3:4. Square and landscape videos show whole instead.
  static const double fillScreenMaxAspect = 3 / 4;

  /// Whether a video of [aspectRatio] fills the screen rather than showing
  /// whole.
  static bool fillsScreen(double aspectRatio) =>
      aspectRatio <= fillScreenMaxAspect;

  static bool reservesPlayerRect(SocialPlatform? platform) =>
      platform == SocialPlatform.youtube;

  /// Whether a full-bleed [platform] player keeps below the status bar.
  /// TikTok's player draws its creator header and logo along its top edge,
  /// which must never sit under the clock and battery; its video still runs
  /// to the bottom of the page. Nothing is drawn over the player instead.
  static bool keepsClearOfStatusBar(SocialPlatform platform) =>
      platform == SocialPlatform.tiktok;

  /// Like [coverRect], for the part of [page] below [topInset], and pinned to
  /// that edge: the player is trimmed at the sides or the bottom, never above
  /// [topInset].
  static Rect coverRectBelow({
    required Size page,
    required double aspectRatio,
    required double topInset,
  }) {
    final top = topInset.clamp(0.0, page.height);
    final area = Size(page.width, page.height - top);
    if (area.height <= 0) return Rect.fromLTWH(0, top, page.width, 0);
    final cover = coverRect(page: area, aspectRatio: aspectRatio);
    return Rect.fromLTWH(cover.left, top, cover.width, cover.height);
  }

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

  /// A player of the video's shape ([aspectRatio], width / height) just large
  /// enough to cover a page of size [page], centred on it. The video fills
  /// its player exactly, so the page shows no bars; the page clips what falls
  /// outside it, trimming the sides of a video narrower than the page's shape
  /// allows, or the top and bottom of a taller one.
  static Rect coverRect({required Size page, required double aspectRatio}) {
    if (page.width / page.height < aspectRatio) {
      final width = page.height * aspectRatio;
      return Rect.fromLTWH((page.width - width) / 2, 0, width, page.height);
    }
    final height = page.width / aspectRatio;
    return Rect.fromLTWH(0, (page.height - height) / 2, page.width, height);
  }
}
