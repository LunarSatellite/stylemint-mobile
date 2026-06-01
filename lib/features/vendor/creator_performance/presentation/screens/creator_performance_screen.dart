import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/data/models/creator_match_dto.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Creator Performance (vendor). Pixel-matched to Brand
/// 'Creator Performance-Actions.pdf'. Backed by `GET /v1/vendor/matches`
/// (match score + reason) — the available vendor-facing creator signal.
final _vendorMatchesProvider =
    FutureProvider.autoDispose<List<CreatorMatchDto>>((ref) async {
  final ApiClient api = ref.watch(apiClientProvider);
  final res = await api.get('/v1/vendor/matches', queryParameters: {'pageSize': 25});
  final map = res as Map<String, dynamic>;
  final items = (map['items'] as List<dynamic>? ?? const <dynamic>[]);
  return items
      .whereType<Map<String, dynamic>>()
      .map(CreatorMatchDto.fromJson)
      .toList(growable: false);
});

class CreatorPerformanceScreen extends ConsumerWidget {
  const CreatorPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_vendorMatchesProvider);
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
            child: Text("Couldn't load creators.", style: DesignTokens.bodyText)),
        data: (matches) => matches.isEmpty
            ? Center(
                child: Text('No matched creators yet.',
                    style: DesignTokens.bodyText))
            : ListView.separated(
                padding: const EdgeInsets.all(DesignTokens.s16),
                itemCount: matches.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesignTokens.s12),
                itemBuilder: (_, i) => _MatchCard(match: matches[i]),
              ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});
  final CreatorMatchDto match;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${match.creatorHandle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold),
                if (match.reasonSummary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(match.reasonSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Column(
            children: [
              Text('${match.scorePercent.toStringAsFixed(0)}%',
                  style: DesignTokens.mediumSemibold
                      .copyWith(color: DesignTokens.primaryGreen)),
              Text('match',
                  style: DesignTokens.tiny
                      .copyWith(color: DesignTokens.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
