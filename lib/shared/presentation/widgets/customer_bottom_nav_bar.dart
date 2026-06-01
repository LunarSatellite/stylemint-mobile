import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The customer shell's bottom navigation bar — Home · Discover · Track Order
/// · Profile. Shared across all customer tab surfaces (Figma "Customer Bottom
/// Navbar"). Purely presentational: the host owns navigation via [onTap].
///
/// Eventually this lives in a go_router `StatefulShellRoute` so it persists
/// across tabs; for now individual customer screens render it directly.
class CustomerBottomNavBar extends StatelessWidget {
  const CustomerBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    this.trackOrderBadge = 0,
    super.key,
  });

  /// 0 = Home, 1 = Discover, 2 = Track Order, 3 = Profile.
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Count shown on the Track Order badge; hidden when 0.
  final int trackOrderBadge;

  static const _items = <({IconData icon, String label})>[
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.search_rounded, label: 'Discover'),
    (icon: Icons.inventory_2_outlined, label: 'Track Order'),
    (icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].icon,
                    label: _items[i].label,
                    isActive: i == currentIndex,
                    badge: i == 2 ? trackOrderBadge : 0,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? DesignTokens.primaryGreen : DesignTokens.textMuted;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: DesignTokens.iconMedium),
              if (badge > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: DesignTokens.colorError,
                      borderRadius: BorderRadius.circular(DesignTokens.s8),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      textAlign: TextAlign.center,
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
