import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor profile / store header card with a one-tap Partnership Flow menu.
///
/// Rendered at the top of the vendor dashboard body. Composes:
///   1. Vendor avatar + display name + chevron (tap to go to settings).
///   2. A horizontally scrollable row of partnership-flow shortcuts
///      (Send Request, Create Campaign, Briefs, Requests) so the most
///      common vendor actions in this flow are one tap from the home screen.
///
/// Account data is sourced from [accountNotifierProvider]; if it has not
/// been fetched yet we kick off a load here so the section always shows a
/// real name instead of a permanent skeleton.
class VendorProfileSection extends ConsumerStatefulWidget {
  const VendorProfileSection({super.key});

  @override
  ConsumerState<VendorProfileSection> createState() =>
      _VendorProfileSectionState();
}

class _VendorProfileSectionState extends ConsumerState<VendorProfileSection> {
  String? _lastLoadedForAccountId;

  @override
  void initState() {
    super.initState();
    // Defer the first load until after the first frame so we don't mutate
    // provider state during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  void _ensureLoaded() {
    if (!mounted) return;
    final session = ref.read(sessionControllerProvider);
    final accountId = session.maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );

    // Logged out (or session not yet known). Clear any stale cached
    // account so the previous user's name doesn't linger, and bail.
    if (accountId == null) {
      if (_lastLoadedForAccountId != null) {
        _lastLoadedForAccountId = null;
        ref.read(accountNotifierProvider.notifier).reset();
      }
      return;
    }

    // Stale cache from a previous user — wipe before reloading so the
    // build never paints the previous user's name during the gap.
    final cached = ref.read(accountNotifierProvider).loadedAccount;
    if (cached != null && cached.id != accountId) {
      ref.read(accountNotifierProvider.notifier).reset();
    }

    final fresh = ref.read(accountNotifierProvider);
    final alreadyLoaded = fresh.loadedAccount?.id == accountId;
    if (!alreadyLoaded && _lastLoadedForAccountId != accountId) {
      _lastLoadedForAccountId = accountId;
      ref.read(accountNotifierProvider.notifier).loadAccount(accountId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-check whenever EITHER the session (login/logout, account switch)
    // OR the account state (initial load, refresh) changes. Without the
    // session listener, switching users keeps the previous user's name
    // visible because the global accountNotifierProvider still holds it.
    ref.listen<AuthSessionState>(
      sessionControllerProvider,
      (_, __) => _ensureLoaded(),
    );
    ref.listen(accountNotifierProvider, (_, __) => _ensureLoaded());

    final accountState = ref.watch(accountNotifierProvider);
    final displayName = accountState.loadedAccount?.displayName;
    final avatarUrl = accountState.loadedAccount?.avatarUrl;

    final name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : 'Vendor';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s16,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push(RouteNames.settings),
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
              child: Row(
                children: [
                  _VendorAvatar(avatarUrl: avatarUrl),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: DesignTokens.sectionInnerTitle.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vendor Dashboard',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: DesignTokens.iconLight,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          const _PartnershipFlowLabel(text: 'Partnership Flow'),
          const SizedBox(height: DesignTokens.s8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: [
                _PartnershipChip(
                  icon: Icons.send_outlined,
                  label: 'Send Request',
                  onTap: () =>
                      context.push(RouteNames.vendorSendPartnershipRequest),
                ),
                _PartnershipChip(
                  icon: Icons.add_box_outlined,
                  label: 'Create Campaign',
                  onTap: () => context.push(RouteNames.vendorCreateCampaign),
                ),
                _PartnershipChip(
                  icon: Icons.campaign_outlined,
                  label: 'Briefs',
                  onTap: () => context.push(RouteNames.vendorCampaignBriefs),
                ),
                _PartnershipChip(
                  icon: Icons.inbox_outlined,
                  label: 'Requests',
                  onTap: () => context.push(
                    RouteNames.vendorCreatorPartnershipRequests,
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

class _VendorAvatar extends StatelessWidget {
  const _VendorAvatar({required this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        shape: BoxShape.circle,
        border: Border.all(color: DesignTokens.borderDefault, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Icon(
                Icons.storefront_outlined,
                size: 22,
                color: DesignTokens.iconLight,
              ),
              errorWidget: (_, __, ___) => const Icon(
                Icons.storefront_outlined,
                size: 22,
                color: DesignTokens.iconLight,
              ),
            )
          : const Icon(
              Icons.storefront_outlined,
              size: 22,
              color: DesignTokens.iconLight,
            ),
    );
  }
}

class _PartnershipFlowLabel extends StatelessWidget {
  const _PartnershipFlowLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: DesignTokens.smallRegular.copyWith(
        color: DesignTokens.textMuted,
        fontSize: 11,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PartnershipChip extends StatelessWidget {
  const _PartnershipChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: DesignTokens.s8),
      child: Material(
        color: DesignTokens.bgAppBodyLight,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: DesignTokens.borderDefault, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s12,
              vertical: DesignTokens.s8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: DesignTokens.iconLight),
                const SizedBox(width: DesignTokens.s8),
                Text(
                  label,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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