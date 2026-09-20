import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/creator/shared/widgets/creator_more_menu_sheet.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Header affordance that opens [showCreatorMoreMenu].
///
/// Extracted because the more-menu was the *only* route to Rate Card and
/// Reach — and the only route to Settings and the "Switch to Shopping" exit —
/// while its single caller was the Dashboard tab's header. A creator sitting
/// on Analytics, Brands or Profile had to walk back to Dashboard and find an
/// unlabelled hamburger first. Every creator tab renders this instead of
/// re-implementing the tap target.
///
/// Unlike the vendor side, none of the four creator tabs uses a Material
/// [AppBar]; each hand-rolls its header [Row] with its own icon style. So this
/// exposes the host's style rather than imposing one — a filled circle for the
/// Dashboard and Brands headers, a plain [IconButton] for Analytics, a bare
/// glyph for the creator profile. Restyling the headers to match a single
/// button would have been the larger change, and the wrong one.
///
/// The bare `Icons.menu_rounded` reads as a generic "menu" with nothing to say
/// what is behind it, so the tooltip and semantic label name it: these are the
/// creator's tools, not a navigation drawer.
class CreatorMenuButton extends ConsumerWidget {
  /// Plain [IconButton], for a header whose siblings are `IconButton`s
  /// (Analytics).
  const CreatorMenuButton.iconButton({
    this.color = DesignTokens.textWhite,
    this.iconSize = 24,
    super.key,
  }) : _surface = _Surface.iconButton,
       _diameter = 0,
       _fill = null;

  /// Glyph on a filled circle, for headers that draw their own round tap
  /// targets (Dashboard: 32 / `buttonGrayFill`; Brands: 36 / `0xFF2C2C2E`).
  const CreatorMenuButton.circle({
    required double diameter,
    required Color fill,
    this.color = DesignTokens.textWhite,
    this.iconSize = 20,
    super.key,
  }) : _surface = _Surface.circle,
       _diameter = diameter,
       _fill = fill;

  /// Bare glyph with no chrome, for a header of unadorned icons (creator
  /// profile).
  const CreatorMenuButton.bare({
    this.color = DesignTokens.textWhite,
    this.iconSize = 22,
    super.key,
  }) : _surface = _Surface.bare,
       _diameter = 0,
       _fill = null;

  /// Matches the tint of the sibling actions in the host's header.
  final Color color;

  /// Matches the glyph size of the sibling actions in the host's header.
  final double iconSize;

  final _Surface _surface;
  final double _diameter;
  final Color? _fill;

  /// Shared wording for the tooltip and the semantic label, so a screen
  /// reader and a long-press surface the same name.
  static const label = 'Creator tools';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = Icon(Icons.menu_rounded, color: color, size: iconSize);
    void open() => showCreatorMoreMenu(context, ref);

    final Widget child;
    switch (_surface) {
      case _Surface.iconButton:
        child = IconButton(tooltip: label, icon: icon, onPressed: open);
      case _Surface.circle:
        child = Tooltip(
          message: label,
          child: GestureDetector(
            onTap: open,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: _diameter,
              height: _diameter,
              decoration: BoxDecoration(color: _fill, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
        );
      case _Surface.bare:
        child = Tooltip(
          message: label,
          child: GestureDetector(
            onTap: open,
            behavior: HitTestBehavior.opaque,
            child: icon,
          ),
        );
    }

    return Semantics(button: true, label: label, child: child);
  }
}

enum _Surface { iconButton, circle, bare }
