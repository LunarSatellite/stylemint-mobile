import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_icons.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Colours of the bottom navigation bar ("A · Studio bar", approved
/// 2026-09-14).
abstract final class SmNavPalette {
  /// Bar fill; also the colour of the cut-out details on active icons.
  static const Color bar = Color(0xFF0B0E0D);

  /// 1dp top hairline: white at 7%.
  static const Color hairline = Color(0x12FFFFFF);

  /// Active label.
  static const Color labelActive = Color(0xFFEEF1EE);

  /// Inactive labels and outline icons: #EEF1EE at 62%.
  static const Color inactive = Color(0x9EEEF1EE);

  /// Active icon fill.
  static const Color active = DesignTokens.primaryGreen;

  /// The 56×30 pill behind the active icon: mint at 16%.
  static final Color pill = DesignTokens.primaryGreen.withValues(alpha: 0.16);

  /// Press ripple and focus glow.
  static final Color splash = DesignTokens.primaryGreen.withValues(
    alpha: 0.12,
  );

  /// Ring around an inactive profile photo: white at 55%.
  static const Color avatarRing = Color(0x8CFFFFFF);

  /// Halo around the active profile photo: mint at 25%.
  static final Color avatarHalo = DesignTokens.primaryGreen.withValues(
    alpha: 0.25,
  );

  /// Fill behind a profile photo while it loads.
  static const Color avatarPlaceholder = Color(0x1FFFFFFF);
}

/// One bottom-bar icon as white SVG documents on the 24×24 grid, in the reel
/// rail's language (round caps and joins, 2.0 strokes).
///
/// Inactive, [outline] is tinted muted. Active, [solid] is tinted mint and
/// [knockout] — the inner details — is drawn over it in the bar colour, so the
/// details read as cut out of the filled shape.
@immutable
class SmNavGlyph {
  const SmNavGlyph({required this.outline, required this.solid, this.knockout});

  final String outline;
  final String solid;
  final String? knockout;
}

/// The bottom-bar icon set. Home, compass and box use the approved mockup's
/// path data; the rest follow the same grid and weights.
abstract final class SmNavIcons {
  /// Size of a tab icon (dp).
  static const double size = 24;

  static const _open =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">';
  static const _close = '</svg>';
  static const _round = 'stroke-linecap="round" stroke-linejoin="round"';
  static const _line = 'fill="none" stroke="#fff"';
  static const _solid = 'fill="#fff" stroke="#fff"';

  static const homePath =
      'M4 10.2 12 4l8 6.2V19a1.5 1.5 0 0 1-1.5 1.5H15v-5.5H9v5.5H5.5 '
      'A1.5 1.5 0 0 1 4 19z';

  /// House with its door cut into the outline.
  static const home = SmNavGlyph(
    outline:
        '$_open<path d="$homePath" $_line stroke-width="2" $_round/>$_close',
    solid:
        '$_open<path d="$homePath" $_solid stroke-width="2" $_round/>$_close',
  );

  static const compassNeedlePath = 'm15.4 8.6-2.1 4.7-4.7 2.1 2.1-4.7z';
  static const _compassRing = '<circle cx="12" cy="12" r="8.5"';

  /// Compass for Discover and Explore; the needle is the cut-out.
  static const compass = SmNavGlyph(
    outline:
        '$_open$_compassRing $_line stroke-width="2"/> '
        '<path d="$compassNeedlePath" $_line stroke-width="1.8" $_round/>'
        '$_close',
    solid: '$_open$_compassRing $_solid stroke-width="2"/>$_close',
    knockout:
        '$_open<path d="$compassNeedlePath" $_solid stroke-width="1.8" '
        '$_round/>$_close',
  );

  static const boxPath = 'M20 8 12 3.8 4 8v8.2l8 4 8-4z';
  static const boxSeamsPath = 'M4 8l8 4.2L20 8M12 12.2v8';

  /// Parcel for Orders; the seams are the cut-out.
  static const box = SmNavGlyph(
    outline:
        '$_open<path d="$boxPath" $_line stroke-width="2" $_round/> '
        '<path d="$boxSeamsPath" $_line stroke-width="2" $_round/>$_close',
    solid: '$_open<path d="$boxPath" $_solid stroke-width="2" $_round/>$_close',
    // Butt caps, as in the mockup: the seams run out to the box's corners.
    knockout:
        '$_open<path d="$boxSeamsPath" $_line stroke-width="2" '
        'stroke-linejoin="round"/>$_close',
  );

  static const bagBodyPath = 'M6 8h12l1 12H5z';
  static const bagHandlePath = 'M9 8V7a3 3 0 0 1 6 0v1';
  static const bagSmilePath = 'M9.5 11.5a2.5 2.5 0 0 0 5 0';

  /// Shopping bag for Cart, the rail's bag on the bar grid; the inner curve
  /// is the cut-out.
  static const bag = SmNavGlyph(
    outline:
        '$_open<path d="$bagBodyPath" $_line stroke-width="2" $_round/> '
        '<path d="$bagHandlePath" $_line stroke-width="2" $_round/> '
        '<path d="$bagSmilePath" $_line stroke-width="2" $_round/>$_close',
    solid:
        '$_open<path d="$bagBodyPath" $_solid stroke-width="2" $_round/> '
        '<path d="$bagHandlePath" $_line stroke-width="2" $_round/>$_close',
    knockout:
        '$_open<path d="$bagSmilePath" $_line stroke-width="2" $_round/>'
        '$_close',
  );

  static const _personHead = '<circle cx="12" cy="7.6" r="3.5"';
  static const personBodyPath = 'M4.8 20.5c.6-3.7 3.5-6 7.2-6s6.6 2.3 7.2 6';

  /// Person: the Profile tab when there is no photo.
  static const person = SmNavGlyph(
    outline:
        '$_open$_personHead $_line stroke-width="2"/> '
        '<path d="$personBodyPath" $_line stroke-width="2" $_round/>$_close',
    solid:
        '$_open$_personHead $_solid stroke-width="2"/> '
        '<path d="${personBodyPath}z" $_solid stroke-width="2" $_round/>'
        '$_close',
  );

  static const _gridCells =
      '<rect x="4" y="4" width="6" height="6" rx="1.5"/> '
      '<rect x="14" y="4" width="6" height="6" rx="1.5"/> '
      '<rect x="4" y="14" width="6" height="6" rx="1.5"/> '
      '<rect x="14" y="14" width="6" height="6" rx="1.5"/>';

  /// Four tiles for vendor Products.
  static const grid = SmNavGlyph(
    outline: '$_open<g $_line stroke-width="2">$_gridCells</g>$_close',
    solid: '$_open<g $_solid stroke-width="2">$_gridCells</g>$_close',
  );

  static const _chartFrame =
      '<rect x="3.5" y="3.5" width="17" height="17" rx="4"';
  static const chartTrendPath = 'm7.5 15 3-3.5 2.8 2.3 3.2-4.3';

  /// Chart card for creator Analytics; the trend line is the cut-out.
  static const analytics = SmNavGlyph(
    outline:
        '$_open$_chartFrame $_line stroke-width="2"/> '
        '<path d="$chartTrendPath" $_line stroke-width="2" $_round/>$_close',
    solid: '$_open$_chartFrame $_solid stroke-width="2"/>$_close',
    knockout:
        '$_open<path d="$chartTrendPath" $_line stroke-width="2" $_round/>'
        '$_close',
  );

  static const tagPath = 'M3.5 3.5H11l9.5 9.5-7.5 7.5L3.5 11z';
  static const _tagHole = '<circle cx="7.7" cy="7.7" r="1.6" fill="#fff"/>';

  /// Price tag for creator Brands; the hole is the cut-out.
  static const tag = SmNavGlyph(
    outline:
        '$_open<path d="$tagPath" $_line stroke-width="2" $_round/>'
        '$_tagHole$_close',
    solid: '$_open<path d="$tagPath" $_solid stroke-width="2" $_round/>$_close',
    knockout: '$_open$_tagHole$_close',
  );

  /// Plus on the centre create action, drawn dark on the mint circle.
  static const plus =
      '$_open<path d="${ReelRailIcons.plusPath}" $_line stroke-width="2.4" '
      '$_round/>$_close';

  static const _qrFinders =
      '<rect x="3.5" y="3.5" width="6.5" height="6.5" rx="1.6"/>'
      '<rect x="14" y="3.5" width="6.5" height="6.5" rx="1.6"/>'
      '<rect x="3.5" y="14" width="6.5" height="6.5" rx="1.6"/>';
  static const _qrModules =
      '<rect x="5.75" y="5.75" width="2" height="2" rx=".5"/>'
      '<rect x="16.25" y="5.75" width="2" height="2" rx=".5"/>'
      '<rect x="5.75" y="16.25" width="2" height="2" rx=".5"/>'
      '<rect x="14" y="14" width="2.6" height="2.6" rx=".6"/>'
      '<rect x="17.9" y="14" width="2.6" height="2.6" rx=".6"/>'
      '<rect x="15.95" y="17.9" width="2.6" height="2.6" rx=".6"/>';

  /// A QR code — three finder squares and a few modules — for the customer
  /// Scan action, drawn dark on the mint circle.
  static const qr =
      '$_open<g $_line stroke-width="1.8">$_qrFinders</g>'
      '<g fill="#fff">$_qrModules</g>$_close';
}

/// A [SmNavGlyph] at tab size: a muted outline, or — when [active] — a mint
/// fill with its details cut out in the bar colour.
///
/// Drawn with [ReelRailIcon] minus the video shadow, so the bar shares the
/// reel rail's rendering.
class SmNavIcon extends StatelessWidget {
  const SmNavIcon(
    this.glyph, {
    this.active = false,
    this.size = SmNavIcons.size,
    super.key,
  });

  final SmNavGlyph glyph;
  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!active) {
      return ReelRailIcon(
        glyph.outline,
        size: size,
        color: SmNavPalette.inactive,
        shadow: false,
      );
    }
    final knockout = glyph.knockout;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          ReelRailIcon(
            glyph.solid,
            size: size,
            color: SmNavPalette.active,
            shadow: false,
          ),
          if (knockout != null)
            ReelRailIcon(
              knockout,
              size: size,
              color: SmNavPalette.bar,
              shadow: false,
            ),
        ],
      ),
    );
  }
}
