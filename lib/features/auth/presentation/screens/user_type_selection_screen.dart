import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/role_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/identity_roles.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

/// Stores the role the user tapped before signing in so it can be
/// automatically applied once authentication completes.
final pendingRoleProvider = StateProvider<int?>((ref) => null);

/// Delivery partner — `RoleType.Courier` in Identity.
///
/// A real role now, not the sentinel this used to be. Identity gates its
/// activation on the courier profile having cleared checks (asked of the
/// Delivery module through `ICourierStandingLookup`), exactly as Creator and
/// Vendor gate on an approved profile application. So the role is safe to
/// request and activate, and `_isRoleActivated` can answer for it — which is
/// what lets this screen show the activated badge and lets an active courier
/// be taken to their dashboard instead of the shopping feed.
///
/// The courier profile remains the single source of truth for whether someone
/// can carry a parcel; the role only mirrors it, and only ever by asking.
const int deliveryPartnerOption = IdentityRoles.courier;

/// True for the options that cannot be completed as a guest, so tapping one
/// sends the user to sign in and back here afterwards.
///
/// Every post-login screen has to agree on this set. They each used to inline
/// `pendingRole == 2 || pendingRole == 3`, so adding an option meant finding
/// all of them — and the one that was missed dropped the choice silently.
bool pendingRoleNeedsResume(int? option) =>
    option == 2 || option == 3 || option == deliveryPartnerOption;

/// Select User Type — pixel-matched to Figma frame `9365:7986`.
///
/// Brand logo → "Welcome to StyleMint!" (24px) + subtitle → four tappable
/// rows (green numbered badge + title/description + chevron, divided by thin
/// lines) → "Already have an account? Sign In" footer.
///
/// The fourth row, delivery partner, is not a Figma role: it routes to the
/// courier gate rather than through role request/activate. See
/// [deliveryPartnerOption].
class UserTypeSelectionScreen extends ConsumerStatefulWidget {
  /// Whether this sign-in just provisioned a new account (smart-start). Passed
  /// as the `?new=` query param rather than a typed `extra` object, because the
  /// post-login session refresh rebuilds the router stack and does not preserve
  /// `extra` reliably. `accountId` comes from the now-authenticated session.
  final bool isNewAccount;

  /// When true (the post-login default), an account that already has an
  /// activated role has finished onboarding, so we skip straight to home
  /// instead of re-asking. Set false for a "manage / add a role" entry,
  /// where the screen should always be shown.
  final bool skipIfOnboarded;

  const UserTypeSelectionScreen({
    super.key,
    this.isNewAccount = false,
    this.skipIfOnboarded = true,
  });

