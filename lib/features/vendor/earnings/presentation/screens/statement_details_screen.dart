import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_placeholder_body.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Lightweight payout/statement line item passed to [StatementDetailsScreen]
/// via `GoRouter` `state.extra`.
///
/// Defined here (rather than in the earnings domain layer) because the
/// `savyata` branch referenced the type from the router without committing a
/// model. Replace with a proper domain entity when the real screen lands.
class VendorPayoutItem {
  const VendorPayoutItem({
    required this.id,
    required this.title,
    this.subtitle = '',
  });

  final String id;
  final String title;
  final String subtitle;
}

/// Placeholder for a single payout statement's details.
///
/// Route wired on the `savyata` branch; implementation not yet committed.
class StatementDetailsScreen extends StatelessWidget {
  const StatementDetailsScreen({required this.item, super.key});

  final VendorPayoutItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Statement Details'),
      ),
      body: VendorPlaceholderBody(
        icon: Icons.description_outlined,
        title: item.title.isEmpty ? 'Statement Details' : item.title,
        message: 'This screen is coming soon.',
      ),
    );
  }
}
