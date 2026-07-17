import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_sticky_bottom_bar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Single-step "Become a Creator" screen.
///
/// Calls the real `POST /v1/creator/activate` endpoint via
/// [creatorActivateNotifierProvider] — instant activation, no review queue.
/// On success it hands off to the real, OAuth-backed social-connect screen
/// (`RouteNames.socialConnect?onboarding=true`) to actually link platforms.
///
/// This replaces the old three-step apply → social (fake local toggle,
/// no OAuth) → review wizard, which never called `/v1/creator/activate` and
/// whose "connect" step never made a network call at all.
class CreatorApplyScreen extends ConsumerStatefulWidget {
  const CreatorApplyScreen({super.key});

  @override
  ConsumerState<CreatorApplyScreen> createState() => _CreatorApplyScreenState();
}

class _CreatorApplyScreenState extends ConsumerState<CreatorApplyScreen> {
  final _bioController = TextEditingController();
  final _expressionController = TextEditingController();

  static const int _maxBio = 500;
  static const int _maxExpression = 140;

  @override
  void dispose() {
    _bioController.dispose();
    _expressionController.dispose();
    super.dispose();
  }

  void _activate() {
    ref.read(creatorActivateNotifierProvider.notifier).activate(
          bio: _bioController.text.trim(),
          expression: _expressionController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Fires once per state transition — navigates on success, surfaces a
    // retry-able error on failure. Re-login (refreshing the JWT so the
    // Creator role is actually present) happens inside the notifier itself.
    ref.listen<CreatorActivateState>(creatorActivateNotifierProvider,
        (previous, next) {
      next.maybeWhen(
        success: () =>
            context.go('${RouteNames.socialConnect}?onboarding=true'),
        failure: (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t activate your creator account. Please try again.',
            ),
          ),
        ),
        orElse: () {},
      );
    });

    final activateState = ref.watch(creatorActivateNotifierProvider);
    final submitting = activateState.maybeWhen(
      submitting: () => true,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s20,
          DesignTokens.s16, DesignTokens.s32,
        ),
        children: [
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Become a Creator',
                    style: DesignTokens.sectionInnerTitle),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'Creator accounts activate instantly — no waiting on '
                  'review. Tell us a little about yourself, then connect '
                  'your social accounts on the next step.',
                  style: DesignTokens.smallDescription,
                ),
                const SizedBox(height: DesignTokens.s24),
                _bioTextArea(),
                const SizedBox(height: DesignTokens.s16),
                _inputField(
                  controller: _expressionController,
                  hint: 'One-line tagline (optional)',
                  maxLength: _maxExpression,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SmStickyBottomBar(
        primaryLabel: submitting ? 'Activating…' : 'Become a Creator',
        primaryEnabled: !submitting,
        primaryTrailing: submitting
            ? null
            : const Icon(Icons.arrow_forward_rounded,
                size: DesignTokens.iconSmall,
                color: DesignTokens.buttonPrimaryText),
        onPrimary: _activate,
        showTopDivider: true,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: DesignTokens.bgAppFoundation,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: DesignTokens.textWhite),
        onPressed: () => context.go(RouteNames.userTypeSelection),
      ),
      title: const Text('Become a Creator', style: DesignTokens.oneLinerSemibold),
    );
  }

  Widget _bioTextArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _bioController,
          maxLines: 6,
          maxLength: _maxBio,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: DesignTokens.inputFieldData,
            height: 1.5,
          ),
          cursorColor: DesignTokens.primaryGreen,
          onChanged: (_) => setState(() {}),
          decoration: DesignTokens.inputDecoration(
            hintText: 'Bio (optional) — tell brands and fans about your content',
          ).copyWith(
            counterText: '',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: DesignTokens.s4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_bioController.text.length}/$_maxBio',
            style: DesignTokens.smallRegular,
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        color: DesignTokens.inputFieldData,
      ),
      cursorColor: DesignTokens.primaryGreen,
      onChanged: (_) => setState(() {}),
      decoration:
          DesignTokens.inputDecoration(hintText: hint).copyWith(counterText: ''),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: child,
    );
  }
}
