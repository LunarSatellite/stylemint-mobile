import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icon set of the reel rail ("A · Studio", approved 2026-09-14).
///
/// Path data sits on a 24×24 grid and is drawn with round caps and joins.
/// Every document is white; [ReelRailIcon] tints it, so one parsed picture
/// serves the icon and its shadow.
abstract final class ReelRailIcons {
  /// Size of a rail action icon (dp).
  static const double size = 30;

  static const heartPath =
      'M19 14c1.5-1.5 3-3.2 3-5.5A5.5 5.5 0 0 0 16.5 3C14.7 3 13.5 3.5 12 5 '
      '10.5 3.5 9.3 3 7.5 3A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4 3 5.5l7 7z';
  static const commentPath = 'M7.9 20A9 9 0 1 0 4 16.1L2 22z';
  static const sharePath = 'm22 2-7 20-4-9-9-4zM22 2 11 13';
  static const viewsPath =
      'M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7z '
      'M15 12a3 3 0 1 1-6 0 3 3 0 1 1 6 0z';
  static const bagPath = 'M6 8h12l1 12H5zM9 8a3 3 0 0 1 6 0';
  static const plusPath = 'M12 5v14M5 12h14';
  static const checkPath = 'm5 12 5 5 9-10';

  static const _open =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">';
  static const _round = 'stroke-linecap="round" stroke-linejoin="round"';

  /// Outline heart, 2.2 stroke.
  static const heart =
      '$_open<path d="$heartPath" fill="none" stroke="#fff" '
      'stroke-width="2.2" $_round/></svg>';

  /// Filled heart, for a liked state.
  static const heartFilled =
      '$_open<path d="$heartPath" fill="#fff" stroke="#fff" '
      'stroke-width="2.2" $_round/></svg>';

  /// Speech bubble for comments.
  static const comment =
      '$_open<path d="$commentPath" fill="none" stroke="#fff" '
      'stroke-width="2.2" $_round/></svg>';

  /// Paper plane for share.
  static const share =
      '$_open<path d="$sharePath" fill="none" stroke="#fff" '
      'stroke-width="2.2" $_round/></svg>';

  /// Eye for views.
  static const views =
      '$_open<path d="$viewsPath" fill="none" stroke="#fff" '
      'stroke-width="2.2" $_round/></svg>';

  /// Shopping bag at rail size (the cart disc).
  static const bag =
      '$_open<path d="$bagPath" fill="none" stroke="#fff" '
      'stroke-width="2.2" $_round/></svg>';

  /// Shopping bag with a heavier stroke for the 11dp product badge.
  static const bagBadge =
      '$_open<path d="$bagPath" fill="none" stroke="#fff" '
      'stroke-width="2.6" $_round/></svg>';

  /// Plus on the follow badge.
  static const plus =
      '$_open<path d="$plusPath" fill="none" stroke="#fff" '
      'stroke-width="3.2" $_round/></svg>';

  /// Check on the "following" badge.
  static const check =
      '$_open<path d="$checkPath" fill="none" stroke="#fff" '
      'stroke-width="3.2" $_round/></svg>';
}

/// One rail icon: [svg] (a [ReelRailIcons] document) tinted [color] at
/// [size], with a soft drop shadow so it reads over any video frame.
///
/// The shadow is the same picture tinted 50% black, blurred (sigma 2.5) and
/// moved down 1dp behind the icon — an [ImageFiltered] on a 30dp layer, never
/// a BackdropFilter over the video.
class ReelRailIcon extends StatelessWidget {
  const ReelRailIcon(
    this.svg, {
    this.size = ReelRailIcons.size,
    this.color = const Color(0xFFFFFFFF),
    this.shadow = true,
    super.key,
  });

  final String svg;
  final double size;
  final Color color;
  final bool shadow;

  static const Color _shadowColor = Color(0x80000000);
  static final ImageFilter _shadowBlur = ImageFilter.blur(
    sigmaX: 2.5,
    sigmaY: 2.5,
  );

  Widget _picture(Color tint) => SvgPicture.string(
    svg,
    width: size,
    height: size,
    allowDrawingOutsideViewBox: true,
    excludeFromSemantics: true,
    colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
  );

  @override
  Widget build(BuildContext context) {
    if (!shadow) return _picture(color);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(
            offset: const Offset(0, 1),
            child: ImageFiltered(
              imageFilter: _shadowBlur,
              child: _picture(_shadowColor),
            ),
          ),
          _picture(color),
        ],
      ),
    );
  }
}
