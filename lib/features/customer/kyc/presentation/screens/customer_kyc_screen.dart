import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/kyc_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/presentation/notifiers/customer_kyc_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Verify identity (for EMI)": where the buyer's KYC Tier 2 stands, and the
/// way into the form.
///
/// Reached from Profile, from the EMI calculator's button, and from a
/// `kyc.decided` push — which is why it always reads the record afresh on
/// open rather than trusting whatever was cached.
class CustomerKycScreen extends ConsumerWidget {
  const CustomerKycScreen({super.key});

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    await context.push<void>(RouteNames.customerKycSubmit);
    if (!context.mounted) return;
    // The form may have submitted, or a review may have landed meanwhile.
    await ref.read(customerKycNotifierProvider.notifier).load();
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(emiEligibilityProvider);
    await ref.read(customerKycNotifierProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerKycNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Verify identity'),
      ),
      body: SafeArea(child: _body(context, ref, state)),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, CustomerKycState state) {
    if (state.loading && state.kyc == null) return const SmPageLoader();

    if (state.isUnavailable) {
      return const _Message(
        icon: Icons.hourglass_empty_rounded,
        title: 'Not open yet',
        body:
            'Identity verification for EMI is not open yet. Please check back '
            'soon.',
      );
    }
    final failure = state.loadFailure;
    if (failure != null && state.kyc == null) {
      return SmErrorView(
        message: kycErrorMessage(failure),
        onRetry: () => ref.read(customerKycNotifierProvider.notifier).load(),
      );
    }

    final kyc = state.kyc ?? CustomerKyc.notStarted;
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: const EdgeInsets.all(DesignTokens.s20),
        children: [
          _StatusCard(kyc: kyc),
          const SizedBox(height: DesignTokens.s24),
          if (kyc.canStartOrResume)
            SizedBox(
              width: double.infinity,
              child: SmPrimaryButton(
                label: switch (kyc.status) {
                  KycStatus.rejected => 'Resubmit',
                  KycStatus.expired => 'Verify again',
                  KycStatus.pending => 'Continue verification',
                  _ => 'Start verification',
                },
                onPressed: () => _openForm(context, ref),
              ),
            ),
          const SizedBox(height: DesignTokens.s16),
          const _WhyWeAsk(),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.kyc});

  final CustomerKyc kyc;

  static String _date(DateTime? value) =>
      value == null ? '' : DateFormat.yMMMd().format(value.toLocal());

  @override
  Widget build(BuildContext context) {
    final (icon, colour, title, body) = switch (kyc.status) {
      KycStatus.approved => (
        Icons.verified_rounded,
        DesignTokens.primaryGreen,
        'You are verified',
        'Your identity is verified (KYC Tier 2), so you can use EMI on '
            'products that offer it.',
      ),
      KycStatus.submitted || KycStatus.underReview => (
        Icons.hourglass_top_rounded,
        DesignTokens.colorWarning,
        kyc.status == KycStatus.underReview ? 'Under review' : 'Submitted',
        'A reviewer is checking your document and selfie. We will notify '
            'you when it is decided'
            '${kyc.submittedUtc == null ? '.' : ' — sent ${_date(kyc.submittedUtc)}.'}',
      ),
      KycStatus.rejected => (
        Icons.error_outline_rounded,
        DesignTokens.colorError,
        'Not approved',
        kyc.rejectionReason == null
            ? 'Your verification was not approved.'
            : 'Your verification was not approved: ${kyc.rejectionReason}',
      ),
      KycStatus.expired => (
        Icons.history_rounded,
        DesignTokens.textMuted,
        'Verification expired',
        'Your previous verification has expired. Verify again to keep using '
            'EMI.',
      ),
      KycStatus.pending => (
        Icons.pending_outlined,
        DesignTokens.textMuted,
        'Started',
        'You started verifying but have not submitted yet. Pick up where you '
            'left off.',
      ),
      KycStatus.none || KycStatus.unknown => (
        Icons.badge_outlined,
        DesignTokens.textMuted,
        'Verify to use EMI',
        'Paying in instalments needs a verified identity. It takes a few '
            'minutes: a photo of your citizenship, national ID or passport, '
            'a selfie, and your address.',
      ),
    };

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: colour.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colour, size: 32),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DesignTokens.h3),
                const SizedBox(height: DesignTokens.s4),
                Text(body, style: DesignTokens.smallRegular),
                if (kyc.status == KycStatus.rejected && !kyc.canResubmit) ...[
                  const SizedBox(height: DesignTokens.s8),
                  Text(
                    'Contact support to verify again.',
                    style: DesignTokens.tiny,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyWeAsk extends StatelessWidget {
  const _WhyWeAsk();

  @override
  Widget build(BuildContext context) => Text(
    'With EMI the seller lets you pay over time, so we confirm who you are '
    'first. Your document is seen only by StyleMint reviewers, and one person '
    'can verify one account.',
    style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
    textAlign: TextAlign.center,
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: DesignTokens.textMuted),
          const SizedBox(height: DesignTokens.s12),
          Text(title, style: DesignTokens.h3, textAlign: TextAlign.center),
          const SizedBox(height: DesignTokens.s8),
          Text(
            body,
            style: DesignTokens.smallRegular,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
