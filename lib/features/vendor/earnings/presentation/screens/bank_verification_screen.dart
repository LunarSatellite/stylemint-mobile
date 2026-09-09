import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Legacy route retained for deep links. There is no server-side bank OTP
/// endpoint; provider verification is surfaced by the actual destination
/// record in Payment Methods.
class BankVerificationScreen extends StatelessWidget {
  const BankVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DesignTokens.bgAppFoundation,
    appBar: AppBar(
      backgroundColor: DesignTokens.bgAppFoundation,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: DesignTokens.textWhite,
        ),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Payout Verification',
        style: DesignTokens.oneLinerSemibold,
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 64,
            color: DesignTokens.primaryGreen,
          ),
          const SizedBox(height: DesignTokens.s20),
          Text(
            'Verification is provider-managed',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'For your security, Style Mint does not accept a local bank OTP. Add or review your payout destination in Payment Methods to see its current verification status.',
            textAlign: TextAlign.center,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s32),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: () => context.go(RouteNames.vendorPaymentMethods),
              style: DesignTokens.primaryButtonStyle(),
              child: const Text('Open Payment Methods'),
            ),
          ),
        ],
      ),
    ),
  );
}
