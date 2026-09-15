import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Lets a horizontal rail run past the product page's side padding to the
/// screen edges, like the Mall home rails. The rail's own start padding lines
/// its first card up with the page content again.
class PdpBleed extends StatelessWidget {
  const PdpBleed({
    required this.child,
    super.key,
    this.gutter = DesignTokens.s16,
  });

  final Widget child;

  /// The page padding to reach past on each side.
  final double gutter;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth + gutter * 2;
      return OverflowBox(
        fit: OverflowBoxFit.deferToChild,
        minWidth: width,
        maxWidth: width,
        child: child,
      );
    },
  );
}
