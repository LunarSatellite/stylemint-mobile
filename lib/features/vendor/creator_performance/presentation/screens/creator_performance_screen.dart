import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/data/models/creator_performance_dto.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Creator Performance (vendor). Pixel-matched to Brand
/// 'Creator Performance-Actions.pdf'. Backed by the real
/// `GET /v1/vendor/creator-performance` endpoint — per-creator units sold,
/// attributed revenue, commission paid, and distinct reels of the vendor's
/// products over the last 30 days (default window). Ordered by revenue desc.
final _creatorPerformanceProvider =
    FutureProvider.autoDispose<List<CreatorPerformanceDto>>((ref) async {
  final ApiClient api = ref.watch(apiClientProvider);
  final res = await api.get(
    '/v1/vendor/creator-performance',
    queryParameters: {'limit': 25},
  );
  final items = (res as List<dynamic>? ?? const <dynamic>[]);
  return items
      .whereType<Map<String, dynamic>>()
      .map(CreatorPerformanceDto.fromJson)
      .toList(growable: false);
});

class CreatorPerformanceScreen extends ConsumerWidget {
  const CreatorPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_creatorPerformanceProvider);
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
        title: const Text('Creator Performance',
            style: DesignTokens.sectionInnerTitle),
      ),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: DesignTokens.primaryGreen)),
        error: (_, __) => Center(
            child: Text("Couldn't load performance.", style: DesignTokens.bodyText)),
        data: (rows) => rows.isEmpty
            ? Center(
                child: Text('No creator sales in the last 30 days.',
                    style: DesignTokens.bodyText))
            : ListView.separated(
                padding: const EdgeInsets.all(DesignTokens.s16),
                itemCount: rows.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesignTokens.s12),
                itemBuilder: (_, i) => _PerformanceCard(row: rows[i]),
              ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.row});
  final CreatorPerformanceDto row;

  String _money(double v) => '${row.currency} ${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: DesignTokens.avatarMedium,
                height: DesignTokens.avatarMedium,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.bgAppFoundation,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.person, color: DesignTokens.iconLight),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Text(row.shortLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_money(row.attributedRevenue),
                      style: DesignTokens.mediumSemibold
                          .copyWith(color: DesignTokens.primaryGreen)),
                  Text('revenue',
                      style: DesignTokens.tiny
                          .copyWith(color: DesignTokens.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Units sold', value: '${row.unitsSold}'),
              _Stat(label: 'Commission', value: _money(row.commissionPaid)),
              _Stat(label: 'Reels', value: '${row.distinctReelCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: DesignTokens.mediumSemibold),
        Text(label,
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted)),
      ],
    );
  }
}
