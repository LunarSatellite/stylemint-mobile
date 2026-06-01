import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class RegistrationStepIndicator extends StatelessWidget {
  const RegistrationStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.completedSteps,
  });

  final int totalSteps;
  final int currentStep;
  final Set<int> completedSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          final step = index;
          final isCompleted = completedSteps.contains(step);
          final isActive = step == currentStep;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepCircle(
                number: step + 1,
                isCompleted: isCompleted,
                isActive: isActive,
              ),
              if (step < totalSteps - 1)
                _StepLine(isCompleted: isCompleted),
            ],
          );
        }),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.number,
    required this.isCompleted,
    required this.isActive,
  });

  final int number;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (isCompleted) {
      bg = DesignTokens.primaryGreen;
      fg = DesignTokens.buttonPrimaryText;
    } else if (isActive) {
      bg = Colors.transparent;
      fg = DesignTokens.primaryGreen;
    } else {
      bg = DesignTokens.bgAppBodyLight;
      fg = DesignTokens.textMuted;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: isActive
            ? Border.all(color: DesignTokens.primaryGreen, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
          : Text(
              '$number',
              style: DesignTokens.smallRegular.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 2,
      color: isCompleted ? DesignTokens.primaryGreen : DesignTokens.bgAppBodyLight,
    );
  }
}
