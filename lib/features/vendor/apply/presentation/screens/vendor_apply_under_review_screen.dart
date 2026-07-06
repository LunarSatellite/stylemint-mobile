import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplyUnderReviewScreen extends StatelessWidget {
  const VendorApplyUnderReviewScreen({
    super.key,
    this.applicationId,
    this.userEmail,
  });

  final String? applicationId;
  final String? userEmail;

  @override
  Widget build(BuildContext context) {
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
                    _buildFolderIcon(),
                    const SizedBox(height: DesignTokens.s20),
                    Text(
                      'Application Under Review',
                      style: DesignTokens.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      'Your application is being reviewed. We will notify you with the results once the review process is completed',
                      style: DesignTokens.bodyText.copyWith(
                        color: DesignTokens.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.s24),
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

  Widget _buildFolderIcon() {
    return Image.asset(
      'assets/images/vendordashboard/badge_under_review.png',
      width: 90,
      height: 90,
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
