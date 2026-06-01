import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class WizardStepIndicator extends StatelessWidget {
  const WizardStepIndicator({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber == currentStep;
        final isCompleted = stepNumber < currentStep;
        return Padding(
          padding: EdgeInsets.only(
            right: index < totalSteps - 1 ? DesignTokens.s8 : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isActive ? DesignTokens.s32 : DesignTokens.s12,
            height: DesignTokens.s12,
            decoration: BoxDecoration(
              color: isActive
                  ? DesignTokens.primaryGreen
                  : isCompleted
                      ? DesignTokens.primaryGreenLight
                      : DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.s6),
            ),
          ),
        );
      }),
    );
  }
}
