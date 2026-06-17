import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/onboarding_step_progress.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Creator onboarding — **Step 1 of 2: profile**. Collects an optional
/// free-text "expression" (the backend AI-maps it to content categories — the
/// primary input) + an optional bio, then fires the single
/// `POST /v1/creator/activate` call. On success we refresh the token (so it
/// carries the new `Creator` role) and advance to **Step 2: connect accounts**.
class CreatorApplyScreen extends ConsumerStatefulWidget {
  const CreatorApplyScreen({super.key});

  @override
  ConsumerState<CreatorApplyScreen> createState() => _CreatorApplyScreenState();
}

class _CreatorApplyScreenState extends ConsumerState<CreatorApplyScreen> {
  final _expressionController = TextEditingController();
  final _bioController = TextEditingController();

  static const _maxExpression = 140;
  static const _maxBio = 500;

  @override
  void dispose() {
    _expressionController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _activate() {
    ref.read(creatorActivateNotifierProvider.notifier).activate(
          bio: _bioController.text,
          expression: _expressionController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CreatorActivateState>(creatorActivateNotifierProvider, (_, next) {
      next.maybeWhen(
        // → Step 2: connect accounts (onboarding mode).
        success: () =>
            context.go('${RouteNames.socialConnect}?onboarding=true'),
        failure: (_) => SmSnackbar.error(
          context,
          'Could not set up your creator profile. Please try again.',
        ),
        orElse: () {},
      );
    });

    final isSubmitting = ref.watch(creatorActivateNotifierProvider).maybeWhen(
          submitting: () => true,
          orElse: () => false,
        );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: Text('Become a Creator', style: DesignTokens.oneLinerSemibold),
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingStepProgress(step: 0, total: 2),
              const SizedBox(height: DesignTokens.s24),
              Text('Set up your creator profile',
                  style: DesignTokens.titleLarge),
              const SizedBox(height: DesignTokens.s8),
              Text(
                "Tell us about yourself. Next, you'll connect your social "
                'accounts to import reels.',
                style: DesignTokens.bodyText.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
              const SizedBox(height: DesignTokens.s24),

              // Expression — the PRIMARY input (free text → AI categories).
              const _FieldLabel('What do you create?'),
              const SizedBox(height: DesignTokens.s8),
              _ActivateField(
                controller: _expressionController,
                hint: 'e.g. street fashion hauls, budget tech reviews, '
                    'home cooking…',
                maxLength: _maxExpression,
                maxLines: 3,
                enabled: !isSubmitting,
              ),
              const SizedBox(height: DesignTokens.s20),

              // Bio — optional.
              const _FieldLabel('Short bio (optional)'),
              const SizedBox(height: DesignTokens.s8),
              _ActivateField(
                controller: _bioController,
                hint: 'A line or two about you',
                maxLength: _maxBio,
                maxLines: 3,
                enabled: !isSubmitting,
              ),
              const SizedBox(height: DesignTokens.s32),

              SizedBox(
                width: double.infinity,
                child: SmPrimaryButton(
                  label: isSubmitting ? 'Setting up…' : 'Continue',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  disabled: isSubmitting,
                  onPressed: () async => _activate(),
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                'Both fields are optional — you can skip and fill them in later.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: DesignTokens.oneLinerSemibold);
}

class _ActivateField extends StatelessWidget {
  const _ActivateField({
    required this.controller,
    required this.hint,
    required this.maxLength,
    required this.maxLines,
    required this.enabled,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLength;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLength: maxLength,
      maxLines: maxLines,
      style: DesignTokens.bodyText.copyWith(color: DesignTokens.textWhite),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
        filled: true,
        fillColor: DesignTokens.bgAppBody,
        contentPadding: const EdgeInsets.all(DesignTokens.s16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          borderSide: const BorderSide(color: DesignTokens.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          borderSide: const BorderSide(color: DesignTokens.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          borderSide: const BorderSide(color: DesignTokens.primaryGreen),
        ),
      ),
    );
  }
}
