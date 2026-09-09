import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_list_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/brand.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_info_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Maps a real [BrandListItemDto] into the seed shape [BrandInfoScreen]
/// expects. Only carries fields the catalog list endpoint actually
/// returns; description / rating / success rate / category are fetched
/// on mount via brandDetailProvider + brandTrustProvider.
BrandInfoData _toBrandInfoData(Brand brand) => BrandInfoData(
  name: brand.businessName,
  logoUrl: brand.logoUrl,
  commissionMinPercent: brand.commissionRangeMinPercent,
  commissionMaxPercent: brand.commissionRangeMaxPercent,
  vendorProfileId: brand.vendorAccountId,
);

/// The Brands filter sheet only uses fields already returned by the public
/// approved-brand catalog. The API is newest-first, so the [newest] sort
/// deliberately preserves server order.
enum _BrandCatalogSort { newest, highestCommission, lowestCommission, name }

class _BrandCatalogFilter {
  const _BrandCatalogFilter({this.minimum, this.maximum, this.sort});

  final double? minimum;
  final double? maximum;
  final _BrandCatalogSort? sort;

  List<Brand> apply(Iterable<Brand> source) {
    final filtered = source
        .where((brand) {
          // A commission range matches when it overlaps the selected range.
          final aboveMinimum =
              minimum == null || brand.commissionRangeMaxPercent >= minimum!;
          final belowMaximum =
              maximum == null || brand.commissionRangeMinPercent <= maximum!;
          return aboveMinimum && belowMaximum;
        })
        .toList(growable: false);

    switch (sort) {
      case _BrandCatalogSort.highestCommission:
        filtered.sort((a, b) {
          final byMaximum = b.commissionRangeMaxPercent.compareTo(
            a.commissionRangeMaxPercent,
          );
          return byMaximum != 0
              ? byMaximum
              : b.commissionRangeMinPercent.compareTo(
                  a.commissionRangeMinPercent,
                );
        });
      case _BrandCatalogSort.lowestCommission:
        filtered.sort((a, b) {
          final byMinimum = a.commissionRangeMinPercent.compareTo(
            b.commissionRangeMinPercent,
          );
          return byMinimum != 0
              ? byMinimum
              : a.commissionRangeMaxPercent.compareTo(
                  b.commissionRangeMaxPercent,
                );
        });
      case _BrandCatalogSort.name:
        filtered.sort(
          (a, b) => a.businessName.toLowerCase().compareTo(
            b.businessName.toLowerCase(),
          ),
        );
      case _BrandCatalogSort.newest:
      case null:
        break;
    }

    return filtered;
  }
}

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  _BrandCatalogFilter _filter = const _BrandCatalogFilter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      bottomNavigationBar: const _BrandsBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: DesignTokens.s20),
              const Text(
                'Brand Partnerships',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              _buildStatCards(),
              const SizedBox(height: DesignTokens.s24),
              _SectionTitle('Recommended Brands for You'),
              const SizedBox(height: DesignTokens.s12),
              Consumer(
                builder: (context, ref, _) {
                  final async = ref.watch(recommendedBrandsProvider);
                  return async.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: DesignTokens.s16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                    ),
                    error: (_, _) => const _EmptyBrandsMessage(
                      'Could not load recommended brands.',
                    ),
                    data: (brands) => brands.isEmpty
                        ? const _EmptyBrandsMessage(
                            'No approved brands yet — check back soon.',
                          )
                        : Column(
                            children: [
                              for (final b in brands) ...[
                                GestureDetector(
                                  onTap: () => context.push(
                                    RouteNames.brandInfo,
                                    extra: _toBrandInfoData(b),
                                  ),
                                  child: _RecommendedCard(
                                    logo: _BrandLogo(
                                      name: b.businessName,
                                      logoUrl: b.logoUrl,
                                    ),
                                    name: b.businessName,
                                    commission: b.commissionRangeLabel,
                                  ),
                                ),
                                const SizedBox(height: DesignTokens.s12),
                              ],
                            ],
                          ),
                  );
                },
              ),
              const SizedBox(height: DesignTokens.s12),
              _SectionTitle('Browse all Brands'),
              const SizedBox(height: DesignTokens.s16),
              Consumer(
                builder: (context, ref, _) {
                  final async = ref.watch(brandsListProvider);
                  return async.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: DesignTokens.s16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                    ),
                    error: (_, _) => const _EmptyBrandsMessage(
                      'Could not load brands.',
                    ),
                    data: (brands) {
                      final filteredBrands = _filter.apply(brands);
                      return filteredBrands.isEmpty
                          ? const _EmptyBrandsMessage(
                              'No brands match these filters.',
                            )
                          : Column(
                              children: [
                                for (final b in filteredBrands)
                                  GestureDetector(
                                    onTap: () => context.push(
                                      RouteNames.brandInfo,
                                      extra: _toBrandInfoData(b),
                                    ),
                                    child: _BrandRow(
                                      logo: _BrandLogo(
                                        name: b.businessName,
                                        logoUrl: b.logoUrl,
                                      ),
                                      name: b.businessName,
                                      commission:
                                          '${b.commissionRangeLabel} Commissions',
                                    ),
                                  ),
                              ],
                            );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    final filter = await showModalBottomSheet<_BrandCatalogFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => _FilterPartnershipSheet(initialFilter: _filter),
    );
    if (filter != null && mounted) {
      setState(() => _filter = filter);
    }
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Consumer(
          builder: (_, ref, __) {
            final path = ref.watch(avatarImagePathProvider);
            return ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: path != null
                    ? Image.file(File(path), fit: BoxFit.cover)
                    : Container(
                        color: DesignTokens.bgAppBodyLight,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_rounded,
                          size: 22,
                          color: DesignTokens.textMuted,
                        ),
                      ),
              ),
            );
          },
        ),
        const Spacer(),
        _IconBtn(
          icon: Icons.search_rounded,
          onTap: () => context.push(RouteNames.creatorSearch),
        ),
        const SizedBox(width: DesignTokens.s8),
        _IconBtn(
          icon: Icons.tune_rounded,
          onTap: _showFilterSheet,
        ),
        const SizedBox(width: DesignTokens.s8),
        _IconBtn(
          icon: Icons.notifications_none_rounded,
          onTap: () => context.push(RouteNames.creatorActivity),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return Consumer(
      builder: (context, ref, _) {
        final activeCount = ref.watch(activePartnershipsProvider).length;
        final pendingCount = ref.watch(pendingInvitesCountProvider);
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(RouteNames.activePartnerships),
                child: _StatSummaryCard(
                  bg: DesignTokens.primaryGreen,
                  iconBg: const Color(0xFF27AE60),
                  imagePath: 'assets/images/creatordash/Partnership.png',
                  label: 'Active Partnerships',
                  value: activeCount.toString(),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(RouteNames.partnershipRequests),
                child: _StatSummaryCard(
                  bg: DesignTokens.bgAppBody,
                  iconBg: DesignTokens.bgAppBodyLight,
                  imagePath: 'assets/images/creatordash/Pending.png',
                  label: 'Pending Requests',
                  value: pendingCount.toString(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textWhite,
      ),
    );
  }
}

// ── Top-bar icon button ───────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFF2C2C2E),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: DesignTokens.textLight),
      ),
    );
  }
}

