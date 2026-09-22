import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Back control for the onboarding steps.
///
/// These screens have no AppBar — they open with a centred title block — so
/// there was no leading slot for a back button and no way to return to the
/// previous step. This sits above the header and matches the arrow used in
/// the AppBars elsewhere in the app.
///
/// Renders nothing when there is nothing to pop, so the first step of the
/// chain doesn't show a dead control. That makes the widget safe to place on
/// every step regardless of which one the user entered on.
class OnboardingBackButton extends StatelessWidget {
  const OnboardingBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.canPop()) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: DesignTokens.textWhite,
        ),
        tooltip: 'Back',
        onPressed: () => context.pop(),
      ),
    );
  }
}
