import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/search_suggestions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/search_suggest_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_feed_view.dart'
    show isOfflineFailure;
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/discover_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

const TextStyle _titleStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 15,
  fontWeight: FontWeight.w500,
  height: 1.3,
  color: DesignTokens.textWhite,
);

const TextStyle _mutedStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 13,
  height: 1.4,
  color: DesignTokens.textMuted,
);

/// What shows while searching: recent searches for an empty field, grouped
/// live suggestions once two characters are typed.
class DiscoverSuggestionsPanel extends ConsumerWidget {
  const DiscoverSuggestionsPanel({
    required this.text,
    required this.onSubmit,
    required this.onOpen,
    super.key,
  });

  /// The field's current text.
  final String text;

  /// Runs a full search for a term.
  final ValueChanged<String> onSubmit;

  /// Opens the app location of a tapped suggestion.
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typed = text.trim();
    if (typed.isEmpty) return _RecentSearches(onSubmit: onSubmit);

    final state = ref.watch(searchSuggestNotifierProvider);
    final suggestions = switch (state) {
      SuggestLoaded(:final suggestions) => suggestions,
      SuggestLoading(:final previous) => previous,
      _ => null,
    };
    final List<Widget> body;
    if (normalizeSuggestQuery(typed).length < minSuggestQueryLength) {
      body = const [_Hint('Keep typing to see suggestions')];
    } else if (state case SuggestFailure(:final failure)) {
      body = [
        _SuggestError(
          offline: isOfflineFailure(failure),
          onRetry: ref.read(searchSuggestNotifierProvider.notifier).retry,
        ),
      ];
    } else if (state is SuggestIdle) {
      body = const [];
    } else if (suggestions == null ||
        (suggestions.isEmpty && state is SuggestLoading)) {
      body = const [_SuggestSkeleton()];
    } else if (suggestions.isEmpty) {
      body = const [_Hint('No quick matches. Search to see every result.')];
    } else {
      body = _groups(suggestions);
    }

    return ListView(
      key: const ValueKey('discover-suggestions'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        bottom: DesignTokens.s24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _SuggestionRow(
          key: const ValueKey('discover-search-for'),
          leading: const _IconDisc(Icons.search_rounded),
          title: 'Search for "$typed"',
          onTap: () => onSubmit(typed),
        ),
        ...body,
      ],
    );
  }

  List<Widget> _groups(SearchSuggestions suggestions) => [
    if (suggestions.products.isNotEmpty) ...[
      const _GroupHeader('Products'),
      for (final product in suggestions.products)
        _SuggestionRow(
          key: ValueKey('suggest-product-${product.id}'),
          leading: _Thumb(seed: product.id, monogram: product.name),
          title: product.name,
          subtitle: switch (product.price) {
            final price? => formatMoney(price, decimalDigits: 0),
            null => null,
          },
          onTap: () => onOpen(MallRoutes.product(product.id)),
        ),
    ],
    if (suggestions.brands.isNotEmpty) ...[
      const _GroupHeader('Brands'),
      for (final brand in suggestions.brands)
        _SuggestionRow(
          key: ValueKey('suggest-brand-${brand.vendorAccountId}'),
          leading: MallAvatar(
            name: brand.name,
            imageUrl: brand.logoUrl,
          ),
          title: brand.name,
          verified: brand.isVerified,
          subtitle: 'Brand',
          onTap: () =>
              onOpen(MallRoutes.brand(brand.vendorAccountId, brand.name)),
        ),
    ],
    if (suggestions.creators.isNotEmpty) ...[
      const _GroupHeader('Creators'),
      for (final creator in suggestions.creators)
        _SuggestionRow(
          key: ValueKey('suggest-creator-${creator.accountId}'),
          leading: MallAvatar(
            name: creator.displayName,
            imageUrl: creator.avatarUrl,
          ),
          title: creator.displayName,
          verified: creator.isVerified,
          subtitle: creator.handle == null ? 'Creator' : '@${creator.handle}',
          onTap: () => onOpen(MallRoutes.creator(creator.accountId)),
        ),
    ],
    if (suggestions.categories.isNotEmpty) ...[
      const _GroupHeader('Categories'),
      for (final category in suggestions.categories)
        _SuggestionRow(
          key: ValueKey('suggest-category-${category.slug ?? category.id}'),
          leading: const _IconDisc(Icons.grid_view_rounded),
          title: category.name,
          subtitle: 'Category',
          onTap: () => onOpen(
            MallRoutes.category(
              HomeCategory(
                id: category.id,
                slug: category.slug ?? '',
                name: category.name,
              ),
            ),
          ),
        ),
    ],
    if (suggestions.hashtags.isNotEmpty) ...[
      const _GroupHeader('Hashtags'),
      for (final hashtag in suggestions.hashtags)
        _SuggestionRow(
          key: ValueKey('suggest-hashtag-${hashtag.tag}'),
          leading: const _IconDisc(Icons.tag_rounded),
          title: '#${hashtag.tag}',
          subtitle: switch (hashtag.usageCount) {
            <= 0 => null,
            1 => '1 post',
            final count => '$count posts',
          },
          onTap: () => onOpen(
            '${RouteNames.searchResults}'
            '?q=${Uri.encodeComponent(hashtag.tag)}',
          ),
        ),
    ],
  ];
}

