import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_placeholder_body.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Placeholder for verifying a newly added bank account.
///
/// Route wired on the `savyata` branch; implementation not yet committed.
class BankVerificationScreen extends StatelessWidget {
  const BankVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Bank Verification'),
      ),
      body: const VendorPlaceholderBody(
        icon: Icons.verified_outlined,
        title: 'Bank Verification',
        message: 'This screen is coming soon.',
      ),
    );
  }
}
