import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Legacy Figma entry point retained for deep links.
///
/// A payout bank account must be created through the shared Payment Methods
/// flow, which sends the closed set of backend-supported destinations to
/// `/v1/payout-destinations`. This screen deliberately does not collect local
/// bank fields that the API cannot verify or store safely.
class AddBankAccountScreen extends StatelessWidget {
  const AddBankAccountScreen({super.key});

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
        'Add Payment Method',
        style: DesignTokens.oneLinerSemibold,
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_outlined,
            size: 56,
            color: DesignTokens.primaryGreen,
          ),
          const SizedBox(height: DesignTokens.s20),
          Text(
            'Set up a payout destination',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Choose NIMB Bank, Laxmi Bank, PayPal, or eSewa. Your payout destination is created and verified through the configured provider.',
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
