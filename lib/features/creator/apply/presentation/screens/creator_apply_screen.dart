import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_apply_step1_personal_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_apply_step2_social_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_apply_step3_review_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// 3-step creator application wizard shell.
///
/// Hosts a [PageStorageKey]-backed [IndexedStack] of the three step screens so
/// each step's local form state (text controllers, chip selections) survives
/// navigation between steps. The actual data persistence happens through
/// [creatorFormProvider] when each step's "Next" button is pressed.
class CreatorApplyScreen extends ConsumerStatefulWidget {
  const CreatorApplyScreen({super.key});

  @override
  ConsumerState<CreatorApplyScreen> createState() => _CreatorApplyScreenState();
}

class _CreatorApplyScreenState extends ConsumerState<CreatorApplyScreen> {
  static const int _totalSteps = 3;

  int _currentStep = 0;

  final _step1Key = GlobalKey<CreatorApplyStep1PersonalScreenState>();
  final _step2Key = GlobalKey<CreatorApplyStep2SocialScreenState>();
  final _step3Key = GlobalKey<CreatorApplyStep3ReviewScreenState>();

  bool _canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.canProceed ?? false;
      case 1:
        return _step2Key.currentState?.canProceed ?? false;
      case 2:
        return _step3Key.currentState?.canSubmit ?? false;
      default:
        return false;
    }
  }

  Future<void> _onNext() async {
    final ok = await _saveCurrentStep();
    if (!ok || !mounted) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep += 1);
    } else {
      await _submit();
    }
  }

  /// Returns the future the active step exposes for persisting its local form
  /// state into [creatorFormProvider]. Each step owns its controllers; the
  /// wizard only flips pages after the step reports success.
  Future<bool> _saveCurrentStep() async {
    switch (_currentStep) {
      case 0:
        return (_step1Key.currentState?.save() ?? Future.value(false));
      case 1:
        return (_step2Key.currentState?.save() ?? Future.value(false));
      default:
        return Future.value(true);
    }
  }

  Future<void> _submit() async {
    await _step3Key.currentState?.submit();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the shared provider so the Proceed/Submit button re-enables
    // as soon as the active step signals it has enough input. Without this
    // the shell only rebuilds on _currentStep changes and the button stays
    // disabled even after the user fills in the form.
    ref.watch(stepCanProceedProvider);
    final primaryLabel = switch (_currentStep) {
      0 => 'Proceed',
      1 => 'Proceed',
      _ => 'Submit',
    };

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentStep, totalSteps: _totalSteps),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                CreatorApplyStep1PersonalScreen(key: _step1Key),
                CreatorApplyStep2SocialScreen(key: _step2Key),
                CreatorApplyStep3ReviewScreen(
                  key: _step3Key,
                  onEditStep: (step) {
                    if (step < 0 || step >= _totalSteps) return;
                    setState(() => _currentStep = step);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _SinglePrimaryBar(
        label: primaryLabel,
        enabled: _canProceedFromCurrentStep(),
        trailing: const Icon(
          Icons.arrow_forward_rounded,
          size: DesignTokens.iconSmall,
          color: DesignTokens.buttonPrimaryText,
        ),
        onTap: _onNext,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: DesignTokens.bgAppFoundation,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: DesignTokens.textWhite,
        ),
        onPressed: () => context.go(RouteNames.userTypeSelection),
      ),
      title: const Text(
        'Creator Form',
        style: DesignTokens.oneLinerSemibold,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step indicator
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s4,
        DesignTokens.s16,
        DesignTokens.s16,
      ),
      child: Row(
        children: [
          for (var i = 0; i < totalSteps; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: 4,
                decoration: BoxDecoration(
                  // Only COMPLETED steps are green. The active step and
                  // future steps stay muted gray until the user moves past.
                  color: i < currentStep
                      ? DesignTokens.primaryGreen
                      : DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (i != totalSteps - 1) const SizedBox(width: DesignTokens.s8),
          ],
        ],
      ),
    );
  }
}
// ---------------------------------------------------------------------------
// Bottom action bar (Previous + Proceed side-by-side, no shared widget)
// ---------------------------------------------------------------------------

class _SinglePrimaryBar extends StatelessWidget {
  const _SinglePrimaryBar({
    required this.label,
    required this.enabled,
    required this.trailing,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Opacity(
            opacity: enabled ? 1 : 1,
            child: _Pill(
              label: label,
              fill: DesignTokens.primaryGreen,
              textColor: DesignTokens.buttonPrimaryText,
              trailing: trailing,
              onTap: enabled ? onTap : onTap,
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.fill,
    required this.textColor,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String label;
  final Color fill;
  final Color textColor;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s16,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: DesignTokens.s8),
              ],
              Text(
                label,
                style: DesignTokens.oneLinerSemibold.copyWith(color: textColor),
              ),
              if (trailing != null) ...[
                const SizedBox(width: DesignTokens.s8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
