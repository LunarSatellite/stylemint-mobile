import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/regret_check.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Check before you buy" — Voyager "Regret-Aware Product Reranker" on the
/// product page. Lists the viewed product and its alternatives best first,
/// each with how often buyers regret it and why. Supplementary like the
/// sections beside it: renders nothing while loading, on any failure, or
/// when there is nothing to compare against.
class RegretCheckCard extends ConsumerWidget {
  const RegretCheckCard({
    required this.productId,
    this.onOpenProduct,
    super.key,
  });

  final String productId;

  /// Opens another option's product page. Defaults to pushing its route.
  final ValueChanged<String>? onOpenProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final check = ref.watch(regretCheckProvider(productId)).asData?.value;
    if (check == null || !check.hasAlternatives) return const SizedBox.shrink();

    final open =
        onOpenProduct ??
        (id) => context.push(
          RouteNames.productDetail.replaceFirst(':productId', id),
        );
    final viewedId = check.productId.isNotEmpty ? check.productId : productId;
    final recommendedId = check.abstained ? null : check.recommendedProductId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: DesignTokens.primaryGreen,
              ),
              SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  'Check before you buy',
                  style: DesignTokens.sectionInnerTitle,
                ),
              ),
            ],
          ),
          if (check.summary.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            if (check.abstained)
              _AbstainedSummary(summary: check.summary)
            else
              Text(
                check.summary,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
          ],
          const SizedBox(height: DesignTokens.s12),
          for (var i = 0; i < check.options.length; i++) ...[
            if (i > 0)
              const Divider(
                height: DesignTokens.s24,
                color: DesignTokens.borderDefault,
              ),
            _OptionRow(
              option: check.options[i],
              isViewed: _sameId(check.options[i].productId, viewedId),
              isRecommended:
                  recommendedId != null &&
                  _sameId(check.options[i].productId, recommendedId),
              onOpen: open,
            ),
          ],
        ],
      ),
    );
  }
}

bool _sameId(String a, String b) => a.toLowerCase() == b.toLowerCase();

class _AbstainedSummary extends StatelessWidget {
  const _AbstainedSummary({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('regret-check-abstained'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.infoFillDark,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: DesignTokens.infoIconLight,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(
              summary,
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.infoTextLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.isViewed,
    required this.isRecommended,
    required this.onOpen,
  });

  final RegretOption option;
  final bool isViewed;
  final bool isRecommended;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(option.productName, style: DesignTokens.mediumSemibold),
                  if (isViewed)
                    const _Tag(
                      label: 'This one',
                      color: DesignTokens.textLight,
                    ),
                  if (isRecommended)
                    const _Tag(
                      label: 'Recommended',
                      color: DesignTokens.primaryGreen,
                    ),
                ],
              ),
              const SizedBox(height: DesignTokens.s6),
              RegretLevelChip(level: option.level),
              for (final reason in option.reasons)
                Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.s4),
                  child: Text(
                    reason,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!isViewed)
          const Padding(
            padding: EdgeInsets.only(left: DesignTokens.s8),
            child: Icon(
              Icons.chevron_right,
              size: 20,
              color: DesignTokens.textMuted,
            ),
          ),
      ],
    );

    var row = isViewed
        ? content
        : InkWell(
            onTap: () => onOpen(option.productId),
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: content,
          );
    if (!option.eligible) row = Opacity(opacity: 0.5, child: row);
    return KeyedSubtree(
      key: ValueKey('regret-option-${option.productId}'),
      child: row,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: DesignTokens.smallRegular.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// How often buyers regret an option, as a coloured chip.
class RegretLevelChip extends StatelessWidget {
  const RegretLevelChip({required this.level, super.key});

  final RegretLevel level;

  @override
  Widget build(BuildContext context) {
    final color = regretLevelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        regretLevelLabel(level),
        style: DesignTokens.smallRegular.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String regretLevelLabel(RegretLevel level) => switch (level) {
  RegretLevel.low => 'Rarely regretted',
  RegretLevel.medium => 'Some regrets',
  RegretLevel.high => 'Often regretted',
  RegretLevel.unknown => 'Too new to tell',
};

Color regretLevelColor(RegretLevel level) => switch (level) {
  RegretLevel.low => DesignTokens.colorSuccess,
  RegretLevel.medium => DesignTokens.warning500,
  RegretLevel.high => DesignTokens.colorError,
  RegretLevel.unknown => DesignTokens.textMuted,
};
