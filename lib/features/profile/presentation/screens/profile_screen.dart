import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/widgets/profile_header.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/widgets/profile_menu_section.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final isAuthed = session.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );

    if (!isAuthed) {
      return _UnauthenticatedView();
    }

    final state = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: state.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (summary) => _ProfileBody(summary: summary),
          loadFailure:
              (failure) => SmErrorView(
                message: 'Failed to load your profile.',
                onRetry:
                    () =>
                        ref
                            .read(profileNotifierProvider.notifier)
                            .fetchProfile(),
              ),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _UnauthenticatedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: DesignTokens.primaryGreen,
                    size: 36,
                  ),
                ),
                const SizedBox(height: DesignTokens.s24),
                Text(
                  'Your Profile',
                  style: DesignTokens.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.s12),
                Text(
                  'Sign in to manage your profile, track orders, and access your saved items.',
                  textAlign: TextAlign.center,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s24),
                SizedBox(
                  width: double.infinity,
                  height: DesignTokens.buttonHeight,
                  child: ElevatedButton(
                    style: DesignTokens.primaryButtonStyle(),
                    onPressed: () => context.push(RouteNames.signInMethod),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.summary});

  final ProfileSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: DesignTokens.s24),
      children: [
        const SizedBox(height: DesignTokens.s16),
        ProfileHeader(
          summary: summary,
          onEdit: () => context.push('${RouteNames.profile}/edit'),
        ),
        const SizedBox(height: DesignTokens.s20),
        ProfileStatsRow(summary: summary),
        const SizedBox(height: DesignTokens.s20),

        // Account & preferences
        ProfileMenuSection(
          items: [
            ProfileMenuItem(
              icon: Icons.location_on_outlined,
              label: 'Shipping Addresses',
              onTap: () {
                /* TODO(profile): shipping addresses */
              },
            ),
            ProfileMenuItem(
              icon: Icons.credit_card_outlined,
              label: 'Payment Methods',
              onTap: () {
                /* TODO(profile): payment methods */
              },
            ),
            ProfileMenuItem(
              icon: Icons.palette_outlined,
              label: 'Appearance',
              onTap: () {
                /* TODO(profile): appearance */
              },
            ),
            ProfileMenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notification Settings',
              onTap: () => context.push(RouteNames.settings),
            ),
            ProfileMenuItem(
              icon: Icons.language_outlined,
              label: 'Language',
              trailingText: summary.language,
              onTap: () => context.push('${RouteNames.settings}/language'),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),

        // Support
        ProfileMenuSection(
          items: [
            ProfileMenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Help Center',
              onTap: () => context.push(RouteNames.support),
            ),
            ProfileMenuItem(
              icon: Icons.headset_mic_outlined,
              label: 'Contact Support',
              onTap: () => context.push('${RouteNames.support}/contact'),
            ),
            ProfileMenuItem(
              icon: Icons.star_outline_rounded,
              label: 'Rate the App',
              onTap: () {
                /* TODO(profile): in-app review */
              },
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),

        // Legal
        ProfileMenuSection(
          items: [
            ProfileMenuItem(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              onTap: () => context.push('${RouteNames.settings}/terms'),
            ),
            ProfileMenuItem(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              onTap: () => context.push('${RouteNames.settings}/privacy'),
            ),
            ProfileMenuItem(
              icon: Icons.info_outline_rounded,
              label: 'About ReelCommerce',
              onTap: () {
                /* TODO(profile): about */
              },
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),

        // Logout & Delete
        ProfileMenuSection(
          items: [
            ProfileMenuItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              isDestructive: true,
              onTap: () => context.push('${RouteNames.settings}/logout'),
            ),
            ProfileMenuItem(
              icon: Icons.delete_forever_outlined,
              label: 'Delete Account',
              isDestructive: true,
              onTap: () => context.push('${RouteNames.settings}/delete-account'),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),
        const Center(
          child: Text('Version 1.0.0', style: DesignTokens.smallRegular),
        ),
      ],
    );
  }
}
