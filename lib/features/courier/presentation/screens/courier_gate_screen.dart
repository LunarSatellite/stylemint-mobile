import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_dashboard_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_kyc_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The delivery-partner entry point: decides what a courier sees before
/// anything else loads.
///
/// Each of the seven profile states needs a different screen, not one "not
/// ready yet" message. An applicant has a form to fill, someone in review has
/// nothing to do but wants to know that, a rejected applicant needs the reason,
/// and a suspended courier needs to know why — telling all four "pending" is
/// how support tickets get written.
class CourierGateScreen extends ConsumerWidget {
  const CourierGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref.watch(courierAccountIdProvider);
    if (accountId.isEmpty) {
      return const _CourierMessage(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in first',
        body:
            'Delivery partners sign in with the same account they shop with. '
            'Sign in and come back here.',
      );
    }

    final profile = ref.watch(courierProfileProvider(accountId));

    return profile.when(
      loading: () => const Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        body: Center(child: SmBrandLoader()),
      ),
      error: (_, _) => _CourierMessage(
        icon: Icons.wifi_off_rounded,
        title: "Couldn't load your partner account",
        body: 'Check your connection and try again.',
        action: 'Retry',
        onAction: () async => ref.invalidate(courierProfileProvider(accountId)),
      ),
      // Null is not an error: most accounts are not couriers. This is the
      // "become one" path, and it is the common first visit.
      data: (value) => value == null
          ? const CourierApplyScreen()
          : _forState(context, ref, value),
    );
  }

  Widget _forState(BuildContext context, WidgetRef ref, CourierProfile profile) {
    switch (profile.state) {
      case CourierProfileState.applied:
        // Applied but no KYC submitted — the only thing they can do next.
        return CourierKycScreen(courierProfileId: profile.id);

      case CourierProfileState.kycInReview:
        return const _CourierMessage(
          icon: Icons.hourglass_top_rounded,
          title: 'Checks in progress',
          body:
              'We are reviewing your details. You will be able to accept '
              'deliveries as soon as that clears — nothing more is needed '
              'from you right now.',
        );

      case CourierProfileState.rejected:
        return _CourierMessage(
          icon: Icons.block_rounded,
          title: 'Application not approved',
          body:
              profile.suspendedReason?.trim().isNotEmpty ?? false
              ? profile.suspendedReason!
              : 'Your delivery partner application was not approved. '
                    'Contact support if you think this is wrong.',
        );

      case CourierProfileState.suspended:
        return _CourierMessage(
          icon: Icons.pause_circle_outline_rounded,
          title: 'Account suspended',
          body:
              profile.suspendedReason?.trim().isNotEmpty ?? false
              ? profile.suspendedReason!
              : 'Your delivery partner account is suspended. Contact support '
                    'for the reason and what happens next.',
        );

      case CourierProfileState.banned:
        return const _CourierMessage(
          icon: Icons.gpp_bad_rounded,
          title: 'Account closed',
          body: 'This account can no longer deliver on StyleMint.',
        );

      // Onboarded and Active both reach the dashboard. Onboarded cannot be
      // offered work yet — only Active can — so the dashboard says so rather
      // than this gate hiding the screen; a courier who got through checks
      // should be able to see their standing and set up their signing key
      // while they wait.
      case CourierProfileState.onboarded:
      case CourierProfileState.active:
        return CourierDashboardScreen(profile: profile);
    }
  }
}

class _CourierMessage extends StatelessWidget {
  const _CourierMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Delivery partner'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: DesignTokens.textLight),
              const SizedBox(height: DesignTokens.s16),
              Text(
                title,
                style: DesignTokens.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                body,
                style: DesignTokens.smallRegular,
                textAlign: TextAlign.center,
              ),
              if (action != null && onAction != null) ...[
                const SizedBox(height: DesignTokens.s24),
                SmPrimaryButton(label: action!, onPressed: onAction!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
