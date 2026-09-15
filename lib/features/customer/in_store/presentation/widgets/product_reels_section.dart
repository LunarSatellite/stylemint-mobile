import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_poster.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A row of reels that tag the product. Each opens StyleMint's own reel
/// screen (`/reels/{id}`).
class ProductReelsSection extends ConsumerWidget {
  const ProductReelsSection({required this.productId, super.key});

  static const String title = 'Reels with this product';
  static const String emptyMessage = 'No reels with this product yet.';
  static const String failedMessage = "Couldn't load reels.";

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = productReelsNotifierProvider(productId);
    final state = ref.watch(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(title, style: DesignTokens.sectionInnerTitle),
        const SizedBox(height: DesignTokens.s12),
        switch (state) {
          ProductReelsLoading() => const SizedBox(
            height: _ReelTile.height,
            child: SmPageLoader(size: 40),
          ),
          ProductReelsFailed() => Row(
            children: [
              Expanded(
                child: Text(
                  failedMessage,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => unawaited(ref.read(provider.notifier).load()),
                style: DesignTokens.textButtonStyle(),
                child: const Text('Try again'),
              ),
            ],
          ),
          ProductReelsLoaded(:final reels) when reels.isEmpty => Text(
            emptyMessage,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          ProductReelsLoaded(:final reels) => SizedBox(
            height: _ReelTile.height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: reels.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: DesignTokens.s8),
              itemBuilder: (_, index) => _ReelTile(reel: reels[index]),
            ),
          ),
        },
      ],
    );
  }
}

class _ReelTile extends StatelessWidget {
  const _ReelTile({required this.reel});

  static const double width = 120;
  static const double height = width * 16 / 9;

  final ProductReel reel;

  @override
  Widget build(BuildContext context) {
    final creator = reel.creatorName;
    return Semantics(
      button: true,
      label: creator.isEmpty ? 'Watch reel' : 'Watch reel by $creator',
      child: InkWell(
        key: ValueKey('product-reel-${reel.id}'),
        borderRadius: BorderRadius.circular(DesignTokens.s12),
        onTap: () => unawaited(
          context.push(RouteNames.reelDetail.replaceFirst(':reelId', reel.id)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.s12),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(child: ReelPoster(reel: reel)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x99000000)],
                      stops: [0.55, 1],
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: DesignTokens.textWhite,
                    size: 32,
                  ),
                ),
                if (creator.isNotEmpty)
                  Positioned(
                    left: DesignTokens.s8,
                    right: DesignTokens.s8,
                    bottom: DesignTokens.s8,
                    child: Text(
                      creator,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textWhite,
                        fontWeight: FontWeight.w600,
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