// ── Stat summary card (Active / Pending) ──────────────────────────────────────

class _StatSummaryCard extends StatelessWidget {
  const _StatSummaryCard({
    required this.bg,
    required this.iconBg,
    required this.label,
    required this.value,
    this.icon,
    this.imagePath,
  });

  final Color bg;
  final Color iconBg;
  final IconData? icon;
  final String label;
  final String value;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: imagePath != null ? Colors.transparent : iconBg,
                  shape: BoxShape.circle,
                ),
                child: imagePath != null
                    ? Image.asset(
                        imagePath!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : Icon(icon, size: 20, color: Colors.white),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recommended brand card ────────────────────────────────────────────────────

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.logo,
    required this.name,
    required this.commission,
  });

  final Widget logo;
  final String name;
  final String commission;

  @override
  Widget build(BuildContext context) {
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
              SizedBox(width: 44, height: 44, child: logo),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          const _DashedDivider(),
          const SizedBox(height: DesignTokens.s12),
          _MetricRow(
            iconWidget: Image.asset(
              'assets/images/creatordash/material-symbols_money-bag-outline-rounded.png',
              width: 15,
              height: 15,
              color: DesignTokens.textMuted,
            ),
            label: 'Commission Range',
            trailing: _CommissionChip(commission),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    this.icon,
    this.iconWidget,
    required this.label,
    this.trailing,
    this.trailingText,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final Widget? trailing;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        iconWidget ?? Icon(icon!, size: 15, color: DesignTokens.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            color: DesignTokens.textLight,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
        if (trailingText != null)
          Text(
            trailingText!,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textWhite,
            ),
          ),
      ],
    );
  }
}

class _CommissionChip extends StatelessWidget {
  const _CommissionChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF87CEEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0D1B4B),
        ),
      ),
    );
  }
}

// ── Dashed divider ────────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedPainter(),
      child: const SizedBox(height: 1, width: double.infinity),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6B6B6B)
      ..strokeWidth = 1;
    double x = 0;
    const dash = 6.0;
    const gap = 4.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyBrandsMessage extends StatelessWidget {
  const _EmptyBrandsMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 13,
          color: DesignTokens.textMuted,
        ),
      ),
    );
  }
}

// ── Browse brand row ──────────────────────────────────────────────────────────

class _BrandRow extends StatelessWidget {
  const _BrandRow({
    required this.logo,
    required this.name,
    required this.commission,
  });

  final Widget logo;
  final String name;
  final String commission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: DesignTokens.s12,
        horizontal: DesignTokens.s4,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesignTokens.borderDefault, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 48, height: 48, child: logo),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  commission,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF00BCFF),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: DesignTokens.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Brand logo ────────────────────────────────────────────────────────────────

