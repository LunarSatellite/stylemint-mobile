import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/widgets/offer_emi_section.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Offer EMI" for one listing, opened from the product's action sheet. The
/// same section also sits in the product edit form's pricing step.
class VendorProductEmiScreen extends StatelessWidget {
  const VendorProductEmiScreen({
    required this.productId,
    this.productName,
    super.key,
  });

  final String productId;

  /// From the route's `extra` when there is one; the terms carry it too.
  final String? productName;

  @override
  Widget build(BuildContext context) {
    final name = productName?.trim();
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Offer EMI'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            if (name != null && name.isNotEmpty) ...[
              Text(name, style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s12),
            ],
            OfferEmiSection(productId: productId, hideWhenUnavailable: false),
          ],
        ),
      ),
    );
  }
}
