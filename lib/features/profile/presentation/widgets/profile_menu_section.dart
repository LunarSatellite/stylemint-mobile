import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One row in a profile menu section.
class ProfileMenuItem {
  const ProfileMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailingText,
    this.toggleValue,
    this.onToggle,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Optional value shown before the chevron (e.g. "English").
  final String? trailingText;

  /// When non-null the row renders a [Switch] instead of a chevron.
  final bool? toggleValue;
  final ValueChanged<bool>? onToggle;

  /// Renders the row in the error colour (e.g. Log Out).
  final bool isDestructive;
}

/// A grouped, card-style list of [ProfileMenuItem]s (Figma profile menu).
class ProfileMenuSection extends StatelessWidget {
  const ProfileMenuSection({required this.items, super.key});

  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MenuTile(item: items[i]),
            if (i != items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: DesignTokens.s48,
                color: DesignTokens.borderDefault,
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    final color =
        item.isDestructive ? DesignTokens.colorError : DesignTokens.textWhite;
    final hasToggle = item.toggleValue != null;

    return InkWell(
      onTap: hasToggle ? null : item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(item.icon, size: DesignTokens.iconMedium, color: color),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(
                item.label,
                style: DesignTokens.mediumRegular.copyWith(color: color),
              ),
            ),
            if (item.trailingText != null) ...[
              Text(
                item.trailingText!,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
            ],
            if (hasToggle)
              Switch.adaptive(
                value: item.toggleValue!,
                onChanged: item.onToggle,
                activeColor: DesignTokens.primaryGreen,
              )
            else if (!item.isDestructive)
              const Icon(
                Icons.chevron_right_rounded,
                color: DesignTokens.iconLight,
              ),
          ],
        ),
      ),
    );
  }
}
