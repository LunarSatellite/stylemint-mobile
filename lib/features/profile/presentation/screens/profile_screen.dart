import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/role_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/logout_action.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/widgets/profile_header.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/widgets/profile_menu_section.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/core/device/push_notification_service.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/theme/theme_mode_provider.dart';

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
          loadFailure: (failure) => SmErrorView(
            message: 'Failed to load your profile.',
            onRetry: () =>
                ref.read(profileNotifierProvider.notifier).fetchProfile(),
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

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.summary});

  final ProfileSummary summary;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _pushEnabled = false;
  bool _pushLoaded = false;

  void _populatePush(bool value) {
    if (_pushLoaded) return;
    _pushLoaded = true;
    _pushEnabled = value;
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(settingsNotifierProvider);

    // Populate local state from loaded prefs
    notifState.maybeWhen(
      loadSuccess: (prefs) => _populatePush(prefs.pushEnabled),
      orElse: () {},
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: DesignTokens.s24),
      children: [
        const SizedBox(height: DesignTokens.s16),
        ProfileHeader(
          summary: widget.summary,
          onEdit: () => context.push('${RouteNames.profile}/edit').then((_) {
            // Edit Profile pops itself immediately on save success, before
            // this screen gets any signal to reload — confirmed live: after
            // saving a new display name, this header still showed the old
            // one until the next full app restart. profileNotifierProvider
            // isn't told to refresh on its own on return navigation.
            if (mounted) {
              ref.read(profileNotifierProvider.notifier).fetchProfile();
            }
          }),
          onNotifications: () =>
              context.push(RouteNames.customerRecentActivity),
        ),
        const SizedBox(height: DesignTokens.s20),
        ProfileStatsRow(summary: widget.summary),
        const SizedBox(height: DesignTokens.s20),

        // Selling & Creating — apply for / switch into the Creator & Vendor
        // surfaces. Routes to the apply screen (which self-redirects approved
        // roles to their dashboard) or straight to the dashboard if active.
        const _RoleSwitcherSection(),
        const SizedBox(height: DesignTokens.s16),

        // Account & preferences
        ProfileMenuSection(
          items: [
            ProfileMenuItem(
              icon: Icons.location_on_outlined,
              label: 'Shipping Addresses',
              onTap: () => context.push(RouteNames.shippingAddresses),
            ),
            ProfileMenuItem(
              icon: Icons.notifications_active_outlined,
              label: 'Push Notifications',
              toggleValue: _pushEnabled,
              onToggle: (val) async {
                // Update local state immediately for instant UI feedback
                setState(() => _pushEnabled = val);

                // Read current prefs from state
                final current = ref
                    .read(settingsNotifierProvider)
                    .maybeWhen(
                      loadSuccess: (p) => p,
                      orElse: () => null,
                    );
                if (current == null) return;

                if (val) {
                  final granted =
                      await PushNotificationService.requestPermission();
                  if (!granted) {
                    // Revert if permission denied
                    setState(() => _pushEnabled = false);
                    return;
                  }
                  await PushNotificationService.getToken();
                }

                ref
                    .read(settingsNotifierProvider.notifier)
                    .savePrefs(current.copyWith(pushEnabled: val));
              },
            ),
            ProfileMenuItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'My Wallet',
              onTap: () => context.push(RouteNames.wallet),
            ),
            ProfileMenuItem(
              icon: Icons.credit_card_outlined,
              label: 'Payment Methods',
              onTap: () => context.push(RouteNames.paymentMethods),
            ),
            ProfileMenuItem(
              icon: Icons.palette_outlined,
              label: 'Appearance',
              onTap: () => _showAppearanceSheet(context),
            ),
            ProfileMenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notification Settings',
              onTap: () => context.push(RouteNames.settingsNotifications),
            ),
            ProfileMenuItem(
              icon: Icons.language_outlined,
              label: 'Language',
              trailingText: widget.summary.language,
              onTap: () => context.push('${RouteNames.settings}/language'),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),

        // Community & social commerce
        ProfileMenuSection(
          items: [
            ProfileMenuItem(
              icon: Icons.groups_outlined,
              label: 'Community & Social',
              onTap: () => context.push(RouteNames.community),
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
                // In-app review needs a real Play Store/App Store listing,
                // which this dev build doesn't have — was previously a
                // silent no-op with no feedback at all when tapped, unlike
                // every other not-yet-implemented action in this app (Live
                // Chat, report saving, etc.), which all show a message.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rating is coming soon.'),
                  ),
                );
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
              label: 'About StyleMint',
              onTap: () => context.push(RouteNames.settingsAbout),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),

        // Log Out
        ProfileMenuSection(
          items: [
            ProfileMenuItem(
              icon: Icons.logout_rounded,
              label: 'Log Out',
              onTap: () => confirmAndLogout(context, ref),
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

  void _showAppearanceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (_, ref, _) {
          final selected = ref.watch(themeModeProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appearance', style: DesignTokens.h3),
                  const SizedBox(height: 8),
                  Text(
                    // Style Mint's screens are built with fixed dark colors
                    // throughout (not Theme.of(context)-driven), so Light
                    // and "use device setting" have no visible effect today
                    // even though the underlying MaterialApp theme switch
                    // exists — only offer the mode that actually changes
                    // anything, rather than a picker that silently does
                    // nothing for two of its three options.
                    'Style Mint currently supports Dark mode only.',
                    style: DesignTokens.body.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: selected,
                    activeColor: DesignTokens.primaryGreen,
                    title: Text(
                      _themeModeLabel(ThemeMode.dark),
                      style: DesignTokens.body.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      unawaited(
                        ref.read(themeModeProvider.notifier).setMode(value),
                      );
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Use device setting',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

/// Creator & Vendor entry points + role switcher.
///
/// Loads the account's role profiles so each row reflects the real state:
/// an **active** role links straight to its dashboard; otherwise the row links
/// to the application/review flow. Role loading is best-effort — if it fails
/// the rows default to the apply route, and the apply screen self-redirects an
/// already-approved role to its dashboard, so navigation stays correct either
/// way.
class _RoleSwitcherSection extends ConsumerStatefulWidget {
  const _RoleSwitcherSection();

  @override
  ConsumerState<_RoleSwitcherSection> createState() =>
      _RoleSwitcherSectionState();
}

class _RoleSwitcherSectionState extends ConsumerState<_RoleSwitcherSection> {
  // Role ids per the identity model: 2 = Creator, 3 = Vendor.
  static const _creatorRole = 2;
  static const _vendorRole = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountId = ref
          .read(sessionControllerProvider)
          .maybeWhen(
            authenticated: (id) => id,
            orElse: () => null,
          );
      if (accountId != null && accountId.isNotEmpty) {
        ref.read(roleNotifierProvider.notifier).loadRoles(accountId);
      }
    });
  }

  bool _isActive(List<RoleProfileDto> roles, int role) =>
      roles.any((r) => r.role == role && r.isActivated);

  bool _navigating = false;

  void _pushOnce(String route) {
    if (_navigating) return;
    _navigating = true;
    context.push(route).whenComplete(() {
      if (mounted) _navigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The shell keeps this screen mounted across tab switches, so it never
    // naturally re-runs initState — this is what actually catches a vendor/
    // creator approval granted elsewhere in the session.
    ref.listen<int>(profileTabVisitedProvider, (_, _) {
      final accountId = ref
          .read(sessionControllerProvider)
          .maybeWhen(authenticated: (id) => id, orElse: () => null);
      if (accountId != null && accountId.isNotEmpty) {
        ref.read(roleNotifierProvider.notifier).loadRoles(accountId);
      }
    });

    final roles = ref
        .watch(roleNotifierProvider)
        .maybeWhen(
          loadSuccess: (r) => r,
          orElse: () => const <RoleProfileDto>[],
        );
    final creatorActive = _isActive(roles, _creatorRole);
    final vendorActive = _isActive(roles, _vendorRole);

    return ProfileMenuSection(
      items: [
        ProfileMenuItem(
          icon: Icons.video_camera_back_outlined,
          label: creatorActive ? 'Creator Studio' : 'Become a Creator',
          // See the Vendor tile below for why this re-checks fresh instead
          // of trusting `creatorActive` from the last build.
          onTap: () async {
            if (creatorActive) {
              _pushOnce(RouteNames.creatorHome);
              return;
            }
            final accountId = ref
                .read(sessionControllerProvider)
                .maybeWhen(authenticated: (id) => id, orElse: () => null);
            if (accountId != null && accountId.isNotEmpty) {
              await ref
                  .read(roleNotifierProvider.notifier)
                  .loadRoles(accountId);
            }
            final freshRoles = ref
                .read(roleNotifierProvider)
                .maybeWhen(
                  loadSuccess: (r) => r,
                  orElse: () => const <RoleProfileDto>[],
                );
            if (_isActive(freshRoles, _creatorRole)) {
              _pushOnce(RouteNames.creatorHome);
              return;
            }
            // Mirror user_type_selection_screen: when the role isn't active,
            // resolve the existing application status so a submitted/under-
            // review account lands on the right status screen instead of
            // re-entering the apply form.
            await ref.read(creatorApplyNotifierProvider.notifier).checkStatus();
            if (!mounted) return;
            final statusState = ref.read(creatorApplyNotifierProvider);
            final route = statusState.maybeWhen(
              loadSuccess: (application) => switch (application.status) {
                CreatorApplicationStatus.approved =>
                  RouteNames.creatorApplyApproved,
                CreatorApplicationStatus.rejected =>
                  RouteNames.creatorApplyRejected,
                CreatorApplicationStatus.pending ||
                CreatorApplicationStatus.underReview =>
                  RouteNames.creatorApplyUnderReview,
              },
              orElse: () => RouteNames.creatorApply,
            );
            _pushOnce(route);
          },
        ),
        ProfileMenuItem(
          icon: Icons.storefront_outlined,
          label: vendorActive ? 'Vendor Dashboard' : 'Sell on Style Mint',
          // Re-check fresh rather than trusting `vendorActive` from whatever
          // build last ran — a vendor approval can land moments before this
          // tap (e.g. right after switching to this tab), and the cached
          // role list can still read stale-false at the exact instant of
          // tap, incorrectly routing back through the apply/approved gate
          // instead of straight to the dashboard.
          onTap: () async {
            if (vendorActive) {
              _pushOnce(RouteNames.vendorHome);
              return;
            }
            final accountId = ref
                .read(sessionControllerProvider)
                .maybeWhen(authenticated: (id) => id, orElse: () => null);
            if (accountId != null && accountId.isNotEmpty) {
              await ref
                  .read(roleNotifierProvider.notifier)
                  .loadRoles(accountId);
            }
            final freshRoles = ref
                .read(roleNotifierProvider)
                .maybeWhen(
                  loadSuccess: (r) => r,
                  orElse: () => const <RoleProfileDto>[],
                );
            if (_isActive(freshRoles, _vendorRole)) {
              _pushOnce(RouteNames.vendorHome);
              return;
            }
            // Mirror user_type_selection_screen: when the role isn't active,
            // resolve the existing application status so a submitted/under-
            // review account lands on the right status screen instead of
            // re-entering the vendor apply form.
            if (accountId != null && accountId.isNotEmpty) {
              await ref
                  .read(vendorApplyNotifierProvider.notifier)
                  .checkStatus(accountId);
              if (!mounted) return;
              final vendorState = ref.read(vendorApplyNotifierProvider);
              final route = vendorState.maybeWhen(
                loadSuccess: (application) => switch (application.status) {
                  // Already approved — go straight to the dashboard. The
                  // "Application Approved" screen is a one-time congrats
                  // shown when the status first flips (from the under-review
                  // polling loop), not a landing page for every repeat visit.
                  VendorApplicationStatus.approved => RouteNames.vendorHome,
                  VendorApplicationStatus.rejected =>
                    RouteNames.vendorApplyRejected,
                  VendorApplicationStatus.pending ||
                  VendorApplicationStatus.underReview =>
                    RouteNames.vendorApplyUnderReview,
                  VendorApplicationStatus.draft => RouteNames.vendorApply,
                },
                orElse: () => RouteNames.vendorApply,
              );
              _pushOnce(route);
              return;
            }
            _pushOnce(RouteNames.vendorApply);
          },
        ),
      ],
    );
  }
}
