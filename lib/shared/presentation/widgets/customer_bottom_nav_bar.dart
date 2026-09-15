import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_bottom_nav_bar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_nav_icons.dart';

/// The customer shell's bottom navigation bar — Home · Discover · (Scan) ·
/// Cart · Profile — in the shared [SmBottomNavBar] look.
///
/// Scan is the large mint QR action in the true centre, not a tab. Orders is
/// not in the bar: it opens from Profile's "My Orders" (owner choice,
/// 2026-09-15). Purely presentational: the host owns navigation via [onTap]
/// and [onScan].
class CustomerBottomNavBar extends StatelessWidget {
  const CustomerBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    this.onScan,
    this.cartBadge = 0,
    this.avatarUrl,
    super.key,
  });

  static const int homeIndex = 0;
  static const int discoverIndex = 1;

  /// Cart opens the cart page over the shell rather than switching tabs.
  static const int cartIndex = 2;
  static const int profileIndex = 3;

  /// The Scan circle: larger than the creator bar's 44dp create button.
  static const double scanDiameter = 54;
  static const double scanIconSize = 28;

  /// 0 = Home, 1 = Discover, 2 = Cart, 3 = Profile.
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Opens the QR scanner; no centre action when null.
  final VoidCallback? onScan;

  /// Units in the cart, shown on the Cart badge; hidden when 0.
  final int cartBadge;

  /// The signed-in user's photo for the Profile tab; the person icon when
  /// null (guests, or no photo).
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final scan = onScan;
    return SmBottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      centerAction: scan == null
          ? null
          : SmNavCenterAction(
              icon: SmNavIcons.qr,
              diameter: scanDiameter,
              iconSize: scanIconSize,
              semanticLabel: 'Scan QR code',
              onTap: scan,
            ),
      items: [
        SmBottomNavItem.glyph(SmNavIcons.home, label: 'Home'),
        SmBottomNavItem.glyph(SmNavIcons.compass, label: 'Discover'),
        SmBottomNavItem.glyph(SmNavIcons.bag, label: 'Cart', badge: cartBadge),
        SmBottomNavItem.glyph(
          SmNavIcons.person,
          label: 'Profile',
          avatarUrl: avatarUrl,
        ),
      ],
    );
  }
}
