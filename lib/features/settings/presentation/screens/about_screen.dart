import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<PackageInfo> _packageInfo;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // These bullet links were all previously `onTap: () {}` — styled and
  // laid out exactly like the working links above them, but silently doing
  // nothing when tapped, with no page or content behind them yet.
  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'About StyleMint',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s24,
          DesignTokens.s16,
          DesignTokens.s32 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          // Logo + Tagline
          Column(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: DesignTokens.primaryGreen,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                'STYLE MINT',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.primaryGreen,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              const Text(
                'Discover. Shop. Earn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(height: DesignTokens.s4),
              FutureBuilder<PackageInfo>(
                future: _packageInfo,
                builder: (context, snapshot) {
                  final text = snapshot.hasData
                      ? 'Version ${snapshot.data!.version} '
                            '(Build ${snapshot.data!.buildNumber})'
                      : 'Version unavailable';
                  return Text(
                    text,
                    textAlign: TextAlign.center,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s32),

          // Our Mission
          const _SectionHeading('Our Mission'),
          const SizedBox(height: DesignTokens.s8),
          const _Body(
            'StyleMint is revolutionizing e-commerce by connecting customers '
            'with products through engaging short-form video content, '
            'empowering '
            'creators to earn while helping shoppers discover amazing products '
            'in an entertaining way.',
          ),
          const SizedBox(height: DesignTokens.s32),

          // Support
          const _SectionHeading('Support'),
          const SizedBox(height: DesignTokens.s8),
          _LabelLink(
            label: 'Email: ',
            linkText: 'help@stylemint.app',
            onTap: () => _launch('mailto:help@stylemint.app'),
          ),
          const SizedBox(height: DesignTokens.s32),

          // Legal
          const _SectionHeading('Legal'),
          const SizedBox(height: DesignTokens.s8),
          _BulletLink(
            'Terms of Service',
            onTap: () => context.push('${RouteNames.settings}/terms'),
          ),
          _BulletLink(
            'Privacy Policy',
            onTap: () => context.push('${RouteNames.settings}/privacy'),
          ),
          _BulletLink(
            'Cookie Policy',
            onTap: () => _comingSoon(context, 'Cookie Policy'),
          ),
          _BulletLink(
            'Community Guidelines',
            onTap: () => _comingSoon(context, 'Community Guidelines'),
          ),
          _BulletLink(
            'Intellectual Property',
            onTap: () => _comingSoon(context, 'Intellectual Property'),
          ),
          const SizedBox(height: DesignTokens.s32),

          // Resources
          const _SectionHeading('Resources'),
          const SizedBox(height: DesignTokens.s8),
          _BulletLink(
            'Help Center',
            onTap: () => context.push(RouteNames.support),
          ),
          _BulletLink(
            'Become a Creator',
            onTap: () => context.push(RouteNames.creatorApply),
          ),
          _BulletLink(
            'Sell on StyleMint',
            onTap: () => context.push(RouteNames.vendorApply),
          ),
          _BulletLink(
            'Press Kit',
            onTap: () => _comingSoon(context, 'Press Kit'),
          ),
          _BulletLink('Careers', onTap: () => _comingSoon(context, 'Careers')),
          _BulletLink('Blog', onTap: () => _comingSoon(context, 'Blog')),
          const SizedBox(height: DesignTokens.s32),

          // Licenses
          const _SectionHeading('Licenses'),
          const SizedBox(height: DesignTokens.s8),
          _BulletLink(
            'Open Source Licenses',
            onTap: () => showLicensePage(context: context),
          ),
          _BulletLink(
            'Third-Party Services',
            onTap: () => _comingSoon(context, 'Third-party services list'),
          ),
          const SizedBox(height: DesignTokens.s32),

          // Footer
          Center(
            child: Text(
              '© ${DateTime.now().year} StyleMint. All rights reserved.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                color: DesignTokens.textMuted,
              ),
            ),
          ),
        ],
      ),
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
        fontSize: 16,
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
      ),
    );
  }
}
