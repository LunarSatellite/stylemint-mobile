import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// About ReelCommerce — informational screen.
/// Pixel-matched to `About Reelcommerce.pdf` (Customer User): brand logo,
/// "Discover. Shop. Earn" tagline, version, Our Mission, platform stats
/// (250k Products / 5k Creators / 1000+ Brands) and social handle pills.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = 'Version 1.2.0 (Build 456)';
  static const _mission =
      'ReelCommerce is revolutionizing e-commerce by connecting customers with '
      'products through engaging short-form video content, empowering creators '
      'to earn while helping shoppers discover amazing products in an '
      'entertaining way.';

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
        title: const Text('About ReelCommerce',
            style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s24,
            DesignTokens.s16, DesignTokens.s32),
        children: [
          // Brand logo (placeholder mark, consistent with user-type screen).
          Column(
            children: [
              const Icon(Icons.shopping_bag_outlined,
                  size: 56, color: DesignTokens.primaryGreen),
              const SizedBox(height: DesignTokens.s8),
              Text('STYLE MINT',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.primaryGreen,
                    letterSpacing: 2,
                  )),
              const SizedBox(height: DesignTokens.s16),
              Text('Discover. Shop. Earn',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  )),
              const SizedBox(height: DesignTokens.s4),
              Text(_version,
                  textAlign: TextAlign.center,
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textMuted)),
            ],
          ),
          const SizedBox(height: DesignTokens.s32),

          // Our Mission
          Text('Our Mission', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s8),
          Text(_mission, style: DesignTokens.bodyText),
          const SizedBox(height: DesignTokens.s32),

          // Platform stats
          Text('Platform Stats', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: const [
              Expanded(child: _StatTile(value: '250k', label: 'Products')),
              SizedBox(width: DesignTokens.s12),
              Expanded(child: _StatTile(value: '5k', label: 'Creators')),
              SizedBox(width: DesignTokens.s12),
              Expanded(child: _StatTile(value: '1000+', label: 'Brands')),
            ],
          ),
          const SizedBox(height: DesignTokens.s32),

          // Social handles
          Text('Follow us', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              for (final s in const [
                ('Instagram', Icons.camera_alt_outlined),
                ('TikTok', Icons.music_note),
                ('YouTube', Icons.play_circle_outline),
                ('Facebook', Icons.facebook),
              ])
                _SocialPill(
                  label: s.$1,
                  icon: s.$2,
                  onTap: () =>
                      SmSnackbar.info(context, '${s.$1} — coming soon'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          Text(value, style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s4),
          Text(label,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight)),
        ],
      ),
    );
  }
}

class _SocialPill extends StatelessWidget {
  const _SocialPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x38FFFFFF)), // white @ 22%
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: DesignTokens.textWhite),
            const SizedBox(width: DesignTokens.s8),
            Text(label, style: DesignTokens.smallRegular),
          ],
        ),
      ),
    );
  }
}
