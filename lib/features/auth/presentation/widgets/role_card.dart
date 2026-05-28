import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Role selection card
/// Displays role icon, title, and description
class RoleCard extends StatelessWidget {
  final String role; // "customer", "creator", "vendor"
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleCard({
    Key? key,
    required this.role,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(
            color: isSelected
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? DesignTokens.primaryGreenDark
                    : DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.s12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textMuted,
                size: 28,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),

            // Title
            Text(
              title,
              style: DesignTokens.h3.copyWith(
                color: DesignTokens.textWhite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.s8),

            // Description
            Text(
              description,
              style: DesignTokens.tiny.copyWith(
                color: DesignTokens.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DesignTokens.s12),

            // Selection Indicator
            if (isSelected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.s6,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryGreen,
                  borderRadius: BorderRadius.circular(DesignTokens.s6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: DesignTokens.buttonPrimaryText,
                    ),
                    const SizedBox(width: DesignTokens.s4),
                    Text(
                      'Selected',
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.buttonPrimaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
