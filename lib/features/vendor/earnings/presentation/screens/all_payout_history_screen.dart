import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_placeholder_body.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Placeholder for the full payout history list.
///
/// Route wired on the `savyata` branch; implementation not yet committed.
class AllPayoutHistoryScreen extends StatelessWidget {
  const AllPayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Payout History'),
      ),
      body: const VendorPlaceholderBody(
        icon: Icons.receipt_long_outlined,
        title: 'Payout History',
        message: 'This screen is coming soon.',
      ),
    );
  }
}
