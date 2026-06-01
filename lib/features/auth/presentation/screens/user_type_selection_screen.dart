import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/auth_response_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/role_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Select User Type — pixel-matched to Figma frame `9365:7986`.
///
/// Brand logo → "Welcome to ReelCommerce!" (24px) + subtitle → three tappable
/// rows (green numbered badge + title/description + chevron, divided by thin
/// lines) → "Already have an account? Sign In" footer.
class UserTypeSelectionScreen extends ConsumerStatefulWidget {
  final AuthResponseDto authData;

  const UserTypeSelectionScreen({super.key, required this.authData});

  @override
  ConsumerState<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState
    extends ConsumerState<UserTypeSelectionScreen> {
  List<RoleProfileDto> _existingRoles = [];
  bool _loadingRole = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roleNotifierProvider.notifier).loadRoles(widget.authData.accountId);
    });
  }

  Future<void> _selectRole(int roleInt) async {
    final accountId = widget.authData.accountId;

    final existing = _existingRoles.firstWhere(
      (r) => r.role == roleInt,
      orElse: () => RoleProfileDto(
        id: '',
        accountId: accountId,
        role: roleInt,
        status: 0,
      ),
    );

    setState(() => _loadingRole = true);

    final notifier = ref.read(roleNotifierProvider.notifier);

    if (existing.id.isNotEmpty && existing.isActivated) {
      _navigateForRole(roleInt);
      setState(() => _loadingRole = false);
      return;
    }

    if (existing.id.isEmpty) {
      await notifier.requestRole(accountId, roleInt);
    }

    await notifier.activateRole(accountId, roleInt);

    if (!mounted) return;
    setState(() => _loadingRole = false);
    _navigateForRole(roleInt);
  }

  void _navigateForRole(int role) {
    switch (role) {
      case 2:
        context.go(RouteNames.creatorHome);
      case 3:
        context.go(RouteNames.vendorHome);
      default:
        context.go(RouteNames.pickInterests);
    }
  }

  bool _isRoleActivated(int role) {
    return _existingRoles.any((r) => r.role == role && r.isActivated);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RolesState>(roleNotifierProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess: (roles) => setState(() => _existingRoles = roles),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: _loadingRole
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.s16,
                        DesignTokens.s40,
                        DesignTokens.s16,
                        DesignTokens.s16,
                      ),
                      child: Column(
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                width: 132,
                                height: 100,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 56,
                                      color: DesignTokens.primaryGreen,
                                    ),
                                    const SizedBox(height: DesignTokens.s4),
                                    Text(
                                      'STYLE MINT',
                                      style: DesignTokens.mediumSemibold
                                          .copyWith(
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
                                  Text(
                                    'Welcome to ReelCommerce!',
                                    textAlign: TextAlign.center,
                                    style: DesignTokens.titleLarge,
                                  ),
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
                          _RoleRow(
                            number: 1,
                            title: 'I want to Shop',
                            description:
                                'Discover products through creator reels. Shop the latest trends & get personalized recommendations',
                            isActivated: _isRoleActivated(1),
                            onTap: () => _selectRole(1),
                          ),
                          const _RoleDivider(),
                          _RoleRow(
                            number: 2,
                            title: 'I am a Creator',
                            description:
                                'Earn money from your content, Partner with top brands, Get 5-25% commission on sales',
                            isActivated: _isRoleActivated(2),
                            onTap: () => _selectRole(2),
                          ),
                          const _RoleDivider(),
                          _RoleRow(
                            number: 3,
                            title: 'I want to sell',
                            description:
                                'List your products on our marketplace, Reach millions through creators, Grow your business with influencer marketing',
                            isActivated: _isRoleActivated(3),
                            onTap: () => _selectRole(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: DesignTokens.s32,
                      top: DesignTokens.s8,
                    ),
                    child: GestureDetector(
                      onTap: () => context.go(RouteNames.signInMethod),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have an account ? ',
                              style: DesignTokens.mediumRegular.copyWith(
                                color: DesignTokens.textLight,
                              ),
                            ),
                            TextSpan(
                              text: 'Sign In',
                              style: DesignTokens.mediumSemibold.copyWith(
                                color: DesignTokens.primaryGreen,
                              ),
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
  final bool isActivated;
  final VoidCallback onTap;

  const _RoleRow({
    required this.number,
    required this.title,
    required this.description,
    required this.isActivated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s4,
          vertical: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActivated
                    ? DesignTokens.textMuted
                    : DesignTokens.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: isActivated
                  ? const Icon(Icons.check, color: DesignTokens.textWhite, size: 20)
                  : Text(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                        ),
                      ),
                      if (isActivated)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.primaryGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.chipRadius,
                            ),
                          ),
                          child: Text(
                            'Active',
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    description,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s16),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignTokens.textMuted,
              size: DesignTokens.iconSmall,
            ),
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
      child: Divider(
        color: DesignTokens.borderDefault,
        height: 1,
        thickness: 1,
      ),
    );
  }
}
