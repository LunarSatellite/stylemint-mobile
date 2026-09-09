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
import 'package:url_launcher/url_launcher.dart';

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

class _ReelReviewsTab extends ConsumerWidget {
  const _ReelReviewsTab({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewsNotifierProvider(productId));
    return state.maybeWhen(
      loadSuccess: (reviews, _, __, ___) {
        final reelReviews = reviews
            .where((review) =>
                review.kind == ReviewKind.reel &&
                Uri.tryParse(review.reelSourceUrl ?? '') != null)
            .toList(growable: false);
        if (reelReviews.isEmpty) {
          return const SmEmptyState(
            message: 'No reel reviews yet.',
            icon: Icons.play_circle_outline_rounded,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(3),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemCount: reelReviews.length,
          itemBuilder: (_, index) =>
              _ReelThumbnailTile(review: reelReviews[index]),
        );
      },
      loadFailure: (_) => SmErrorView(
        message: 'Failed to load reviews.',
        onRetry: () => ref.read(reviewsNotifierProvider(productId).notifier).refresh(),
      ),
      orElse: () => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      ),
    );
  }
}

class _ReelThumbnailTile extends StatelessWidget {
  const _ReelThumbnailTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final source = Uri.tryParse(review.reelSourceUrl ?? '');
    final provider = _providerName(review.reelPlatform);
    return Material(
      color: DesignTokens.bgAppBodyLight,
      child: InkWell(
        onTap: source == null
            ? null
            : () => launchUrl(source, mode: LaunchMode.externalApplication),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(
              child: Icon(Icons.play_circle_outline_rounded,
                  color: Colors.white54, size: 32),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              left: 6,
              child: Text(
                provider,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _providerName(String? platform) => switch (platform) {
        '0' || 'Instagram' || 'instagram' => 'Instagram',
        '1' || 'YouTubeShorts' || 'youtubeShorts' => 'YouTube',
        '2' || 'TikTok' || 'tiktok' => 'TikTok',
        '3' || 'Facebook' || 'facebook' => 'Facebook',
        _ => 'Open reel',
      };
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
        final writtenReviews = reviews
            .where((review) => review.kind == ReviewKind.written)
            .toList(growable: false);
        if (writtenReviews.isEmpty) {
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
            itemCount: writtenReviews.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox.shrink(),
            itemBuilder: (_, i) {
              if (i == writtenReviews.length) {
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
              return ReviewCard(review: writtenReviews[i]);
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
