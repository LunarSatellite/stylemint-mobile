import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/providers/current_user_avatar_provider.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_bottom_nav_bar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_nav_icons.dart';

/// Shared vendor bottom nav — extracted so every vendor screen reached via
/// `context.go()` (Home/Orders/Products/Profile) shows the same persistent
/// nav bar, instead of only the screens that happened to add their own copy.
///
/// Drawn with the app-wide [SmBottomNavBar]; the host navigates in [onTap].
class VendorBottomNav extends ConsumerWidget {
  const VendorBottomNav({
    required this.selectedIndex,
    required this.onTap,
    super.key,
  });

  /// 0 = Home, 1 = Orders, 2 = Products, 3 = Profile.
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SmBottomNavBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      items: [
        SmBottomNavItem.glyph(SmNavIcons.home, label: 'Home'),
        SmBottomNavItem.glyph(SmNavIcons.box, label: 'Orders'),
        SmBottomNavItem.glyph(SmNavIcons.grid, label: 'Products'),
        SmBottomNavItem.glyph(
          SmNavIcons.person,
          label: 'Profile',
          avatarUrl: ref.watch(currentUserAvatarUrlProvider),
        ),
      ],
    );
  }
}
