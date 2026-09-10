import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
              Text(
                'Version 1.2.0 (Build 456)',
                textAlign: TextAlign.center,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s32),

          // Our Mission
          const _SectionHeading('Our Mission'),
          const SizedBox(height: DesignTokens.s8),
          const _Body(
            'StyleMint is revolutionizing e-commerce by connecting customers with '
            'products through engaging short-form video content, empowering creators '
            'to earn while helping shoppers discover amazing products in an entertaining way.',
          ),
          const SizedBox(height: DesignTokens.s32),

          // Platform Stats
          const _SectionHeading('Platform Stats'),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: const [
              Expanded(
                child: _StatTile(
                  icon: Icons.inventory_2_outlined,
                  value: '250k',
                  label: 'Products',
                ),
              ),
              SizedBox(width: DesignTokens.s12),
              Expanded(
                child: _StatTile(
                  icon: Icons.videocam_outlined,
                  value: '5k',
                  label: 'Creators',
                ),
              ),
              SizedBox(width: DesignTokens.s12),
              Expanded(
                child: _StatTile(
                  icon: Icons.store_outlined,
                  value: '1000+',
                  label: 'Brands',
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: const [
              Expanded(
                child: _StatTile(
                  icon: Icons.play_circle_outline,
                  value: '15m',
                  label: 'Reels',
                ),
              ),
              SizedBox(width: DesignTokens.s12),
              Expanded(
                child: _StatTile(
                  icon: Icons.access_time_outlined,
                  value: '98%',
                  label: 'On-Time',
                ),
              ),
              SizedBox(width: DesignTokens.s12),
              Expanded(
                child: _StatTile(
                  icon: Icons.star_outline_rounded,
                  value: '4.8',
                  label: 'Rating',
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s32),

          // Company Information
          const _SectionHeading('Company Information'),
          const SizedBox(height: DesignTokens.s8),
          _LabelLink(
            label: 'Email: ',
            linkText: 'hello@stylemint.com',
            onTap: () => _launch('mailto:hello@stylemint.com'),
          ),
          const SizedBox(height: DesignTokens.s4),
          _LabelLink(
            label: 'Headquarters: ',
            linkText:
                'StyleMint Inc., 123 Privacy Lane San Francisco, CA 94102',
            onTap: () => _launch(
              'https://maps.google.com/?q=123+Privacy+Lane,+San+Francisco,+CA+94102',
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          _LabelLink(
            label: 'Website: ',
            linkText: 'www.stylemint.com',
            onTap: () => _launch('https://www.stylemint.com'),
          ),
          const SizedBox(height: DesignTokens.s32),

          // Follow us on
          const _SectionHeading('Follow us on:'),
          const SizedBox(height: DesignTokens.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _SocialCircle(
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFFFF0000),
                onTap: () => _launch('https://youtube.com'),
              ),
              const SizedBox(width: DesignTokens.s16),
              _SocialCircle(
                icon: Icons.camera_alt_outlined,
                color: const Color(0xFFE1306C),
                onTap: () => _launch('https://instagram.com'),
              ),
              const SizedBox(width: DesignTokens.s16),
              _SocialCircle(
                icon: Icons.facebook,
                color: const Color(0xFF1877F2),
                onTap: () => _launch('https://facebook.com'),
              ),
              const SizedBox(width: DesignTokens.s16),
              _SocialCircle(
                icon: Icons.music_note_rounded,
                color: const Color(0xFF010101),
                onTap: () => _launch('https://tiktok.com'),
              ),
            ],
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

          // App Information
          const _SectionHeading('App Information'),
          const SizedBox(height: DesignTokens.s8),
          const _InfoRow(label: 'Version:', value: '1.2.0'),
          const _InfoRow(label: 'Build:', value: '456'),
          const _InfoRow(label: 'Released:', value: 'December 15, 2024'),
          const SizedBox(height: DesignTokens.s4),
          _BulletLink(
            'Check for Updates',
            onTap: () => _comingSoon(context, 'Update checking'),
          ),
          _BulletLink(
            'View Release Notes',
            onTap: () => _comingSoon(context, 'Release notes'),
          ),
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
          const Center(
            child: Text(
              '© 2024 StyleMint Inc. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: DesignTokens.textLight),
          const SizedBox(height: DesignTokens.s8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialCircle extends StatelessWidget {
  const _SocialCircle({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 26),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

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
          Text(
            '$label  ',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              height: 1.6,
              color: DesignTokens.textLight,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              height: 1.6,
              color: DesignTokens.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}
