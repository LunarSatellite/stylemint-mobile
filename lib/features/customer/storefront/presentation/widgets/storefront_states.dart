import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/mall_page_chrome.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/notifiers/storefront_paged_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A sentence for a failed storefront read.
String storefrontErrorBody(NetworkExceptions failure) => failure.isNoInternet
    ? 'Check your connection and try again.'
    : 'Something went wrong on our side. Please try again.';

/// A whole-page message (not found, failed to load) with a back button.
class StorefrontMessagePage extends StatelessWidget {
  const StorefrontMessagePage({
    required this.title,
    required this.icon,
    super.key,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s24,
                  vertical: DesignTokens.s48,
                ),
                child: MallEmptyState(
                  icon: icon,
                  title: title,
                  body: body,
                  actionLabel: actionLabel,
                  onAction: onAction,
                ),
              ),
            ),
          ),
          const MallBackButton(),
        ],
      ),
    );
  }
}

/// A tab's empty or failed state, with breathing room above.
class StorefrontSliverMessage extends StatelessWidget {
  const StorefrontSliverMessage({
    required this.title,
    super.key,
    this.icon,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  /// "Couldn't load" with a retry.
  factory StorefrontSliverMessage.failure(
    NetworkExceptions failure, {
    required VoidCallback onRetry,
    Key? key,
  }) => StorefrontSliverMessage(
    key: key,
    icon: Icons.cloud_off_rounded,
    title: "Couldn't load this",
    body: storefrontErrorBody(failure),
    actionLabel: 'Try again',
    onAction: onRetry,
  );

  final String title;
  final IconData? icon;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          DesignTokens.s24,
          DesignTokens.s40,
          DesignTokens.s24,
          DesignTokens.s24,
        ),
        child: MallEmptyState(
          icon: icon,
          title: title,
          body: body,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }
}

/// The end of a paged tab: spinner while more is coming, retry after a
/// failed page, breathing room at the end.
class StorefrontSliverPagingFooter<T> extends StatelessWidget {
  const StorefrontSliverPagingFooter({
    required this.state,
    required this.onRetry,
    super.key,
  });

  final StorefrontPagedLoaded<T> state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: MallPagingFooter(
        isLoading: state.isLoadingMore || state.canLoadMore,
        failed: state.loadMoreFailed,
        onRetry: onRetry,
      ),
    );
  }
}

/// A padded section title for a tab.
class StorefrontSliverHeader extends StatelessWidget {
  const StorefrontSliverHeader({
    required this.title,
    super.key,
    this.eyebrow,
    this.subtitle,
    this.onSeeAll,
    this.topPadding = DesignTokens.s24,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final VoidCallback? onSeeAll;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: topPadding),
        child: MallSectionHeader(
          title: title,
          eyebrow: eyebrow,
          subtitle: subtitle,
          onSeeAll: onSeeAll,
        ),
      ),
    );
  }
}

/// A horizontally scrolling row of chips with page gutters.
class StorefrontChipRow extends StatelessWidget {
  const StorefrontChipRow({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: DesignTokens.s16,
      ),
      child: Row(
        children: [
          for (final (index, chip) in children.indexed) ...[
            if (index > 0) const SizedBox(width: DesignTokens.s8),
            chip,
          ],
        ],
      ),
    );
  }
}
