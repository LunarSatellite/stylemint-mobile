import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Home Page Reel — vertical, full-screen reels feed (Figma node 9386-5224).
///
/// State comes from [reelsFeedNotifierProvider]; the notifier talks to the
/// reels repository directly (no UseCase layer).
class ReelsFeedScreen extends ConsumerWidget {
  const ReelsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reelsFeedNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (reels) {
          if (reels.isEmpty) {
            return const SmEmptyState(
              message: 'No reels yet. Check back soon for new content.',
              icon: Icons.video_library_outlined,
            );
          }
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (_, index) => ReelCard(reel: reels[index]),
          );
        },
        loadFailure:
            (failure) => SmErrorView(
              message: 'Failed to load reels.',
              onRetry:
                  () =>
                      ref.read(reelsFeedNotifierProvider.notifier).fetchFeed(),
            ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
