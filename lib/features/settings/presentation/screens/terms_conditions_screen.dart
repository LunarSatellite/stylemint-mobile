import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Terms of Service',
            style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16, DesignTokens.s8, DesignTokens.s16, DesignTokens.s32),
        children: [
          _LastUpdated('Thursday, 15th Aug, 2023, 12:45 AM'),
          const SizedBox(height: DesignTokens.s24),

          // 1. Acceptance of Terms
          _SectionHeading('1. Acceptance of Terms'),
          const SizedBox(height: DesignTokens.s8),
          _Body(
            'By accessing or using the StyleMint platform ("Service"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the Service.',
          ),
          const SizedBox(height: DesignTokens.s24),

          // 2. User of Service
          _SectionHeading('2. User of Service'),
          const SizedBox(height: DesignTokens.s12),
          _SubSection(
            number: '2.1',
            title: 'Eligibility',
            body: 'You must be at least 13 years old to use this Service. By using the Service, you represent and warrant that you meet this requirement.',
          ),
          const SizedBox(height: DesignTokens.s12),
          _SubSection(
            number: '2.2',
            title: 'Account Registration',
            body: 'You may be required to create an account to access certain features. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete.',
          ),
          const SizedBox(height: DesignTokens.s24),

          // 3. Contact Us
          _SectionHeading('3. Contact Us'),
          const SizedBox(height: DesignTokens.s8),
          _Body('Questions? Contact our privacy team:'),
          const SizedBox(height: DesignTokens.s8),
          _LinkRow(
            label: 'Email: ',
            linkText: 'legal@stylemint.com',
            onTap: () => _launch('mailto:legal@stylemint.com'),
          ),
          const SizedBox(height: DesignTokens.s4),
          _LinkRow(
            label: 'Legal Officer: ',
            linkText: 'lgo@stylemint.com',
            onTap: () => _launch('mailto:lgo@stylemint.com'),
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
        const Icon(Icons.calendar_today_outlined,
            size: 14, color: DesignTokens.textMuted),
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

class _SubSection extends StatelessWidget {
  const _SubSection({
    required this.number,
    required this.title,
    required this.body,
  });
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$number  ',
            style: DesignTokens.mediumSemibold
                .copyWith(color: DesignTokens.textWhite)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s4),
              _Body(body),
            ],
          ),
        ),
      ],
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

class _LinkRow extends StatelessWidget {
  const _LinkRow({
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
      children: [
        if (label.isNotEmpty)
          Text(label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                height: 1.6,
                color: DesignTokens.textLight,
              )),
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
    );
  }
}
