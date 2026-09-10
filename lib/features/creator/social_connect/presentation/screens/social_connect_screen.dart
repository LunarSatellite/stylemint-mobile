import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/notifiers/social_connect_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/widgets/platform_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/onboarding_step_progress.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class SocialConnectScreen extends ConsumerWidget {
  const SocialConnectScreen({super.key, this.isOnboarding = false});

  /// When reached as a post-approval step the screen shows a "Continue to
  /// Dashboard" action (connecting is optional, so it doubles as skip). When
  /// reached from the dashboard later it's `false` — a normal back-navigable
  /// management screen.
  final bool isOnboarding;

  /// Fires the OAuth flow. The notifier opens the provider authorize page in an
  /// in-app browser; the backend exchanges the code server-side and redirects
  /// to `stylemint://social-connected`, which routes back to
  /// [SocialConnectNotifier.onConnectReturn] to close the browser and refresh.
  Future<void> _connect(
    BuildContext context,
    WidgetRef ref,
    SocialPlatform platform,
  ) async {
    final failure = await ref
        .read(socialConnectNotifierProvider.notifier)
        .connect(platform);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not connect ${platform.displayName}. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialConnectNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: Text('Connect Accounts', style: DesignTokens.oneLinerSemibold),
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
      ),
      bottomNavigationBar: isOnboarding
          ? SafeArea(
              minimum: const EdgeInsets.all(DesignTokens.s16),
              child: SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  style: DesignTokens.primaryButtonStyle(),
                  onPressed: () =>
                      context.pushReplacement(RouteNames.creatorHome),
                  child: Text(
                    'Continue to Dashboard',
                    style: DesignTokens.oneLinerSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText,
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOnboarding)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s16,
                  DesignTokens.s16,
                  0,
                ),
                child: OnboardingStepProgress(step: 1, total: 2),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s8,
              ),
              child: Text(
                isOnboarding
                    ? 'Link your social platforms to import reels and tag '
                          'products. You can also do this later from your '
                          'dashboard.'
                    : 'Connected Platforms',
                style: isOnboarding
                    ? DesignTokens.bodyText
                    : DesignTokens.titleLarge,
              ),
            ),
            Expanded(
              child: state.maybeWhen(
                loadSuccess: (accounts) {
                  final notifier = ref.read(
                    socialConnectNotifierProvider.notifier,
                  );
                  final connectedPlatforms = accounts
                      .where((a) => a.isConnected)
                      .map((a) => a.platform)
                      .toSet();
                  final available = SocialPlatform.values
                      .where((p) => !connectedPlatforms.contains(p))
                      .toList(growable: false);

                  return RefreshIndicator(
                    color: DesignTokens.primaryGreen,
                    onRefresh: () => notifier.load(),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s16,
                      ),
                      children: [
                        if (accounts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: DesignTokens.s8,
                            ),
                            child: Text(
                              'No platforms connected yet. Link one below to '
                              'import your reels and tag products.',
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textLight,
                              ),
                            ),
                          )
                        else
                          ...accounts.map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: DesignTokens.s8,
                              ),
                              child: PlatformCard(
                                account: a,
                                onConnect: () =>
                                    _connect(context, ref, a.platform),
                                onDisconnect: () =>
                                    notifier.disconnect(a.platform),
                              ),
                            ),
                          ),
                        if (available.isNotEmpty) ...[
                          const SizedBox(height: DesignTokens.s16),
                          Text(
                            'Add a Platform',
                            style: DesignTokens.sectionInnerTitle,
                          ),
                          const SizedBox(height: DesignTokens.s8),
                          ...available.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: DesignTokens.s8,
                              ),
                              child: _AddPlatformTile(
                                platform: p,
                                onTap: () => _connect(context, ref, p),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loadFailure: (failure) => SmErrorView(
                  message: 'Failed to load platforms.',
                  onRetry: () =>
                      ref.read(socialConnectNotifierProvider.notifier).load(),
                ),
                orElse: () => const Center(
                  child: CircularProgressIndicator(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable row that kicks off the OAuth connect flow for an unconnected
/// platform.
class _AddPlatformTile extends StatelessWidget {
  const _AddPlatformTile({required this.platform, required this.onTap});

  final SocialPlatform platform;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: platform.color.withValues(alpha: 0.15),
              radius: DesignTokens.iconMedium,
              child: Icon(
                platform.icon,
                color: platform.color,
                size: DesignTokens.iconMedium,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(
                platform.displayName,
                style: DesignTokens.oneLinerSemibold,
              ),
            ),
            const Icon(
              Icons.add_circle_outline,
              color: DesignTokens.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}
