import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_placeholder_body.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Placeholder for selecting/changing the active payout method.
///
/// Route wired on the `savyata` branch; implementation not yet committed.
class ChangePaymentMethodScreen extends StatelessWidget {
  const ChangePaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Payment Method'),
      ),
      body: const VendorPlaceholderBody(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Payment Method',
        message: 'This screen is coming soon.',
      ),
    );
  }
}
