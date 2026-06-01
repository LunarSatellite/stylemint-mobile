import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Trending Now" row: thumbnail, name, price, rating + sold-today count.
class TrendingProductCard extends StatelessWidget {
  const TrendingProductCard({
    required this.product,
    required this.onTap,
    super.key,
  });

  final TrendingProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.s12),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s8),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.s12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s8),
              child: SizedBox(
                width: 56,
                height: 56,
                child:
                    product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (_, _) => const ColoredBox(
                                color: DesignTokens.bgAppBodyLight,
                              ),
                          errorWidget:
                              (_, _, _) => const ColoredBox(
                                color: DesignTokens.bgAppBodyLight,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: DesignTokens.iconLight,
                                ),
                              ),
                        )
                        : const ColoredBox(color: DesignTokens.bgAppBodyLight),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    formatMoney(product.price),
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: DesignTokens.iconSmall,
                        color: DesignTokens.secondaryYellow,
                      ),
                      const SizedBox(width: DesignTokens.s4),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      Text(
                        '🔥 ${_compact(product.soldToday)} sold today',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
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

/// 1500 → "1.5k", 156 → "156".
String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}
