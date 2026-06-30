import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/notifiers/reviews_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/rate_review_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/review_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ProductReviewsScreen extends ConsumerWidget {
  const ProductReviewsScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: AppBar(
          backgroundColor: DesignTokens.bgAppFoundation,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: DesignTokens.textWhite),
            onPressed: () => context.pop(),
          ),
          title: Text('Customer Reviews', style: DesignTokens.sectionInnerTitle),
          centerTitle: true,
          bottom: const TabBar(
            labelStyle: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            labelColor: DesignTokens.primaryGreen,
            unselectedLabelColor: DesignTokens.textMuted,
            indicatorColor: DesignTokens.primaryGreen,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [Tab(text: 'Reel Reviews'), Tab(text: 'Written Reviews')],
          ),
        ),
        body: TabBarView(
          children: [
            _ReelReviewsTab(productId: productId),
            _WrittenReviewsTab(productId: productId),
          ],
        ),
        bottomNavigationBar: _AddReviewBar(productId: productId),
      ),
    );
  }
}

// ── Reel Reviews Tab ──────────────────────────────────────────────────────────

// ponytail: grid uses placeholder tiles — swap with reel-reviews API when available
class _ReelReviewsTab extends StatelessWidget {
  const _ReelReviewsTab({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: 9,
      itemBuilder: (_, i) => _ReelThumbnailTile(fakeViewCount: _fakeCount(i)),
    );
  }

  static String _fakeCount(int i) {
    const counts = ['12.3m', '400k', '1.5m', '900k', '500k', '12.3m', '12.3m', '12.9m', '12.3m'];
    return counts[i % counts.length];
  }
}

class _ReelThumbnailTile extends StatelessWidget {
  const _ReelThumbnailTile({required this.fakeViewCount});

  final String fakeViewCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: DesignTokens.bgAppBodyLight),
        const Center(
          child: Icon(Icons.play_circle_outline_rounded, color: Colors.white54, size: 32),
        ),
        Positioned(
          bottom: 6,
          left: 6,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white70),
              const SizedBox(width: 2),
              Text(
                fakeViewCount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Written Reviews Tab ───────────────────────────────────────────────────────

class _WrittenReviewsTab extends ConsumerWidget {
  const _WrittenReviewsTab({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewsNotifierProvider(productId));

    ref.listen<ReviewsState>(reviewsNotifierProvider(productId), (_, next) {
      next.maybeWhen(
        loadFailure: (_) => SmSnackbar.error(context, 'Failed to load reviews.'),
        orElse: () {},
      );
    });

    ref.listen<SubmitReviewState>(submitReviewNotifierProvider, (_, next) {
      next.maybeWhen(
        success: (_) {
          SmSnackbar.success(context, 'Review submitted successfully!');
          ref.read(reviewsNotifierProvider(productId).notifier).refresh();
          ref.read(submitReviewNotifierProvider.notifier).reset();
        },
        failure: (_) => SmSnackbar.error(context, 'Failed to submit review.'),
        orElse: () {},
      );
    });

    return state.when(
      initial: _loader,
      loadInProgress: _loader,
      loadSuccess: (reviews, _, hasMore, __) {
        if (reviews.isEmpty) {
          return const SmEmptyState(
            message: 'No reviews yet. Be the first to review this product!',
            icon: Icons.rate_review_outlined,
          );
        }
        return RefreshIndicator(
          color: DesignTokens.primaryGreen,
          onRefresh: () => ref.read(reviewsNotifierProvider(productId).notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16,
              vertical: DesignTokens.s12,
            ),
            itemCount: reviews.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox.shrink(),
            itemBuilder: (_, i) {
              if (i == reviews.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
                  child: Center(
                    child: TextButton(
                      onPressed: () => ref.read(reviewsNotifierProvider(productId).notifier).loadMore(),
                      child: Text(
                        'Load More',
                        style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.primaryGreen),
                      ),
                    ),
                  ),
                );
              }
              return ReviewCard(review: reviews[i]);
            },
          ),
        );
      },
      loadFailure: (_) => SmErrorView(
        message: 'Failed to load reviews.',
        onRetry: () => ref.read(reviewsNotifierProvider(productId).notifier).refresh(),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

// ── Add Review Bottom Bar ─────────────────────────────────────────────────────

class _AddReviewBar extends StatelessWidget {
  const _AddReviewBar({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s12 + bottomPad,
      ),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(top: BorderSide(color: DesignTokens.borderDefault, width: 0.5)),
      ),
      child: ElevatedButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: DesignTokens.bgAppBody,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.cardRadius)),
          ),
          builder: (_) => RateReviewSheet(productId: productId),
        ),
        style: DesignTokens.primaryButtonStyle(width: double.infinity),
        child: Text(
          'Add Review',
          style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.buttonPrimaryText),
        ),
      ),
    );
  }
}