  @override
  ConsumerState<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState
    extends ConsumerState<UserTypeSelectionScreen> {
  List<RoleProfileDto> _existingRoles = [];
  bool _loadingRole = false;

  /// While true we hold on a loader and have not yet shown the role list —
  /// this is the window in which an already-onboarded user is auto-skipped to
  /// home, so they never see a flash of the selection screen.
  late bool _deciding;

  /// Account id from the active (authenticated) session.
  String? get _accountId => ref
      .read(sessionControllerProvider)
      .maybeWhen(
        authenticated: (id) => id,
        orElse: () => null,
      );

  @override
  void initState() {
    super.initState();
    // Only block the UI behind a loader while we may still auto-skip.
    _deciding = widget.skipIfOnboarded;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountId = _accountId;
      if (accountId == null) {
        if (mounted) setState(() => _deciding = false);
        return;
      }

      // Resume a pending delivery-partner choice here, not from the roles
      // listener below.
      //
      // That listener fires on a CHANGE to roleNotifierProvider. The roles are
      // frequently already loaded and identical by the time this screen is
      // reached — the profile screen loads them, and it reloads them on every
      // visit to that tab — so `loadRoles` re-emits an equal state, nothing
      // notifies, and the resume never ran: signing in as a delivery partner
      // dropped the user back on this picker.
      //
      // Courier is the one option that needs no role data to act on. The gate
      // reads the courier profile and decides between apply, KYC, review and
      // the dashboard, so there is nothing to wait for.
      if (ref.read(pendingRoleProvider) == deliveryPartnerOption) {
        ref.read(pendingRoleProvider.notifier).state = null;
        _toCourier();
        return;
      }

      unawaited(_loadAndResume(accountId));
    });
  }

  /// Loads the roles, then resumes a pending Creator/Vendor choice if the
  /// listener did not.
  ///
  /// Belt and braces for the same race as the courier case above: the
  /// listener only sees a change, and an already-loaded equal state produces
  /// none. Creator and Vendor genuinely need the role list to choose between
  /// a dashboard and an application, so unlike courier they wait for it —
  /// they just no longer depend on being *notified*.
  ///
  /// Idempotent with the listener: whichever gets there first clears
  /// [pendingRoleProvider], and the other then finds nothing to do.
  Future<void> _loadAndResume(String accountId) async {
    await ref.read(roleNotifierProvider.notifier).loadRoles(accountId);
    if (!mounted) return;

    final pending = ref.read(pendingRoleProvider);
    if (pending == null) return;
    ref.read(pendingRoleProvider.notifier).state = null;

    setState(() {
      _existingRoles = ref
          .read(roleNotifierProvider)
          .maybeWhen(
            loadSuccess: (roles) => roles,
            orElse: () => _existingRoles,
          );
      _deciding = false;
    });
    await _selectRole(pending);
  }

  Future<void> _selectRole(int roleInt) async {
    final accountId = _accountId;
    if (accountId == null) {
      // Pre-auth: remember the chosen role so it is auto-applied after login.
      ref.read(pendingRoleProvider.notifier).state = roleInt;
      // Customer (1) sees the onboarding carousel before sign-in.
      // Creator (2) and Vendor (3) must sign in first — the application
      // endpoints require an authenticated account (`requiresToken: true`),
      // so sending a guest straight into the multi-step form used to let
      // them fill it out in full and only discover it can't be submitted
      // when the final Submit silently 401'd. Sign in now, then the
      // pendingRoleProvider listener below auto-resumes into the
      // application once the account is authenticated.
      if (roleInt == 1) {
        context.go(RouteNames.onboarding);
      } else {
        context.go(RouteNames.signInMethod);
      }
      return;
    }

    // Delivery partner has no Identity role to request or activate — the
    // courier gate reads the courier profile and decides between apply, KYC,
    // "in review" and the work list. Checked BEFORE the activation and
    // Creator/Vendor branches below, because falling through them would reach
    // the Customer path and post role 4 to an enum that has no such member.
    if (roleInt == deliveryPartnerOption) {
      await _navigateForRole(roleInt);
      return;
    }

    // Already an active role → straight to that surface, no application needed.
    if (_isRoleActivated(roleInt)) {
      await _navigateForRole(roleInt);
      return;
    }

    // Creator (2) / Vendor (3) must go through the application + review flow
    // before the role is activated — the apply screen owns request/activate.
    if (roleInt == 2 || roleInt == 3) {
      await _navigateForRole(roleInt);
      return;
    }

    // Customer (1) needs no review — request + activate inline, then onboard.
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

    if (existing.id.isEmpty) {
      await notifier.requestRole(accountId, roleInt);
    }

    await notifier.activateRole(accountId, roleInt);

    if (!mounted) return;
    setState(() => _loadingRole = false);
    await _navigateForRole(roleInt);
  }

  /// Opens the delivery surface with the shopping home underneath it.
  ///
  /// `/courier` is a top-level route, so reaching it with `go` alone makes it
  /// the only page on the stack and its AppBar renders no back button —
  /// someone who taps this before applying would be stranded on the apply
  /// form with no way back to shopping.
  ///
  /// The push waits a frame: `go` re-parses the route asynchronously, so
  /// pushing in the same synchronous block can append onto the stack being
  /// replaced. The router is captured first because `go` can dispose this
  /// element, taking its context with it.
  void _toCourier() {
    final router = GoRouter.of(context);
    router.go(RouteNames.home);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => router.push(RouteNames.courier),
    );
  }

  Future<void> _navigateForRole(int role) async {
    switch (role) {
      // Braced so `router` is scoped to this case rather than the whole
      // switch body.
      case deliveryPartnerOption:
        _toCourier();
      case 2:
        if (_isRoleActivated(2)) {
          context.go(RouteNames.creatorHome);
          return;
        }
        // Creator onboarding is instant (POST /v1/creator/activate), so
        // there is no application or review status to check first.
        context.go(RouteNames.creatorApply);
      case 3:
        if (_isRoleActivated(3)) {
          context.go(RouteNames.vendorHome);
          return;
        }
        setState(() => _loadingRole = true);
        final vendorAccountId = ref
            .read(sessionControllerProvider)
            .maybeWhen(
              authenticated: (id) => id,
              orElse: () => null,
            );
        if (vendorAccountId != null) {
          await ref
              .read(vendorApplyNotifierProvider.notifier)
              .checkStatus(vendorAccountId);
        }
        if (!mounted) return;
        setState(() => _loadingRole = false);
        final vendorStatusState = ref.read(vendorApplyNotifierProvider);
        String vendorRoute = RouteNames.vendorApply;
        String? rejectionReason;
        vendorStatusState.maybeWhen(
          loadSuccess: (application) {
            vendorRoute = switch (application.status) {
              // Already approved — go straight to the dashboard. The
              // "Application Approved" screen is a one-time congrats shown
              // when the status first flips, not a landing page for every
              // repeat visit.
              VendorApplicationStatus.approved => RouteNames.vendorHome,
              VendorApplicationStatus.rejected =>
                RouteNames.vendorApplyRejected,
              VendorApplicationStatus.pending ||
              VendorApplicationStatus.underReview =>
                RouteNames.vendorApplyUnderReview,
              VendorApplicationStatus.draft => RouteNames.vendorApply,
            };
            rejectionReason = application.rejectionReason;
          },
          orElse: () {},
        );
        context.go(vendorRoute, extra: rejectionReason);
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
        loadSuccess: (roles) {
          if (!mounted) return;

          // If the user pre-selected a role before signing in, apply it now
          // automatically and skip showing the selection screen again.
          final pendingRole = ref.read(pendingRoleProvider);
          if (pendingRole != null) {
            ref.read(pendingRoleProvider.notifier).state = null;
            setState(() {
              _existingRoles = roles;
              _deciding = false;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _selectRole(pendingRole);
            });
            return;
          }

          // One-time setup: an account that already has an activated role has
          // onboarded. Skip straight to home — but ONLY on the initial load
          // (`_deciding`), never after the user activates a role in this very
          // session (that path navigates to pick-interests itself).
          //
          // `isNewAccount` from the auth bundle is the authoritative "fresh
          // signup" signal: a just-provisioned account is never skipped, even
          // if a role somehow already exists. For returning users we still
          // gate on having an activated role so abandoned-onboarding accounts
          // are sent through the picker rather than dropped at home.
          if (_deciding &&
              widget.skipIfOnboarded &&
              !widget.isNewAccount &&
              roles.any((r) => r.isActivated)) {
            // A courier and nothing else goes to the delivery surface, not
            // the shopping feed. Someone whose only activated role is
            // Courier opened the app to work; sending them to reels means
            // navigating to Profile and down a menu on every single launch.
            //
            // "And nothing else" matters: a courier who also shops is a
            // shopper first by default, because that is the app they opened
            // and the delivery surface is one tap away in the profile menu.
            // Deciding the other way would hijack the app for anyone who
            // ever signed up to deliver.
            final activated = roles
                .where((r) => r.isActivated)
                .map((r) => r.role)
                .toSet();
            if (activated.length == 1 &&
                activated.first == deliveryPartnerOption) {
              _toCourier();
              return;
            }
            context.go(RouteNames.home);
            return;
          }
          setState(() {
            _existingRoles = roles;
            _deciding = false;
          });
        },
        loadFailure: (_) {
          // Couldn't read roles — fall back to showing the selection.
          if (mounted) setState(() => _deciding = false);
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: (_deciding || _loadingRole)
            ? const SmPageLoader()
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
                                    Image.asset(
                                      'assets/branding/stylemint-mark.png',
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: DesignTokens.s4),
                                    // Text(
                                    //   'STYLE MINT',
                                    //   style: DesignTokens.mediumSemibold
                                    //       .copyWith(
                                    //         color: DesignTokens.primaryGreen,
                                    //         letterSpacing: 2,
                                    //       ),
                                    // ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: DesignTokens.s24),
                              Column(
                                children: [
                                  Text(
                                    'Welcome to StyleMint!',
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
                          const _RoleDivider(),
                          _RoleRow(
                            number: 4,
                            title: 'I am a delivery partner',
                            description:
                                'Deliver parcels on your own schedule, Get paid per drop, Your phone signs for every handover',
                            // Answerable now that Courier is a real role —
                            // the badge reads off the same role list as the
                            // other three instead of being hardcoded false.
                            isActivated: _isRoleActivated(
                              deliveryPartnerOption,
                            ),
                            onTap: () => _selectRole(deliveryPartnerOption),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Browsing has never needed an account — /home and the reels
                  // feed are both public routes, and the feed endpoint serves
                  // trending to anonymous callers. There was just no way in:
                  // a cold start landed here and every path off it asked you
                  // to pick a role and sign in.
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.s8),
                    child: GestureDetector(
                      key: const Key('browse_as_guest'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.go(RouteNames.home),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: DesignTokens.s12,
                          horizontal: DesignTokens.s16,
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Just looking? ',
                                style: DesignTokens.mediumRegular.copyWith(
                                  color: DesignTokens.textLight,
                                ),
                              ),
                              TextSpan(
                                text: 'Watch reels without an account',
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: DesignTokens.s32,
                      top: DesignTokens.s4,
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
                  ? const Icon(
                      Icons.check,
                      color: DesignTokens.textWhite,
                      size: 20,
                    )
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
