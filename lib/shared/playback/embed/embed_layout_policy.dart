import 'dart:math' as math;
import 'dart:ui';

import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// Where an embedded reel's player sits on a reel page.
///
/// YouTube's Required Minimum Functionality forbids drawing anything in front
/// of any part of an embedded player and requires a viewport of at least
/// 200x200. So a YouTube reel gets its own rectangle, with the action rail to
/// its right and the creator and product panel below. TikTok and Facebook
/// play full-bleed under the reel's overlay UI.
abstract final class EmbedLayoutPolicy {
  static const double minPlayerSide = 200;

  /// Width of the action rail beside a YouTube player.
  static const double railWidth = 64;

  /// Creator row and caption below a YouTube player.
  static const double creatorPanelHeight = 132;

  /// Added below a YouTube player when the reel has tagged products.
  static const double productsPanelHeight = 108;

  static bool reservesPlayerRect(SocialPlatform? platform) =>
      platform == SocialPlatform.youtube;

  static double panelHeight({
    required bool hasProducts,
    double bottomInset = 0,
  }) =>
      creatorPanelHeight +
      (hasProducts ? productsPanelHeight : 0) +
      bottomInset;

  /// The player's rectangle within a page of size [page]. [topInset] is space
  /// kept clear above it (status bar, top bar); [panelHeight] is the panel
  /// below it.
  static Rect playerRect({
    required SocialPlatform? platform,
    required Size page,
    double topInset = 0,
    double panelHeight = 0,
  }) {
    if (!reservesPlayerRect(platform)) return Offset.zero & page;
    final width = math.max(minPlayerSide, page.width - railWidth);
    final height = math.max(
      minPlayerSide,
      page.height - topInset - panelHeight,
    );
    return Rect.fromLTWH(0, topInset, width, height);
  }
}
