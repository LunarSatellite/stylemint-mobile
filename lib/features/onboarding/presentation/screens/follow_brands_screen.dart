import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_list_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_sticky_bottom_bar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Follow Brands — onboarding step after Follow Creators.
///
/// Real approved-brand list from `GET /v1/brands` (same source
/// [BrandsScreen] uses). Follow calls the real one-way follow graph
/// (POST/DELETE /v1/follows/{vendorAccountId}) — the follow graph is
/// generic per-account, not creator-only, so a vendor's account id works
/// the same way a creator's does. Previously a static list of 5 fake
/// brands (Nike/Zara/Sephora/Apple/Lululemon) whose Follow button only
/// flipped local state and never called any API.
class FollowBrandsScreen extends ConsumerWidget {
  const FollowBrandsScreen({super.key});

  Future<void> _toggle(WidgetRef ref, BuildContext context, String vendorAccountId) async {
    try {
      await ref.read(followNotifierProvider.notifier).toggle(vendorAccountId);
    } catch (_) {
      if (context.mounted) {
        SmSnackbar.error(context, "Couldn't update follow. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(brandsListProvider);
    final followed = ref.watch(followNotifierProvider);

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
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: DesignTokens.primaryGreen)),
                error: (_, _e) => Center(
                  child: Text("Couldn't load brands.",
                      style: DesignTokens.bodyText),
                ),
                data: (brands) => brands.isEmpty
                    ? Center(
                        child: Text('No approved brands yet — check back soon.',
                            style: DesignTokens.bodyText),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s16),
                        itemCount: brands.length,
                        separatorBuilder: (_, _i) =>
                            const SizedBox(height: DesignTokens.s20),
                        itemBuilder: (_, i) {
                          final b = brands[i];
                          return _BrandCard(
                            brand: b,
                            following: followed.contains(b.vendorAccountId),
                            onFollow: () =>
                                _toggle(ref, context, b.vendorAccountId),
                          );
                        },
                      ),
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
  final BrandListItemDto brand;
  final bool following;
  final VoidCallback onFollow;

  const _BrandCard({
    required this.brand,
    required this.following,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final logo = brand.logoUrl;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: (logo == null || logo.isEmpty)
                      ? const ColoredBox(
                          color: DesignTokens.bgAppBodyLight,
                          child: Icon(Icons.storefront_rounded,
                              color: DesignTokens.textMuted, size: 22),
                        )
                      : Image.network(logo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _e, _s) => const ColoredBox(
                              color: DesignTokens.bgAppBodyLight,
                              child: Icon(Icons.storefront_rounded,
                                  color: DesignTokens.textMuted, size: 22))),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  brand.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.oneLinerSemibold,
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              _FollowButton(following: following, onTap: onFollow),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              const Icon(Icons.percent_rounded,
                  size: 14, color: DesignTokens.textMuted),
              const SizedBox(width: 4),
              Text(
                '${brand.commissionRangeLabel} commission for creators',
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
