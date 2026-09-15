import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A product on the store screen's grid: photo, name and price.
class StoreProductCard extends StatelessWidget {
  const StoreProductCard({
    required this.product,
    required this.onTap,
    super.key,
  });

  final StoreProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.s12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: product.imageUrl.isEmpty
                  ? const _NoPhoto(icon: Icons.image_outlined)
                  : CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ColoredBox(
                        color: DesignTokens.bgAppBodyLight,
                      ),
                      errorWidget: (_, _, _) => const _NoPhoto(
                        icon: Icons.image_not_supported_outlined,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    formatMoney(product.price),
                    style: DesignTokens.oneLinerSemibold,
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

class _NoPhoto extends StatelessWidget {
  const _NoPhoto({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: DesignTokens.bgAppBodyLight,
    child: Center(child: Icon(icon, color: DesignTokens.iconLight)),
  );
}