class _RecentSearches extends ConsumerWidget {
  const _RecentSearches({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentSearchesProvider);
    final notifier = ref.read(recentSearchesProvider.notifier);
    final bottom = DesignTokens.s24 + MediaQuery.paddingOf(context).bottom;
    if (recents.isEmpty) {
      return ListView(
        key: const ValueKey('discover-recent-empty'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          DesignTokens.s24,
          DesignTokens.s32,
          DesignTokens.s24,
          bottom,
        ),
        children: const [
          MallEmptyState(
            icon: Icons.search_rounded,
            title: 'Find your next favourite',
            body:
                'Search products, brands, creators, categories and #hashtags.',
          ),
        ],
      );
    }
    return ListView(
      key: const ValueKey('discover-recent'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(bottom: bottom),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            DesignTokens.s16,
            DesignTokens.s8,
            DesignTokens.s4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'RECENT SEARCHES',
                    style: DesignTokens.eyebrow.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ),
              ),
              TextButton(
                key: const ValueKey('discover-recent-clear'),
                onPressed: () => unawaited(notifier.clear()),
                style: TextButton.styleFrom(
                  foregroundColor: DesignTokens.textLight,
                ),
                child: const Text('Clear all'),
              ),
            ],
          ),
        ),
        for (final term in recents)
          Row(
            key: ValueKey('discover-recent-$term'),
            children: [
              Expanded(
                child: _SuggestionRow(
                  leading: const _IconDisc(Icons.history_rounded),
                  title: term,
                  onTap: () => onSubmit(term),
                ),
              ),
              IconButton(
                tooltip: 'Remove $term',
                color: DesignTokens.textMuted,
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => unawaited(notifier.remove(term)),
              ),
            ],
          ),
      ],
    );
  }
}

/// One tappable suggestion: leading visual, title (with a verified tick) and
/// an optional kind or detail line. At least 56dp tall.
class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.leading,
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.verified = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool verified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: [title, if (verified) 'verified', ?subtitle].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16,
              vertical: DesignTokens.s8,
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _titleStyle,
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: DesignTokens.s4),
                            const MallVerifiedBadge(size: 14),
                          ],
                        ],
                      ),
                      if (subtitle case final detail?)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _mutedStyle,
                        ),
                    ],
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

/// The mark beside a product suggestion.
///
/// It used to be the product's photo, which the Mall does not show outside
/// product detail; it is the tile's own tonal ground now, seeded from the
/// same product id, so a product wears the same face in the suggestion list
/// as on the tile the list opens.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.seed, this.monogram});

  final String seed;
  final String? monogram;

  @override
  Widget build(BuildContext context) {
    final letter = monogram?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
      child: SizedBox(
        width: 40,
        height: 50,
        child: MallTypeGround(
          seed: seed,
          monogram: letter == null || letter.isEmpty
              ? null
              : letter[0].toUpperCase(),
        ),
      ),
    );
  }
}

class _IconDisc extends StatelessWidget {
  const _IconDisc(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DesignTokens.surfaceRaised,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(
        dimension: 40,
        child: Icon(icon, size: 20, color: DesignTokens.textLight),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DesignTokens.s16,
        DesignTokens.s20,
        DesignTokens.s16,
        DesignTokens.s4,
      ),
      child: Semantics(
        header: true,
        child: Text(
          label.toUpperCase(),
          style: DesignTokens.eyebrow.copyWith(color: DesignTokens.textMuted),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Text(message, style: _mutedStyle),
    );
  }
}

class _SuggestError extends StatelessWidget {
  const _SuggestError({required this.offline, required this.onRetry});

  final bool offline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s8,
        DesignTokens.s8,
      ),
      child: Row(
        children: [
          Icon(
            offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            size: 20,
            color: DesignTokens.textMuted,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Text(
              offline
                  ? "You're offline. Suggestions return when you reconnect."
                  : "Suggestions aren't available right now.",
              style: _mutedStyle,
            ),
          ),
          TextButton(
            key: const ValueKey('discover-suggest-retry'),
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.textLight,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SuggestSkeleton extends StatelessWidget {
  const _SuggestSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s8,
              ),
              child: Row(
                children: [
                  SmSkeleton.circle(diameter: 40),
                  SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SmSkeleton.line(width: 160),
                        SizedBox(height: 6),
                        SmSkeleton.line(width: 90, height: 10),
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
