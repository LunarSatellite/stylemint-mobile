import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/notifiers/reviews_notifier.dart';
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
    final state = ref.watch(reviewsNotifierProvider(productId));

    ref.listen<ReviewsState>(reviewsNotifierProvider(productId), (previous, next) {
      next.maybeWhen(
        loadFailure: (failure) => SmSnackbar.error(context, 'Failed to load reviews.'),
        orElse: () {},
      );
    });

    ref.listen<SubmitReviewState>(submitReviewNotifierProvider, (previous, next) {
      next.maybeWhen(
        success: (_) {
          SmSnackbar.success(context, 'Review submitted successfully!');
          ref.read(reviewsNotifierProvider(productId).notifier).refresh();
          ref.read(submitReviewNotifierProvider.notifier).reset();
          context.pop();
        },
        failure: (failure) => SmSnackbar.error(context, 'Failed to submit review.'),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Customer Reviews',
          style: DesignTokens.sectionInnerTitle,
        ),
        centerTitle: true,
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (reviews, summary, hasMore, nextCursor) {
          if (reviews.isEmpty) {
            return const SmEmptyState(
              message: 'No reviews yet. Be the first to review this product!',
              icon: Icons.rate_review_outlined,
            );
          }
          return RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh: () => ref.read(reviewsNotifierProvider(productId).notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ReviewSummaryHeader(summary: summary),
                ),
                if (reviews.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ReviewCard(review: reviews[i]),
                        childCount: reviews.length,
                      ),
                    ),
                  ),
                if (hasMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.s16),
                      child: Center(
                        child: TextButton(
                          onPressed: () => ref.read(reviewsNotifierProvider(productId).notifier).loadMore(),
                          child: Text(
                            'Load More',
                            style: DesignTokens.mediumSemibold.copyWith(
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.s48),
                ),
              ],
            ),
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load reviews.',
          onRetry: () => ref.read(reviewsNotifierProvider(productId).notifier).refresh(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWriteReview(context, ref),
        backgroundColor: DesignTokens.primaryGreen,
        foregroundColor: DesignTokens.buttonPrimaryText,
        icon: const Icon(Icons.edit),
        label: const Text('Write a Review'),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  void _showWriteReview(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.cardRadius)),
      ),
      builder: (ctx) => _WriteReviewSheet(productId: productId),
    );
  }
}

class _ReviewSummaryHeader extends StatelessWidget {
  const _ReviewSummaryHeader({required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.s16),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                children: [
                  Text(
                    summary.averageRating.toStringAsFixed(1),
                    style: DesignTokens.titleLarge.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  _StarRating(rating: summary.averageRating.round()),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    '${summary.totalReviews} review${summary.totalReviews == 1 ? '' : 's'}',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: DesignTokens.s32),
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final count = summary.ratingDistribution[star] ?? 0;
                    final maxVal = summary.totalReviews > 0 ? summary.totalReviews : 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$star',
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.s4),
                          const Icon(Icons.star, size: 12, color: Color(0xFFF1C40F)),
                          const SizedBox(width: DesignTokens.s8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: count / maxVal,
                                minHeight: 6,
                                backgroundColor: DesignTokens.bgAppBodyLight,
                                color: const Color(0xFFF1C40F),
                              ),
                            ),
                          ),
                          const SizedBox(width: DesignTokens.s8),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '$count',
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating) {
          return const Icon(Icons.star, size: 14, color: Color(0xFFF1C40F));
        }
        return const Icon(Icons.star_border, size: 14, color: Color(0xFFF1C40F));
      }),
    );
  }
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  const _WriteReviewSheet({required this.productId});

  final String productId;

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitReviewNotifierProvider);
    final isSubmitting = submitState.maybeWhen(
      submitting: () => true,
      orElse: () => false,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.s16,
        right: DesignTokens.s16,
        top: DesignTokens.s24,
        bottom: MediaQuery.of(context).viewInsets.bottom + DesignTokens.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Write a Review',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: isSubmitting ? null : () => setState(() => _rating = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      size: 36,
                      color: const Color(0xFFF1C40F),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          TextField(
            controller: _commentController,
            maxLines: 4,
            style: DesignTokens.bodyText,
            enabled: !isSubmitting,
            decoration: DesignTokens.inputDecoration(
              hintText: 'Share your experience with this product...',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      final comment = _commentController.text.trim();
                      if (comment.isEmpty) {
                        SmSnackbar.warning(context, 'Please write a review comment.');
                        return;
                      }
                      ref.read(submitReviewNotifierProvider.notifier).submitReview(
                        productId: widget.productId,
                        rating: _rating,
                        comment: comment,
                      );
                    },
              style: DesignTokens.primaryButtonStyle(),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    )
                  : Text(
                      'Submit Review',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
