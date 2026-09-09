import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  static const _quickNav = [
    'Information We Collect',
    'How We Use Your Information',
    'Information Sharing',
    'Your Rights and Choices',
    'Data Security',
    'Cookies and Tracking',
    "Children's Privacy",
    'International Users',
    'Changes to This Policy',
    'Contact Us',
  ];

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _requestDataExport(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(profileRepositoryProvider)
        .requestDataExport();
    if (!context.mounted) return;
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not request your data export.')),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your data export request was received. We will notify you when it is ready.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Privacy Policy',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s8,
          DesignTokens.s16,
          DesignTokens.s32,
        ),
        children: [
          _LastUpdated('Thursday, 15th Aug, 2023, 12:45 AM'),
          const SizedBox(height: DesignTokens.s24),

          // Quick Navigation
          _SectionHeading('Quick Navigation'),
          const SizedBox(height: DesignTokens.s8),
          for (final item in _quickNav) ...[
            _BulletLink(item, onTap: () {}),
          ],
          const SizedBox(height: DesignTokens.s24),

          // 1. Information We Collect
          _SectionHeading('1. Information We Collect'),
          const SizedBox(height: DesignTokens.s8),
          const _Body(
            'We collect information you provide directly to us including:',
          ),
          const SizedBox(height: DesignTokens.s8),
          const _Bullet(
            'Account Information: Name, email address, phone number, password, date of birth',
          ),
          const _Bullet(
            'Profile Information: Profile photo, bio, preferences, social media links',
          ),
          const _Bullet(
            'Purchase Information: Shipping address, billing address, payment method details',
          ),
          const _Bullet('Communications: Messages, support tickets, reviews'),
          const _Bullet(
            "Creator Content: If you're a creator, links to your social media content",
          ),
          const _Bullet(
            'Vendor Information: Business details, tax IDs, banking information',
          ),
          const SizedBox(height: DesignTokens.s12),
          const _Body(
            'Automatically Collected Information. When you use our Service, we automatically collect:',
          ),
          const SizedBox(height: DesignTokens.s8),
          const _Bullet(
            'Device Information: Device type, operating system, unique device identifiers, IP address',
          ),
          const _Bullet(
            'Usage Data: Pages viewed, features used, time spent, clicks, scrolls, reels watched',
          ),
          const _Bullet(
            'Location Data: Approximate location based on IP (precise location only with permission)',
          ),
          const _Bullet('Cookies and Similar Technologies: See Section 6'),
          const SizedBox(height: DesignTokens.s24),

          // 2. Your Rights and Choices
          _SectionHeading('2. Your Rights and Choices'),
          const SizedBox(height: DesignTokens.s8),
          const _Body('You have the right to:'),
          const SizedBox(height: DesignTokens.s8),
          const _Bullet('Access your personal information'),
          const _Bullet('Correct inaccurate information'),
          const _Bullet('Delete your account and data'),
          const _Bullet('Opt-out of marketing communications'),
          const _Bullet('Disable cookies (may affect functionality)'),
          const _Bullet('Export your data (GDPR/CCPA)'),
          const SizedBox(height: DesignTokens.s12),
          const _Body('To exercise these rights:'),
          const SizedBox(height: DesignTokens.s8),
          _BulletLink(
            'Request Data Access',
            onTap: () => _launch('mailto:privacy@reelcommerce.com'),
          ),
          _BulletLink(
            'Download My Data',
            onTap: () => _requestDataExport(context, ref),
          ),
          _BulletLink('Delete My Account', onTap: () {}),
          const SizedBox(height: DesignTokens.s24),

          // 3. Contact Us
          _SectionHeading('3. Contact Us'),
          const SizedBox(height: DesignTokens.s8),
          const _Body('Questions? Contact our privacy team:'),
          const SizedBox(height: DesignTokens.s8),
          _LabelLink(
            label: 'Email: ',
            linkText: 'privacy@reelcommerce.com',
            onTap: () => _launch('mailto:privacy@reelcommerce.com'),
          ),
          const SizedBox(height: DesignTokens.s4),
          _LabelLink(
            label: 'Mail: ',
            linkText:
                'ReelCommerce Inc., 123 Privacy Lane San Francisco, CA 94102',
            onTap: () => _launch(
              'https://maps.google.com/?q=123+Privacy+Lane,+San+Francisco,+CA+94102',
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          _LabelLink(
            label: 'Data Protection Officer: ',
            linkText: 'dpo@reelcommerce.com',
            onTap: () => _launch('mailto:dpo@reelcommerce.com'),
          ),
          const SizedBox(height: DesignTokens.s32),
        ],
      ),
    );
  }
}

class _LastUpdated extends StatelessWidget {
  const _LastUpdated(this.date);
  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: DesignTokens.textMuted,
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(
            'Last Updated: $date',
            style: DesignTokens.smallRegular,
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textWhite,
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        height: 1.6,
        color: DesignTokens.textLight,
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: DesignTokens.textLight,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                height: 1.6,
                color: DesignTokens.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLink extends StatelessWidget {
  const _BulletLink(this.text, {required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: CircleAvatar(
              radius: 3,
              backgroundColor: DesignTokens.primaryGreen,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                height: 1.6,
                color: DesignTokens.primaryGreen,
                decoration: TextDecoration.underline,
                decorationColor: DesignTokens.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelLink extends StatelessWidget {
  const _LabelLink({
    required this.label,
    required this.linkText,
    required this.onTap,
  });
  final String label;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6, right: 8),
          child: CircleAvatar(
            radius: 3,
            backgroundColor: DesignTokens.textLight,
          ),
        ),
        Expanded(
          child: Wrap(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  height: 1.6,
                  color: DesignTokens.textLight,
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  linkText,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    height: 1.6,
                    color: DesignTokens.primaryGreen,
                    decoration: TextDecoration.underline,
                    decorationColor: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
