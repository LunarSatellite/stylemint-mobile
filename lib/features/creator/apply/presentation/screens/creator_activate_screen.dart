import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';

import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_activate_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One-step creator onboarding (backend docs/CREATOR_ONBOARDING_SIMPLIFIED.md).
///
/// Name, email and phone already live on the account, so nothing is asked
/// again, and there is no ID upload or review: `POST /v1/creator/activate`
/// makes the account a creator immediately. Both fields are optional. On
/// success the creator goes to Connect Accounts, where handles and followers
/// are imported from each platform instead of being typed in.
class CreatorActivateScreen extends ConsumerStatefulWidget {
  const CreatorActivateScreen({super.key});

  @override
  ConsumerState<CreatorActivateScreen> createState() =>
      _CreatorActivateScreenState();
}

class _CreatorActivateScreenState extends ConsumerState<CreatorActivateScreen> {
  static const int _maxExpression = 140;
  static const int _maxBio = 500;

  final _expressionController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void dispose() {
    _expressionController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    await ref
        .read(creatorActivateNotifierProvider.notifier)
        .activate(
          bio: _bioController.text,
          expression: _expressionController.text,
        );
    if (!mounted) return;
    ref
        .read(creatorActivateNotifierProvider)
        .maybeWhen<void>(
          // Replace this screen so Back from Connect Accounts returns to
          // where the creator came from, not to an already-used form.
          // onboarding=true shows "Continue to Dashboard": connecting is
          // optional, so the creator always has a way forward.
          success: () => context.pushReplacement(
            '${RouteNames.socialConnect}?onboarding=true',
          ),
          failure: (_) => SmSnackbar.error(
            context,
            "Couldn't make you a creator. Check your connection and try "
            'again.',
          ),
          orElse: () {},
        );
  }

  void _back() {
    if (context.canPop()) {
      context.popOrHome();
    } else {
      context.go(RouteNames.userTypeSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref
        .watch(creatorActivateNotifierProvider)
        .maybeWhen(submitting: () => true, orElse: () => false);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: _back,
        ),
        title: const Text(
          'Become a Creator',
          style: DesignTokens.oneLinerSemibold,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s8,
          DesignTokens.s16,
          DesignTokens.s32,
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start creating on StyleMint',
                  style: DesignTokens.sectionInnerTitle,
                ),
                const SizedBox(height: DesignTokens.s6),
                const Text(
                  "You're a creator as soon as you tap the button. We use "
                  'the name, email and phone already on your account.',
                  style: DesignTokens.smallDescription,
                ),
                const SizedBox(height: DesignTokens.s16),
                const _Point(
                  icon: Icons.bolt_rounded,
                  text: 'No forms, ID upload or review',
                ),
                const SizedBox(height: DesignTokens.s8),
                const _Point(
                  icon: Icons.link_rounded,
                  text: 'Connect Instagram, TikTok, YouTube or Facebook next',
                ),
                const SizedBox(height: DesignTokens.s8),
                const _Point(
                  icon: Icons.insights_rounded,
                  text: 'Followers come straight from each platform',
                ),
                const SizedBox(height: DesignTokens.s24),
                TextField(
                  controller: _expressionController,
                  enabled: !submitting,
                  maxLength: _maxExpression,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    color: DesignTokens.inputFieldData,
                  ),
                  cursorColor: DesignTokens.primaryGreen,
                  decoration: DesignTokens.inputDecoration(
                    labelText: 'What do you create? (optional)',
                    hintText: 'e.g. Tech reviews and unboxings',
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                TextField(
                  controller: _bioController,
                  enabled: !submitting,
                  maxLines: 4,
                  maxLength: _maxBio,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    color: DesignTokens.inputFieldData,
                  ),
                  cursorColor: DesignTokens.primaryGreen,
                  decoration: DesignTokens.inputDecoration(
                    hintText: 'Short bio (optional)',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: DesignTokens.bgAppFoundation,
          border: Border(
            top: BorderSide(color: DesignTokens.borderDefault),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Material(
              color: DesignTokens.primaryGreen,
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              child: InkWell(
                onTap: submitting ? null : _activate,
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                child: SizedBox(
                  height: 56,
                  child: Center(
                    child: submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: DesignTokens.buttonPrimaryText,
                            ),
                          )
                        : Text(
                            'Become a Creator',
                            style: DesignTokens.oneLinerSemibold.copyWith(
                              color: DesignTokens.buttonPrimaryText,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: DesignTokens.iconSmall, color: DesignTokens.primaryGreen),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(text, style: DesignTokens.smallDescription),
        ),
      ],
    );
  }
}
