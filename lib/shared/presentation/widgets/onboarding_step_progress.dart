import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Step X of N" label + an N-segment progress bar for multi-step onboarding
/// flows (e.g. creator registration: profile → connect accounts).
class OnboardingStepProgress extends StatelessWidget {
  const OnboardingStepProgress({
    super.key,
    required this.step, // 0-based
    required this.total,
  });

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${step + 1} of $total',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Row(
          children: List.generate(total, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: i == total - 1 ? 0 : DesignTokens.s8,
                ),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step
                      ? DesignTokens.primaryGreen
                      : DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
