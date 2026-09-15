import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/customer_returns_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/kathmandu_time.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/orders_load_error_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_status_pill.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "My returns" (`/orders/returns`): every return the buyer has submitted,
/// newest first, with cursor paging and pull-to-refresh.
class MyReturnsScreen extends ConsumerWidget {
  const MyReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myReturnsNotifierProvider);
    final notifier = ref.read(myReturnsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: DesignTokens.primaryGreen,
          onRefresh: notifier.refresh,
          child: state.when(
            initial: () => const _ReturnsSkeleton(),
            loadInProgress: () => const _ReturnsSkeleton(),
            loadFailure: (failure) => OrdersScrollableState(
              child: OrdersLoadErrorView(
                failure: failure,
                onRetry: notifier.load,
                subject: 'your returns',
              ),
            ),
            loadSuccess: (returns, nextCursor, isLoadingMore, loadMoreFailure) {
              if (returns.isEmpty) {
                return OrdersScrollableState(
                  child: MallEmptyState(
                    icon: Icons.assignment_return_outlined,
                    eyebrow: 'My returns',
                    title: 'No returns yet',
                    body:
                        'When you send an item back, you can follow the '
                        'seller’s decision and your refund here.',
                    actionLabel: 'View my orders',
                    onAction: () => context.push(RouteNames.orders),
                  ),
                );
              }
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsetsDirectional.fromSTEB(
                  DesignTokens.s16,
                  0,
                  DesignTokens.s16,
                  DesignTokens.s32,
                ),
                itemCount: returns.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) return const _ReturnsHeader();
                  if (index == returns.length + 1) {
                    return _ReturnsFooter(
                      hasMore: nextCursor != null,
                      isLoadingMore: isLoadingMore,
                      failure: loadMoreFailure,
                      onLoadMore: notifier.loadMore,
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.s12),
                    child: ReturnListTile(customerReturn: returns[index - 1]),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReturnsHeader extends StatelessWidget {
  const _ReturnsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: DesignTokens.s4,
        bottom: DesignTokens.s20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MallEyebrow('After your order'),
          const SizedBox(height: DesignTokens.s8),
          Semantics(
            header: true,
            child: const Text('My returns', style: DesignTokens.displayTitle),
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Follow each item you’ve sent back, from review to refund.',
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// One return row: thumbnail, product, quantity and reason, state pill and
/// submitted date. The whole row opens the return.
class ReturnListTile extends StatelessWidget {
  const ReturnListTile({required this.customerReturn, super.key});

  final CustomerReturn customerReturn;

  @override
  Widget build(BuildContext context) {
    final r = customerReturn;
    final variant = r.product.variantLabel?.trim();
    return Material(
      color: DesignTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          RouteNames.returnDetail.replaceFirst(':returnId', r.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                child: SizedBox(
                  width: 64,
                  height: 80,
                  child: MallNetworkImage(url: r.product.thumbnailUrl),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.product.title.isEmpty ? 'Item' : r.product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.mediumSemibold,
                    ),
                    if (variant != null && variant.isNotEmpty)
                      Text(
                        variant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.smallRegular,
                      ),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      'Qty ${r.quantity} · ${r.reason}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.smallDescription.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Wrap(
                      spacing: DesignTokens.s8,
                      runSpacing: DesignTokens.s4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ReturnStatusPill(status: r.status),
                        Text(
                          formatNptDate(r.submittedUtc),
                          style: DesignTokens.smallRegular,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsetsDirectional.only(start: DesignTokens.s4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: DesignTokens.iconLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnsFooter extends StatelessWidget {
  const _ReturnsFooter({
    required this.hasMore,
    required this.isLoadingMore,
    required this.failure,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final NetworkExceptions? failure;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: DesignTokens.s8,
          children: [
            Text(
              failure!.isNoInternet
                  ? 'You’re offline.'
                  : 'Couldn’t load more returns.',
              style: DesignTokens.smallRegular,
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  DesignTokens.minTouchTarget,
                  DesignTokens.minTouchTarget,
                ),
                foregroundColor: DesignTokens.primaryGreen,
              ),
              onPressed: onLoadMore,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.s16),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: DesignTokens.primaryGreen,
            ),
          ),
        ),
      );
    }
    if (hasMore) {
      // The footer is built only once it scrolls near the viewport, so
      // building it is the cue to fetch the next page.
      WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
    }
    return const SizedBox(height: DesignTokens.s24);
  }
}

class _ReturnsSkeleton extends StatelessWidget {
  const _ReturnsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading returns',
      liveRegion: true,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: [
          const SmSkeleton.line(width: 96, height: 10),
          const SizedBox(height: DesignTokens.s12),
          const SmSkeleton.line(width: 180, height: 28),
          const SizedBox(height: DesignTokens.s24),
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.s12),
              child: Row(
                children: [
                  SmSkeleton.box(width: 64, height: 80),
                  SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SmSkeleton.line(),
                        SizedBox(height: DesignTokens.s8),
                        SmSkeleton.line(width: 120, height: 10),
                        SizedBox(height: DesignTokens.s12),
                        SmSkeleton.line(width: 80, height: 18, radius: 9),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
