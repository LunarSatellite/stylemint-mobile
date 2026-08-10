import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplySubmittedScreen extends StatelessWidget {
  const VendorApplySubmittedScreen({
    super.key,
    this.applicationId,
    this.submittedAt,
    this.userEmail,
  });

  final String? applicationId;
  final String? submittedAt;
  final String? userEmail;

  @override
  Widget build(BuildContext context) {
    final appId = applicationId ?? '#CR2024-52341';
    final submittedOn = submittedAt ?? 'Dec 10, 2024';
    final email = userEmail ?? 'your email';

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s24,
                ),
                child: Column(
                  children: [
                    _buildSuccessBadge(),
                    const SizedBox(height: DesignTokens.s20),
                    Text(
                      'Application Submitted',
                      style: DesignTokens.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      "Thank you for applying to sell on ReelCommerce. We're reviewing your application",
                      style: DesignTokens.bodyText.copyWith(
                        color: DesignTokens.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.s24),
                    _buildStatusCard(appId: appId, submittedOn: submittedOn),
                    const SizedBox(height: DesignTokens.s16),
                    _buildWhatHappensNext(),
                    const SizedBox(height: DesignTokens.s16),
                    _buildWhileYouWait(email: email),
                    const SizedBox(height: DesignTokens.s24),
                    _buildNeedHelp(context),
                    const SizedBox(height: DesignTokens.s16),
                  ],
                ),
              ),
            ),
            _buildReturnHomeButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return Image.asset(
      'assets/images/vendordashboard/badge_approved.png',
      width: 90,
      height: 90,
    );
  }

  Widget _buildStatusCard({
    required String appId,
    required String submittedOn,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/vendordashboard/badge_under_review.png',
            width: 44,
            height: 44,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Current Status',
                  style: DesignTokens.mediumSemibold,
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Submitted on $submittedOn',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignTokens.warningFillDark,
                    borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
                    border: Border.all(
                        color: DesignTokens.colorWarning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          size: 12, color: DesignTokens.colorWarning),
                      const SizedBox(width: 4),
                      Text(
                        'Under Review',
                        style: DesignTokens.smallRegular.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: DesignTokens.colorWarning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'Application ID: $appId',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatHappensNext() {
    const steps = [
      'Document verification (1-3 days)',
      'Business & bank account verification (1-2 days)',
      'Final review & approval (1 day)',
      'You\'ll receive access to vendor dashboard',
      'Expected decision: 3-5 business days',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2137),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: const Color(0xFF1A3A55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What Happens next ?', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: DesignTokens.textWhite,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Text(step, style: DesignTokens.smallRegular),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhileYouWait({required String email}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A0D),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: const Color(0xFF333318)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('While you wait', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          _buildWaitItem('Make sure notifications are enabled'),
          _buildWaitItem('Check your email ($email)'),
          _buildWaitLinkItem('Review our ', 'Vendor Guidelines'),
          _buildWaitLinkItem('Watch ', 'Getting Started Videos'),
          _buildWaitItem('Prepare your product catalog'),
        ],
      ),
    );
  }

  Widget _buildWaitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: DesignTokens.textWhite,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(child: Text(text, style: DesignTokens.smallRegular)),
        ],
      ),
    );
  }

  Widget _buildWaitLinkItem(String prefix, String linkText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: DesignTokens.textWhite,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DesignTokens.smallRegular,
                children: [
                  TextSpan(text: prefix),
                  TextSpan(
                    text: linkText,
                    style: DesignTokens.smallRegular.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: DesignTokens.textWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelp(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Need Help?  ',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        GestureDetector(
          onTap: () => context.push(RouteNames.supportContact),
          child: Text(
            'Contact Support',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReturnHomeButton(BuildContext context) {
    return Container(
      color: DesignTokens.bgAppFoundation,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: DesignTokens.buttonHeight,
        child: ElevatedButton.icon(
          onPressed: () => context.go(RouteNames.home),
          style: DesignTokens.primaryButtonStyle(),
          icon: const Icon(
            Icons.home_outlined,
            color: DesignTokens.buttonPrimaryText,
            size: 20,
          ),
          label: Text(
            'Return to Home',
            style: DesignTokens.oneLinerSemibold.copyWith(
              color: DesignTokens.buttonPrimaryText,
            ),
          ),
        ),
      ),
    );
  }
}

