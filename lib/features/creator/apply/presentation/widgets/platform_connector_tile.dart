import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PlatformConnectorTile extends StatelessWidget {
  const PlatformConnectorTile({
    super.key,
    required this.platformName,
    required this.platformIcon,
    required this.handleController,
    required this.followerCountController,
    this.connected = false,
    this.onRemove,
  });

  final String platformName;
  final IconData platformIcon;
  final TextEditingController handleController;
  final TextEditingController followerCountController;
  final bool connected;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(
        borderColor: connected ? DesignTokens.primaryGreen : null,
      ),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  platformIcon,
                  color: DesignTokens.textWhite,
                  size: 22,
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Text(
                  platformName,
                  style: DesignTokens.oneLinerSemibold,
                ),
              ),
              if (connected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s8,
                    vertical: DesignTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: DesignTokens.primaryGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Connected',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (onRemove != null) ...[
                const SizedBox(width: DesignTokens.s8),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close,
                    color: DesignTokens.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: handleController,
                  style: DesignTokens.oneLinerRegular.copyWith(
                    color: DesignTokens.inputFieldData,
                  ),
                  decoration: DesignTokens.inputDecoration(
                    hintText: '@handle',
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: followerCountController,
                  keyboardType: TextInputType.number,
                  style: DesignTokens.oneLinerRegular.copyWith(
                    color: DesignTokens.inputFieldData,
                  ),
                  decoration: DesignTokens.inputDecoration(
                    hintText: 'Followers',
                  ),
                ),
              ),
            ],
          ),
          if (!connected)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: DesignTokens.colorWarning,
                    size: 14,
                  ),
                  const SizedBox(width: DesignTokens.s6),
                  Text(
                    'Connect your $platformName account to verify',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.colorWarning,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
