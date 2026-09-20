import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_more_menu_sheet.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// App-bar affordance that opens [showVendorMoreMenu].
///
/// Extracted because the more-menu was the *only* route to 14 vendor
/// destinations (Creator Partnerships, Brand Studio, Payouts & Earnings,
/// Analytics, Store to-do, …) and its single caller was the Home tab's app
/// bar — a vendor sitting on Orders, Products or Profile could not reach any
/// of them without first navigating back Home. Every vendor tab puts this in
/// its `actions:` instead of re-implementing the IconButton.
///
/// The bare `Icons.menu_rounded` read as a generic "menu" with nothing to say
/// what was behind it, so the tooltip and semantic label name it: these are
/// the store's tools, not a navigation drawer.
class VendorMenuButton extends ConsumerWidget {
  const VendorMenuButton({this.color = DesignTokens.textWhite, super.key});

  /// Matches the tint of the sibling actions in the host's app bar.
  final Color color;

  /// Shared wording for the tooltip and the semantic label, so a screen
  /// reader and a long-press surface the same name.
  static const label = 'Store tools';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        tooltip: label,
        icon: Icon(Icons.menu_rounded, color: color, size: 22),
        onPressed: () => showVendorMoreMenu(context, ref),
      ),
    );
  }
}
