import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/presentation/widgets/evidence_answer_panel.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Free-text questions answered from time-valid records, with the records
/// shown. The same panel that sits under a product page, given a whole
/// screen for questions that are not about one product.
///
/// There is no control on this screen that changes anything. It reads.
class EvidenceAnswerScreen extends StatelessWidget {
  const EvidenceAnswerScreen({super.key, this.seedQuery = ''});

  /// Optional question to arrive with, e.g. from another surface.
  final String seedQuery;

  /// Keyed on the empty string so this screen's answer is its own.
  static const String familyKey = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Evidence'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s12,
            DesignTokens.s16,
            DesignTokens.s24,
          ),
          children: [
            EvidenceAnswerPanel(
              familyKey: familyKey,
              seedQuery: seedQuery,
              autoAsk: seedQuery.trim().isNotEmpty,
            ),
            const SizedBox(height: DesignTokens.s16),
            const MallEyebrow('Nothing here buys anything'),
            const SizedBox(height: DesignTokens.s8),
            const Text(
              'This screen only reads records. It cannot set a price, hold '
              'stock, move money or put anything in your bag. If an answer '
              'points at a product, opening it is your call.',
              style: DesignTokens.smallRegular,
            ),
          ],
        ),
      ),
    );
  }
}
