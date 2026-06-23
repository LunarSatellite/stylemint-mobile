import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_placeholder_body.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Placeholder for adding a bank account as a payout destination.
///
/// Route wired on the `savyata` branch; implementation not yet committed.
class AddBankAccountScreen extends StatelessWidget {
  const AddBankAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Add Bank Account'),
      ),
      body: const VendorPlaceholderBody(
        icon: Icons.account_balance_outlined,
        title: 'Add Bank Account',
        message: 'This screen is coming soon.',
      ),
    );
  }
}
