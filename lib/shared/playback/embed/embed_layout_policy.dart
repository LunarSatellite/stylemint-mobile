import 'dart:math' as math;
import 'dart:ui';

import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// Where an embedded reel's player sits on a reel page.
///
/// The feed fills the whole screen with every YouTube reel (see [coverRect]),
/// with the page's overlay UI on top as for every other reel. (Owner
/// decisions, 2026-09-13: full-screen overlays on YouTube reels, and reels
/// fill the whole screen with no bars — accepting that YouTube's Required
/// Minimum Functionality forbids drawing over or cropping its player.)
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
