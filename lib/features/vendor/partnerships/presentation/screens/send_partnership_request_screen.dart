import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_placeholder_body.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Placeholder for the "Send partnership request" flow.
///
/// The route and entry point (Vendor → Partnerships) were wired on the
/// `savyata` branch, but the screen implementation was never committed.
/// This placeholder keeps the route navigable until the real flow lands.
class SendPartnershipRequestScreen extends StatelessWidget {
  const SendPartnershipRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Send Partnership Request'),
      ),
      body: const VendorPlaceholderBody(
        icon: Icons.handshake_outlined,
        title: 'Send Partnership Request',
        message: 'This flow is coming soon.',
      ),
    );
  }
}
