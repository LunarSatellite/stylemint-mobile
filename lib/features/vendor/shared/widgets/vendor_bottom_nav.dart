import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/providers/current_user_avatar_provider.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_to_ship_count_provider.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_bottom_nav_bar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_nav_icons.dart';

/// Shared vendor bottom nav — extracted so every vendor screen reached via
/// `context.go()` (Home/Orders/Products/Profile) shows the same persistent
/// nav bar, instead of only the screens that happened to add their own copy.
///
/// Drawn with the app-wide [SmBottomNavBar]; the host navigates in [onTap].
///
/// Orders carries a badge with the number of parcels waiting to ship, so the
/// vendor sees it from anywhere in their app rather than only after opening
/// Orders. The count is read here rather than passed in, because the nav bar
/// appears on screens (Home, Products, Profile) that have no reason to know
/// anything about orders.
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
    // `.value` (not `.asData?.value`, the more common idiom here) because it
    // retains the previous value while a refresh is in flight, so the badge
    // does not blink to nothing on every navigation. Null — never loaded, or
    // the call failed — shows no badge, same as zero.
    final toShip = ref.watch(vendorToShipCountProvider).value ?? 0;

    return SmBottomNavBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      items: [
        SmBottomNavItem.glyph(SmNavIcons.home, label: 'Home'),
        SmBottomNavItem.glyph(
          SmNavIcons.box,
          label: 'Orders',
          badge: toShip,
        ),
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
