import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor "More" bottom sheet.
/// Pixel-matched to Brand `More Menu.pdf`: rounded-top (28px) sheet on
/// `#27272A`, action rows (24px icon / 14px title / 16px chevron) split by
/// `#3F3F46` dividers. Spec lists Creator Partnerships / Payouts & Earnings /
/// Analytics; Settings / Support / Log Out are added as standard More-menu items.
Future<void> showVendorMoreMenu(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    // The menu has grown to 10 items since the "spec 3 items" comment above
    // was written â€" without this, the sheet's default height cap clipped the
    // bottom entries (Help & Support, Log Out) behind the system nav bar
    // with no way to scroll to them.
    isScrollControlled: true,
    backgroundColor: DesignTokens.bgAppBodyLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => _VendorMoreMenu(parentContext: context, ref: ref),
  );
}

class _VendorMoreMenu extends StatelessWidget {
  const _VendorMoreMenu({required this.parentContext, required this.ref});

  final BuildContext parentContext;
  final WidgetRef ref;

  void _go(BuildContext sheetCtx, String route) {
    Navigator.of(sheetCtx).pop();
    parentContext.push(route);
  }

  Future<void> _logout(BuildContext sheetCtx) async {
    Navigator.of(sheetCtx).pop();
    await ref.read(sessionControllerProvider.notifier).logout();
    if (parentContext.mounted) parentContext.go(RouteNames.signInMethod);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: DesignTokens.s8),
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              _MoreItem(
                icon: Icons.groups_outlined,
                title: 'Creator Partnerships',
                onTap: () => _go(context, RouteNames.vendorPartnerships),
              ),
              const _MoreDivider(),
              // Brand Studio (brand intelligence + Campaign Briefs) had no
              // navigation entry point anywhere in the vendor UI despite being
              // fully built and wired to real backend endpoints
              // (GET/POST /v1/vendor/briefs, VendorBriefsController) â€" this
              // was the actual reason "create a campaign" looked unreachable.
              _MoreItem(
                icon: Icons.auto_awesome_outlined,
                title: 'Brand Studio',
                onTap: () => _go(context, RouteNames.vendorBrandStudio),
              ),
              const _MoreDivider(),
              _MoreItem(
                icon: Icons.payments_outlined,
                title: 'Payouts & Earnings',
                onTap: () => _go(context, RouteNames.vendorEarnings),
              ),
              const _MoreDivider(),
              _MoreItem(
                icon: Icons.bar_chart_rounded,
                title: 'Analytics',
                onTap: () => _go(context, RouteNames.vendorAnalytics),
              ),
              const _MoreDivider(),
              _MoreItem(
                icon: Icons.question_answer_outlined,
                title: 'Customer Inquiries',
                onTap: () => _go(context, RouteNames.vendorInquiries),
              ),
              const _MoreDivider(),
              _MoreItem(
                icon: Icons.insights_outlined,
                title: 'Creator Performance',
                onTap: () => _go(context, RouteNames.vendorCreatorPerformance),
              ),
              const _MoreDivider(),
              // Same "fully built, zero navigation entry points" gap as Brand
              // Studio above â€" AI creator-match recommendations, never linked
              // from anywhere in the vendor UI.
              _MoreItem(
                icon: Icons.recommend_outlined,
                title: 'Recommended Creators',
                onTap: () => _go(context, RouteNames.vendorMatchmaking),
              ),
              const _MoreDivider(),
              _MoreItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => _go(context, RouteNames.settings),
              ),
              const _MoreDivider(),
              _MoreItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                // A dedicated VendorContactSupportScreen exists and is
                // registered but had zero references anywhere â€" this was
                // sending vendors to the generic customer HelpCenterScreen
                // instead.
                onTap: () => _go(context, RouteNames.vendorSupportContact),
              ),
              const _MoreDivider(),
              _MoreItem(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                destructive: true,
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _MoreItem extends StatelessWidget {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? DesignTokens.colorError
        : DesignTokens.iconLight;
    final titleColor = destructive
        ? DesignTokens.colorError
        : DesignTokens.textWhite;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(
                title,
                style: DesignTokens.mediumRegular.copyWith(color: titleColor),
              ),
            ),
            if (!destructive)
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: DesignTokens.iconLight,
              ),
          ],
        ),
      ),
    );
  }
}

class _MoreDivider extends StatelessWidget {
  const _MoreDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: DesignTokens.borderDefault,
    );
  }
}
