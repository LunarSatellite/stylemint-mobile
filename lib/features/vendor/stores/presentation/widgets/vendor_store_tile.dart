import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One store in a list: name and address, tappable.
class VendorStoreTile extends StatelessWidget {
  const VendorStoreTile({
    required this.store,
    required this.onTap,
    this.trailingIcon = Icons.chevron_right_rounded,
    super.key,
  });

  final VendorStore store;
  final VoidCallback onTap;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${store.name}, ${store.addressSummary}',
      excludeSemantics: true,
      child: Material(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: DesignTokens.primaryGreenDark,
                  child: Icon(
                    Icons.storefront_rounded,
                    color: DesignTokens.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.name, style: DesignTokens.mediumSemibold),
                      const SizedBox(height: 2),
                      Text(
                        store.addressSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.smallRegular,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Icon(trailingIcon, color: DesignTokens.iconLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
