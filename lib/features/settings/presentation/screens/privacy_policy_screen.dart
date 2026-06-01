import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _content = '''
Privacy Policy

Last updated: January 2025

1. Information We Collect
We collect information you provide directly, such as your name, email address, phone number, and profile information when you create an account or make a purchase.

2. How We Use Your Information
We use your information to provide and improve our services, process transactions, send notifications, and personalize your experience.

3. Sharing Your Information
We do not sell your personal information. We share data only with service providers who help us operate the platform.

4. Data Security
We implement security measures to protect your data, including encryption and secure storage.

5. Your Rights
You can access, update, or delete your data through your account settings. Contact support for additional requests.

6. Cookies and Tracking
We use essential cookies and analytics to improve the service. You can manage preferences in settings.

7. Children's Privacy
Style Mint is not intended for users under 13. We do not knowingly collect data from children.

8. Changes to This Policy
We may update this policy from time to time. Continued use constitutes acceptance.

Contact us at privacy@stylemint.com for questions.
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
        title: const Text('Privacy Policy', style: DesignTokens.sectionInnerTitle),
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
