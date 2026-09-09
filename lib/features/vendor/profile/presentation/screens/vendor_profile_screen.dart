import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/domain/entities/vendor_profile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_bottom_nav.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorProfileScreen extends ConsumerWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref
        .watch(sessionControllerProvider)
        .maybeWhen(
          authenticated: (id) => id,
          orElse: () => '',
        );
    final profile = ref.watch(myVendorProfileProvider(accountId));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: DesignTokens.sectionInnerTitle),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
              color: DesignTokens.textWhite,
            ),
            onPressed: () => context.push(RouteNames.settings),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        error: (_, __) => const _ProfileUnavailable(),
        data: (value) => value == null
            ? const _ProfileUnavailable()
            : _ProfileBody(profile: value),
      ),
      bottomNavigationBar: VendorBottomNav(
        selectedIndex: 3,
        onTap: (index) {
          if (index == 0) context.go(RouteNames.vendorHome);
          if (index == 1) context.go(RouteNames.vendorOrders);
          if (index == 2) context.go(RouteNames.vendorProducts);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final VendorProfile profile;

  @override
  Widget build(BuildContext context) {
    final initials = profile.businessName.trim().isEmpty
        ? 'SM'
        : profile.businessName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((word) => word[0])
              .join();
    final commissionMin = (profile.commissionRangeMin * 100).toStringAsFixed(0);
    final commissionMax = (profile.commissionRangeMax * 100).toStringAsFixed(0);
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s20),
      children: [
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: DesignTokens.primaryGreen.withValues(alpha: 0.2),
            backgroundImage: profile.logoUrl?.isNotEmpty == true
                ? NetworkImage(profile.logoUrl!)
                : null,
            child: profile.logoUrl?.isNotEmpty == true
                ? null
                : Text(initials.toUpperCase(), style: DesignTokens.titleLarge),
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        Text(
          profile.businessName,
          textAlign: TextAlign.center,
          style: DesignTokens.titleLarge,
        ),
        const SizedBox(height: DesignTokens.s8),
        Center(child: _StatusBadge(status: profile.status)),
        if (profile.description?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: DesignTokens.s24),
          Text(profile.description!.trim(), style: DesignTokens.bodyText),
        ],
        const SizedBox(height: DesignTokens.s24),
        _InfoTile(
          icon: Icons.percent_rounded,
          title: 'Creator commission range',
          value: '$commissionMin%–$commissionMax%',
        ),
        if (profile.websiteUrl?.trim().isNotEmpty ?? false)
          _InfoTile(
            icon: Icons.language_rounded,
            title: 'Website',
            value: profile.websiteUrl!.trim(),
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final int status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      3 => 'Approved',
      2 => 'Under review',
      4 => 'Rejected',
      _ => 'Pending',
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s6,
        ),
        child: Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.primaryGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: DesignTokens.bodyText),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileUnavailable extends StatelessWidget {
  const _ProfileUnavailable();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(DesignTokens.s24),
      child: Text(
        'Your vendor profile is not available yet. Complete vendor onboarding and try again.',
        textAlign: TextAlign.center,
        style: DesignTokens.mediumRegular,
      ),
    ),
  );
}
