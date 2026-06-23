import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplyRejectedScreen extends StatelessWidget {
  const VendorApplyRejectedScreen({super.key, this.rejectionReason});

  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
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
                    _buildRejectedBadge(),
                    const SizedBox(height: DesignTokens.s20),
                    Text(
                      'Application Rejected',
                      style: DesignTokens.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      'Unfortunately your application has been rejected. Please contact our support team for more information',
                      style: DesignTokens.bodyText.copyWith(
                        color: DesignTokens.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (rejectionReason != null) ...[
                      const SizedBox(height: DesignTokens.s16),
                      _buildRejectionReasonCard(rejectionReason!),
                    ],
                    const SizedBox(height: DesignTokens.s16),
                    _buildCausesCard(),
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

  Widget _buildRejectedBadge() {
    return Image.asset(
      'assets/images/badge_rejected.png',
      width: 90,
      height: 90,
    );
  }

  Widget _buildRejectionReasonCard(String reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        border: Border.all(color: DesignTokens.colorError.withOpacity(0.3)),
      ),
      child: Text(
        reason,
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.colorError,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCausesCard() {
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
          Text(
            'What might have caused the rejection',
            style: DesignTokens.mediumSemibold,
          ),
          const SizedBox(height: DesignTokens.s12),
          _buildBullet('Incomplete or invalid business documentation'),
          _buildBulletWithLink(
            'Your business may not meet our ',
            'Vendor Guidelines',
          ),
          _buildBulletWithLink(
            'The information provided does not match our requirements stated in our ',
            'Vendor Guidelines',
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
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

  Widget _buildBulletWithLink(String prefix, String linkText) {
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
                      fontWeight: FontWeight.w700,
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
