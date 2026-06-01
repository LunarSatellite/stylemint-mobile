import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Brand / partnership detail (creator). Pixel-matched to Creator
/// 'Brand Details' PDFs (Partnership Terms + commission).
/// Backend: `GET /v1/partnerships/{id}` + `/v1/partnerships/{id}/terms/active`.
final _partnershipProvider = FutureProvider.autoDispose
    .family<PartnershipDetailDto, String>((ref, id) async {
  final ApiClient api = ref.watch(apiClientProvider);
  final res = await api.get('/v1/partnerships/$id');
  return PartnershipDetailDto.fromJson(res as Map<String, dynamic>);
});

final _termsProvider =
    FutureProvider.autoDispose.family<PartnershipTermsDto, String>((ref, id) async {
  final ApiClient api = ref.watch(apiClientProvider);
  final res = await api.get('/v1/partnerships/$id/terms/active');
  return PartnershipTermsDto.fromJson(res as Map<String, dynamic>);
});

class BrandDetailScreen extends ConsumerWidget {
  const BrandDetailScreen({super.key, required this.partnershipId});

  final String partnershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnership = ref.watch(_partnershipProvider(partnershipId));
    final terms = ref.watch(_termsProvider(partnershipId));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Brand Details', style: DesignTokens.sectionInnerTitle),
      ),
      body: partnership.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: DesignTokens.primaryGreen)),
        error: (_, __) => Center(
            child: Text("Couldn't load this partnership.",
                style: DesignTokens.bodyText)),
        data: (p) => ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            Row(
              children: [
                _Chip(label: p.stateLabel),
                if (p.vendorRating != null) ...[
                  const SizedBox(width: DesignTokens.s8),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 16, color: DesignTokens.secondaryYellow),
                      const SizedBox(width: 2),
                      Text(p.vendorRating!.toStringAsFixed(1),
                          style: DesignTokens.smallRegular),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            Container(
              padding: const EdgeInsets.all(DesignTokens.s16),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Commission', style: DesignTokens.mediumRegular),
                  Text(
                    p.commissionMinPercent == p.commissionMaxPercent
                        ? '${p.commissionMaxPercent.toStringAsFixed(0)}%'
                        : '${p.commissionMinPercent.toStringAsFixed(0)}–${p.commissionMaxPercent.toStringAsFixed(0)}%',
                    style: DesignTokens.mediumSemibold
                        .copyWith(color: DesignTokens.primaryGreen),
                  ),
                ],
              ),
            ),
            if (p.requestMessage != null && p.requestMessage!.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s12),
              Text(p.requestMessage!, style: DesignTokens.bodyText),
            ],
            const SizedBox(height: DesignTokens.s24),
            Text('Partnership Terms', style: DesignTokens.sectionInnerTitle),
            const SizedBox(height: DesignTokens.s12),
            terms.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(DesignTokens.s16),
                child: CircularProgressIndicator(
                    color: DesignTokens.primaryGreen),
              )),
              error: (_, __) => Text('Terms unavailable.',
                  style: DesignTokens.bodyText),
              data: (t) => Column(
                children: [
                  _TermsSectionCard(section: t.whoCanJoin),
                  const SizedBox(height: DesignTokens.s12),
                  _TermsSectionCard(section: t.reelContentRules),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: DesignTokens.s12, vertical: 4),
      decoration: BoxDecoration(
        color: DesignTokens.chipsSelectedFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: DesignTokens.smallRegular
              .copyWith(color: DesignTokens.primaryGreen)),
    );
  }
}

class _TermsSectionCard extends StatelessWidget {
  const _TermsSectionCard({required this.section});
  final TermsSection section;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.heading, style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s8),
          if (section.bullets.isEmpty)
            Text('—',
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textMuted))
          else
            for (final b in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: DesignTokens.s8),
                      child: Icon(Icons.circle,
                          size: 6, color: DesignTokens.primaryGreen),
                    ),
                    Expanded(child: Text(b, style: DesignTokens.bodyText)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
