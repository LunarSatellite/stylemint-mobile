import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Shared vendor bottom nav — extracted so every vendor screen reached via
/// `context.go()` (Home/Orders/Products/Profile) shows the same persistent
/// nav bar, instead of only the screens that happened to add their own copy.
class VendorNavItem {
  const VendorNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.assetIcon,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? assetIcon;
}

class VendorBottomNav extends StatelessWidget {
  const VendorBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    VendorNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    VendorNavItem(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Orders',
      assetIcon: 'assets/images/vendordashboard/nav_orders.png',
    ),
    VendorNavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view,
      label: 'Products',
      assetIcon: 'assets/images/vendordashboard/nav_products.png',
    ),
    VendorNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      assetIcon: 'assets/images/vendordashboard/nav_profile.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
          top: BorderSide(
            color: DesignTokens.borderDefault.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final selected = selectedIndex == i;
              final color = selected
                  ? DesignTokens.primaryGreen
                  : DesignTokens.textMuted;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      item.assetIcon != null
                          ? Image.asset(
                              item.assetIcon!,
                              width: 24,
                              height: 24,
                              color: color,
                            )
                          : Icon(
                              selected ? item.activeIcon : item.icon,
                              color: color,
                              size: 24,
                            ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          color: color,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
