import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/auth_response_dto.dart';

/// Select User Type — pixel-matched to Figma frame `9365:7986`.
///
/// Brand logo → "Welcome to ReelCommerce!" (24px) + subtitle → three tappable
/// rows (green numbered badge + title/description + chevron, divided by thin
/// lines) → "Already have an account? Sign In" footer.
class UserTypeSelectionScreen extends ConsumerWidget {
  final AuthResponseDto authData;

  const UserTypeSelectionScreen({super.key, required this.authData});

  void _selectRole(BuildContext context, String role) {
    // TODO: persist selected role + tokens (Tasks 10–13).
    // Customer onboarding continues to Pick Interests → Follow Creators.
    switch (role) {
      case 'creator':
        context.go(RouteNames.creatorHome);
        break;
      case 'vendor':
        context.go(RouteNames.vendorHome);
        break;
      default:
        // Customer onboarding: continue to interests selection.
        context.go(RouteNames.pickInterests);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16, DesignTokens.s40, DesignTokens.s16, DesignTokens.s16),
                child: Column(
                  children: [
                    // Header (logo + title), gap 24
                    Column(
                      children: [
                        // Brand logo (placeholder — TODO: real Figma asset)
                        SizedBox(
                          width: 132,
                          height: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_bag_outlined,
                                  size: 56, color: DesignTokens.primaryGreen),
                              const SizedBox(height: DesignTokens.s4),
                              Text(
                                'STYLE MINT',
                                style: DesignTokens.mediumSemibold.copyWith(
                                  color: DesignTokens.primaryGreen,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s24),
                        Column(
                          children: [
                            Text('Welcome to ReelCommerce!',
                                textAlign: TextAlign.center,
                                style: DesignTokens.titleLarge),
                            const SizedBox(height: DesignTokens.s8),
                            Text(
                              'Ready to shop in the future? Choose your Path below',
                              textAlign: TextAlign.center,
                              style: DesignTokens.bodyText,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.s40),

                    // Role options
                    _RoleRow(
                      number: 1,
                      title: 'I want to Shop',
                      description:
                          'Discover products through creator reels. Shop the latest trends & get personalized recommendations',
                      onTap: () => _selectRole(context, 'customer'),
                    ),
                    const _RoleDivider(),
                    _RoleRow(
                      number: 2,
                      title: 'I am a Creator',
                      description:
                          'Earn money from your content, Partner with top brands, Get 5-25% commission on sales',
                      onTap: () => _selectRole(context, 'creator'),
                    ),
                    const _RoleDivider(),
                    _RoleRow(
                      number: 3,
                      title: 'I want to sell',
                      description:
                          'List your products on our marketplace, Reach millions through creators, Grow your business with influencer marketing',
                      onTap: () => _selectRole(context, 'vendor'),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s32, top: DesignTokens.s8),
              child: GestureDetector(
                onTap: () => context.go(RouteNames.signInMethod),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Already have an account ? ',
                        style: DesignTokens.mediumRegular
                            .copyWith(color: DesignTokens.textLight),
                      ),
                      TextSpan(
                        text: 'Sign In',
                        style: DesignTokens.mediumSemibold
                            .copyWith(color: DesignTokens.primaryGreen),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tappable role row: [green numbered badge] [title + description] [chevron].
class _RoleRow extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleRow({
    required this.number,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s4, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Numbered badge
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: DesignTokens.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.buttonPrimaryText,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.s16),
            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: DesignTokens.mediumSemibold
                          .copyWith(color: DesignTokens.textWhite)),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    description,
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s16),
            const Icon(Icons.chevron_right_rounded,
                color: DesignTokens.textMuted, size: DesignTokens.iconSmall),
          ],
        ),
      ),
    );
  }
}

/// Thin divider indented to align under the row text (not the badge).
class _RoleDivider extends StatelessWidget {
  const _RoleDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 56),
      child: Divider(color: DesignTokens.borderDefault, height: 1, thickness: 1),
    );
  }
}