/// Real vendor logo when available, else an initials avatar derived from the
/// business name — no per-brand hardcoded artwork.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.name, this.logoUrl});

  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          logoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _e, _s) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: DesignTokens.textWhite,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BrandsBottomNav extends ConsumerWidget {
  const _BrandsBottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref
        .watch(sessionControllerProvider)
        .maybeWhen(authenticated: (id) => id, orElse: () => '');
    return Container(
      height: 68 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBtn(
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => context.go(RouteNames.creatorHome),
            ),
            _NavBtn(
              iconWidget: Image.asset(
                'assets/images/creatordash/Analytics_icon.png',
                width: 22,
                height: 22,
              ),
              label: 'Analytics',
              onTap: () => context.push(RouteNames.creatorAnalytics),
            ),
            GestureDetector(
              onTap: () => context.push(RouteNames.reelImport),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: DesignTokens.primaryGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            _NavBtn(
              iconWidget: Image.asset(
                'assets/images/creatordash/open_brand_icon.png',
                width: 22,
                height: 22,
              ),
              label: 'Brands',
              active: true,
              onTap: null,
            ),
            _NavBtn(
              icon: Icons.person_rounded,
              label: 'Profile',
              onTap: () => context.push(
                RouteNames.creatorProfile.replaceFirst(':accountId', accountId),
                extra: CreatorProfileArgs(
                  accountId: accountId,
                  displayName: '',
                  handle: '',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.onTap,
    this.active = false,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? DesignTokens.primaryGreen : DesignTokens.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget ?? Icon(icon!, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Partnership bottom sheet ─────────────────────────────────────────

class _FilterPartnershipSheet extends StatefulWidget {
  const _FilterPartnershipSheet({required this.initialFilter});

  final _BrandCatalogFilter initialFilter;

  @override
  State<_FilterPartnershipSheet> createState() =>
      _FilterPartnershipSheetState();
}

class _FilterPartnershipSheetState extends State<_FilterPartnershipSheet> {
  late final _fromCtrl = TextEditingController(
    text: widget.initialFilter.minimum?.toStringAsFixed(0) ?? '',
  );
  late final _toCtrl = TextEditingController(
    text: widget.initialFilter.maximum?.toStringAsFixed(0) ?? '',
  );
  late _BrandCatalogSort? _sort = widget.initialFilter.sort;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _fromCtrl.clear();
      _toCtrl.clear();
      _sort = null;
    });
  }

  void _apply() {
    final minimum = double.tryParse(_fromCtrl.text.trim());
    final maximum = double.tryParse(_toCtrl.text.trim());
    if (minimum != null && maximum != null && minimum > maximum) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum commission cannot exceed maximum.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      _BrandCatalogFilter(minimum: minimum, maximum: maximum, sort: _sort),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody.withOpacity(0.92),
            ),
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Text(
                      'Filter Partnership',
                      style: DesignTokens.sectionInnerTitle,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.close_rounded,
                        color: DesignTokens.textWhite,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s16),

                // Commission range
                const Text(
                  'Commission Range',
                  style: DesignTokens.smallRegular,
                ),
                const SizedBox(height: DesignTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fromCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          color: DesignTokens.inputFieldData,
                        ),
                        decoration: DesignTokens.inputDecoration(
                          hintText: 'From',
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: TextField(
                        controller: _toCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          color: DesignTokens.inputFieldData,
                        ),
                        decoration: DesignTokens.inputDecoration(
                          hintText: 'To',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s20),

                // Status
                const Text('Status', style: DesignTokens.smallRegular),
                const SizedBox(height: DesignTokens.s4),
                _StatusCheckboxRow(
                  label: 'Newest',
                  value: _sort == _BrandCatalogSort.newest,
                  onChanged: (_) =>
                      setState(() => _sort = _BrandCatalogSort.newest),
                ),
                _StatusCheckboxRow(
                  label: 'Highest Earnings',
                  value: _sort == _BrandCatalogSort.highestCommission,
                  onChanged: (_) => setState(
                    () => _sort = _BrandCatalogSort.highestCommission,
                  ),
                ),
                _StatusCheckboxRow(
                  label: 'Lowest Earnings',
                  value: _sort == _BrandCatalogSort.lowestCommission,
                  onChanged: (_) => setState(
                    () => _sort = _BrandCatalogSort.lowestCommission,
                  ),
                ),
                _StatusCheckboxRow(
                  label: 'Name',
                  value: _sort == _BrandCatalogSort.name,
                  onChanged: (_) =>
                      setState(() => _sort = _BrandCatalogSort.name),
                ),
                const SizedBox(height: DesignTokens.s20),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: DesignTokens.buttonHeight,
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: DesignTokens.borderDefault,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.buttonRadius,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              color: DesignTokens.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: SizedBox(
                        height: DesignTokens.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _apply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignTokens.buttonRadius,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              color: DesignTokens.buttonPrimaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCheckboxRow extends StatelessWidget {
  const _StatusCheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                side: const BorderSide(
                  color: DesignTokens.borderDefault,
                  width: 1.5,
                ),
                activeColor: DesignTokens.primaryGreen,
                checkColor: DesignTokens.buttonPrimaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
