import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/domain/entities/recommendation.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({required this.request, required this.onTap, super.key});

  final RecommendationRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: DesignTokens.avatarMedium / 2,
                    backgroundImage: NetworkImage(request.userAvatarUrl),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.userName,
                          style: DesignTokens.mediumSemibold,
                        ),
                        Text(
                          _formatDate(request.createdAt),
                          style: DesignTokens.smallRegular,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s8,
                      vertical: DesignTokens.s4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryGreenLight,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.chipRadius,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: DesignTokens.iconSmall,
                          color: DesignTokens.primaryGreen,
                        ),
                        const SizedBox(width: DesignTokens.s4),
                        Text(
                          '${request.replyCount}',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s12),
              Text(
                request.question,
                style: DesignTokens.bodyText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (request.context != null) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(
                  request.context!,
                  style: DesignTokens.smallRegular,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (request.taggedCategories.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s8),
                Wrap(
                  spacing: DesignTokens.s6,
                  runSpacing: DesignTokens.s4,
                  children:
                      request.taggedCategories.take(3).map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s8,
                            vertical: DesignTokens.s4,
                          ),
                          decoration: DesignTokens.tagDecoration(
                            backgroundColor: DesignTokens.primaryGreenLight,
                          ),
                          child: Text(
                            cat,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
              if (request.taggedProducts.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s8),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: request.taggedProducts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: DesignTokens.s8),
                    itemBuilder: (_, index) {
                      final product = request.taggedProducts[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s8,
                        ),
                        decoration: DesignTokens.cardDecoration(
                          backgroundColor: DesignTokens.bgAppBodyLight,
                          hasShadow: false,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.s4,
                              ),
                              child: Image.network(
                                product.imageUrl,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 32,
                                  height: 32,
                                  color: DesignTokens.bgAppBodyLight,
                                  child: const Icon(
                                    Icons.image,
                                    size: 16,
                                    color: DesignTokens.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: DesignTokens.s6),
                            Text(
                              formatMoney(product.price),
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
