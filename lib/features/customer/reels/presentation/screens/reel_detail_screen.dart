import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One reel opened by id at `/reels/:reelId`: a StyleMint share link (the
/// Android App Link lands here) or a search result.
///
/// Plays in-app through [ReelCard], with the same rail as the feed. The back
/// bar sits above the reel, not over the player.
class ReelDetailScreen extends ConsumerWidget {
  const ReelDetailScreen({required this.reelId, super.key});

  final String reelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reel = ref.watch(reelDetailProvider(reelId));
    return Scaffold(
      backgroundColor: DesignTokens.baseBlack,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  const SizedBox(width: DesignTokens.s8),
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.popOrHome(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: reel.when(
              loading: () => const SmPageLoader(),
              error: (error, _) => SmErrorView(
                message: error is NetworkExceptions && error.isNotFound
                    ? 'This reel is no longer available.'
                    : "Couldn't load this reel.",
                onRetry: () => ref.invalidate(reelDetailProvider(reelId)),
              ),
              data: (value) => ReelCard(reel: value, isActive: true),
            ),
          ),
        ],
      ),
    );
  }
}
