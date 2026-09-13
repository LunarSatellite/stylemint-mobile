import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Voyager "Carbon impact of delivery" — the customer's cumulative CO2
/// saved by StyleMint community delivery. Supplementary and passive like
/// the risk banner and seal card beside it: renders nothing while loading,
/// on any failure, or before any saving has been recorded.
class CarbonImpactCard extends ConsumerWidget {
  const CarbonImpactCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final impact = ref.watch(carbonImpactProvider).asData?.value;
    if (impact == null) return const SizedBox.shrink();

    final deliveries = impact.deliveryCount == 1
        ? '1 community delivery'
        : '${impact.deliveryCount} community deliveries';
    final percent = impact.percentSaved;

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DesignTokens.s8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.eco_outlined,
              size: 18,
              color: DesignTokens.primaryGreen,
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You saved ${formatCo2Mass(impact.kgCo2Saved)} CO₂ '
                    'with StyleMint delivery',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    percent == null
                        ? deliveries
                        : '$deliveries · $percent% less than a '
                              'traditional courier',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
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

/// Human CO2 mass: grams below 1 kg (so a small saving never reads as
/// "0.0 kg"), one decimal below 10 kg, whole kilograms above.
String formatCo2Mass(double kg) {
  final grams = (kg * 1000).round();
  if (grams < 1000) return '$grams g';
  if (kg < 10) return '${kg.toStringAsFixed(1)} kg';
  return '${kg.round()} kg';
}
