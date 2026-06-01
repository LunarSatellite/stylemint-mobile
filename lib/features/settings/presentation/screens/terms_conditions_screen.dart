import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const _content = '''
Terms & Conditions

Last updated: January 2025

1. Acceptance of Terms
By using Style Mint, you agree to these terms. If you do not agree, do not use the service.

2. Account Registration
You must provide accurate information and maintain the security of your account. You are responsible for all activity under your account.

3. Purchases and Payments
All purchases are subject to our payment terms. Prices are listed in NPR and include applicable taxes.

4. Returns and Refunds
Returns are accepted within 7 days of delivery for eligible items. Refunds are processed within 5-10 business days.

5. User Conduct
You agree not to use the service for any unlawful purpose or to harass other users.

6. Intellectual Property
All content on Style Mint is protected by copyright and other intellectual property laws.

7. Limitation of Liability
Style Mint is provided "as is" without warranties. We are not liable for indirect damages.

8. Termination
We may suspend or terminate your account for violations of these terms.

9. Governing Law
These terms are governed by the laws of Nepal.

Contact us at legal@stylemint.com for questions.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Terms & Conditions', style: DesignTokens.sectionInnerTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Text(
          _content,
          style: const TextStyle(
            color: DesignTokens.textLight,
            fontFamily: DesignTokens.fontFamily,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
