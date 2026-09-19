// Dense product copy and immutable parser factories are intentionally kept together.
// ignore_for_file: lines_longer_than_80_chars, sort_constructors_first

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

final FutureProvider<List<LifecycleAsset>> lifecycleAssetsProvider =
    FutureProvider.autoDispose<List<LifecycleAsset>>((ref) async {
      final response = await ref
          .watch(apiClientProvider)
          .get('/v1/customer/lifecycle/assets');
      return (response as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LifecycleAsset.fromJson)
          .toList(growable: false);
    });

class LifecycleAsset {
  const LifecycleAsset({
    required this.lineId,
    required this.title,
    required this.variant,
    required this.image,
    required this.ageDays,
    required this.remainingDays,
    required this.recommendation,
    required this.reason,
    required this.pathways,
  });
  final String lineId;
  final String title;
  final String? variant;
  final String? image;
  final int ageDays;
  final int remainingDays;
  final String recommendation;
  final String reason;
  final List<LifecyclePathway> pathways;

  factory LifecycleAsset.fromJson(Map<String, dynamic> json) => LifecycleAsset(
    lineId: json['subOrderLineId'] as String? ?? '',
    title: json['title'] as String? ?? 'Your item',
    variant: json['variantLabel'] as String?,
    image: json['thumbnailUrl'] as String?,
    ageDays: (json['ageDays'] as num?)?.toInt() ?? 0,
    remainingDays: (json['estimatedRemainingLifeDays'] as num?)?.toInt() ?? 0,
    recommendation: json['recommendation'] as String? ?? '',
    reason: json['recommendationReason'] as String? ?? '',
    pathways: (json['pathways'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LifecyclePathway.fromJson)
        .toList(growable: false),
  );
}

class LifecyclePathway {
  const LifecyclePathway({
    required this.kind,
    required this.available,
    required this.explanation,
  });
  final int kind;
  final bool available;
  final String explanation;
  factory LifecyclePathway.fromJson(Map<String, dynamic> json) =>
      LifecyclePathway(
        kind: json['pathway'] is num
            ? (json['pathway'] as num).toInt()
            : _kind(json['pathway']?.toString()),
        available: json['available'] as bool? ?? false,
        explanation: json['explanation'] as String? ?? '',
      );
  static int _kind(String? value) => switch (value?.toLowerCase()) {
    'repair' => 1,
    'tradein' => 2,
    'resale' => 3,
    'recycle' => 4,
    _ => 0,
  };
  String get label => switch (kind) {
    1 => 'Repair',
    2 => 'Trade in',
    3 => 'Resell',
    4 => 'Recycle',
    _ => 'Circular care',
  };
  IconData get icon => switch (kind) {
    1 => Icons.handyman_outlined,
    2 => Icons.swap_horiz_rounded,
    3 => Icons.sell_outlined,
    4 => Icons.recycling_rounded,
    _ => Icons.eco_outlined,
  };
}

class LifecycleStewardScreen extends ConsumerWidget {
  const LifecycleStewardScreen({super.key});
  static const portfolioKey = ValueKey<String>('lifecycle-portfolio');
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(lifecycleAssetsProvider);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: const Text('My wardrobe life'),
        backgroundColor: DesignTokens.bgAppFoundation,
      ),
      body: assets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Empty(
          icon: Icons.cloud_off_rounded,
          title: 'Wardrobe unavailable',
          body: 'Check your connection and try again.',
          onTap: () => ref.invalidate(lifecycleAssetsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(lifecycleAssetsProvider.future),
          child: ListView(
            key: portfolioKey,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
            children: [
              const _Hero(),
              const SizedBox(height: 18),
              if (items.isEmpty)
                const _Empty(
                  icon: Icons.checkroom_outlined,
                  title: 'Your wardrobe story starts after delivery',
                  body:
                      'Delivered purchases appear here with care-first guidance.',
                )
              else
                for (final item in items) ...[
                  _AssetCard(item),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      color: DesignTokens.primaryGreenDark,
      boxShadow: DesignTokens.shadowCard,
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.eco_rounded, color: DesignTokens.primaryGreen, size: 34),
        SizedBox(height: 14),
        Text(
          'Love it longer.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Know when to keep, care, repair or pass an item forward. StyleMint will never push a replacement while useful life remains.',
          style: TextStyle(color: DesignTokens.textLight, height: 1.45),
        ),
      ],
    ),
  );
}

class _AssetCard extends ConsumerWidget {
  const _AssetCard(this.asset);
  final LifecycleAsset asset;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keep = asset.recommendation == 'do_not_replace_yet';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        boxShadow: DesignTokens.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (asset.image case final image?)
            Image.network(
              image,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 110,
                child: Center(child: Icon(Icons.checkroom, size: 44)),
              ),
            )
          else
            const SizedBox(
              height: 110,
              child: Center(child: Icon(Icons.checkroom, size: 44)),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        asset.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (asset.variant case final variant?)
                      Text(
                        variant,
                        style: const TextStyle(color: DesignTokens.textLight),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                MallStatusPill(
                  label: keep
                      ? 'Keep & care · ${asset.remainingDays} days est.'
                      : 'Assess next life',
                  tone: keep ? MallStatusTone.success : MallStatusTone.caution,
                  icon: keep ? Icons.eco_outlined : Icons.autorenew_rounded,
                ),
                const SizedBox(height: 10),
                Text(
                  asset.reason,
                  style: const TextStyle(
                    color: DesignTokens.textLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final pathway in asset.pathways)
                      ActionChip(
                        avatar: Icon(pathway.icon, size: 18),
                        label: Text(pathway.label),
                        onPressed: () => _request(context, ref, asset, pathway),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _request(
    BuildContext context,
    WidgetRef ref,
    LifecycleAsset asset,
    LifecyclePathway pathway,
  ) async {
    final condition = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.surfaceRaised,
      builder: (_) => _ConditionSheet(pathway),
    );
    if (condition == null || !context.mounted) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .post(
            '/v1/customer/lifecycle/assets/${asset.lineId}/requests',
            data: {'pathway': pathway.kind, 'condition': condition},
            options: Options(
              headers: {
                'requiresToken': true,
                'Idempotency-Key': 'lifecycle-${asset.lineId}-${pathway.kind}',
              },
            ),
          );
      if (!context.mounted) return;
      final state = response is Map<String, dynamic> ? response['state'] : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state == 3 || state == 'Accepted'
                ? '${pathway.label} request accepted.'
                : '${pathway.label} request saved. We will connect a verified provider when available.',
          ),
        ),
      );
    } on Object catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this request. Please try again.'),
          ),
        );
      }
    }
  }
}

class _ConditionSheet extends StatefulWidget {
  const _ConditionSheet(this.pathway);
  final LifecyclePathway pathway;
  @override
  State<_ConditionSheet> createState() => _ConditionSheetState();
}

class _ConditionSheetState extends State<_ConditionSheet> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.pathway.label} this item',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.pathway.available
              ? 'A verified provider is available.'
              : widget.pathway.explanation,
          style: const TextStyle(color: DesignTokens.textLight),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          maxLength: 80,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'What condition is it in?',
            hintText: 'Example: good, one button missing',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Save request'),
          ),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.body,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: DesignTokens.primaryGreen),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: DesignTokens.textLight),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onTap, child: const Text('Try again')),
          ],
        ],
      ),
    ),
  );
}
