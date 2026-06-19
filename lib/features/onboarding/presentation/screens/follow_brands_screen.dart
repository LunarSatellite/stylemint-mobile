import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_sticky_bottom_bar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class _Brand {
  final String name;
  final String category;
  final String description;
  final String followers;
  const _Brand(this.name, this.category, this.description, this.followers);
}

/// Follow Brands — onboarding step after Follow Creators.
///
/// Shows a curated list of brands the user can follow to personalise their
/// feed. Tapping Proceed or Skip routes to the home screen.
class FollowBrandsScreen extends StatefulWidget {
  const FollowBrandsScreen({super.key});

  @override
  State<FollowBrandsScreen> createState() => _FollowBrandsScreenState();
}

class _FollowBrandsScreenState extends State<FollowBrandsScreen> {
  // TODO: replace with API once backend adds /v1/onboarding/brands endpoint.
  static const List<_Brand> _brands = [
    _Brand(
      'Nike',
      'Sports & Fashion',
      'Just Do It. Discover the latest in sportswear, sneakers, and street style.',
      '2.4M',
    ),
    _Brand(
      'Zara',
      'Fashion & Lifestyle',
      'Trend-forward clothing for every occasion, refreshed every week.',
      '1.8M',
    ),
    _Brand(
      'Sephora',
      'Beauty & Skincare',
      'Explore thousands of beauty products from top brands worldwide.',
      '3.1M',
    ),
    _Brand(
      'Apple',
      'Tech & Gadgets',
      'Innovation that changes the way you live, work, and play.',
      '5.6M',
    ),
    _Brand(
      'Lululemon',
      'Fitness & Wellness',
      'Premium activewear designed to move with you every step of the way.',
      '980k',
    ),
  ];

  final Set<String> _following = {};

  void _toggleFollow(String name) {
    setState(() {
      if (_following.contains(name)) {
        _following.remove(name);
      } else {
        _following.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, 0),
              child: _Header(),
            ),
            const SizedBox(height: DesignTokens.s24),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
                itemCount: _brands.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesignTokens.s20),
                itemBuilder: (_, i) {
                  final b = _brands[i];
                  return _BrandCard(
                    brand: b,
                    following: _following.contains(b.name),
                    onFollow: () => _toggleFollow(b.name),
                  );
                },
              ),
            ),
            SmStickyBottomBar(
              primaryLabel: 'Proceed',
              primaryTrailing: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: DesignTokens.buttonPrimaryText,
              ),
              onPrimary: () => context.go(RouteNames.home),
              secondaryLabel: 'Skip',
              onSecondary: () => context.go(RouteNames.home),
              showTopDivider: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Follow Brands You Love',
          textAlign: TextAlign.center,
          style: DesignTokens.titleMedium,
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'Stay updated with the latest drops, deals, and collections from your favourite brands.',
          textAlign: TextAlign.center,
          style: DesignTokens.bodyText,
        ),
      ],
    );
  }
}

class _BrandCard extends StatelessWidget {
  final _Brand brand;
  final bool following;
  final VoidCallback onFollow;

  const _BrandCard({
    required this.brand,
    required this.following,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: logo placeholder + name/category + Follow
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: DesignTokens.textMuted, size: 22),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brand.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.oneLinerSemibold,
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      brand.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.smallRegular,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              _FollowButton(following: following, onTap: onFollow),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            brand.description,
            style:
                DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight),
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 14, color: DesignTokens.textMuted),
              const SizedBox(width: 4),
              Text(
                '${brand.followers} followers',
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool following;
  final VoidCallback onTap;

  const _FollowButton({required this.following, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s12, vertical: DesignTokens.s8),
        decoration: BoxDecoration(
          color: following ? Colors.transparent : DesignTokens.primaryGreen,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          border: Border.all(
            color: following
                ? DesignTokens.borderDefault
                : DesignTokens.primaryGreen,
          ),
        ),
        child: Text(
          following ? 'Following' : 'Follow',
          style: DesignTokens.smallRegular.copyWith(
            color: following ? DesignTokens.textLight : DesignTokens.bgAppFoundation,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
