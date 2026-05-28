import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/providers/reels_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/empty_state.dart';

/// Reels feed screen - displays vertical scroll feed of reels
/// Each reel shows video placeholder, creator info, caption, actions, and tagged products
class ReelsFeedScreen extends ConsumerWidget {
  const ReelsFeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reelsAsync = ref.watch(reelsFeedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: reelsAsync.when(
        data: (reels) {
          if (reels.isEmpty) {
            return EmptyState(
              title: 'No reels yet',
              message: 'Check back soon for new content',
            );
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (context, index) {
              final reel = reels[index];
              return ReelCard(reel: reel);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => ErrorView(
          title: 'Failed to load reels',
          message: error.toString(),
          onRetry: () => ref.refresh(reelsFeedProvider),
        ),
      ),
    );
  }
}
