import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/discover_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_creator_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/trending_product_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Discover/Search tab — search field plus popular searches, categories,
/// trending products and top creators (Figma "Search", node 9611-3671).
class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoverNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s16,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Search', style: DesignTokens.titleLarge),
                  Icon(Icons.tune_rounded, color: DesignTokens.iconWhite),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(DesignTokens.s16),
              child: _SearchField(),
            ),
            Expanded(
              child: state.when(
                initial: _loader,
                loadInProgress: _loader,
                loadSuccess: (data) => _DiscoverBody(data: data),
                loadFailure:
                    (failure) => SmErrorView(
                      message: 'Failed to load Discover.',
                      onRetry:
                          () =>
                              ref
                                  .read(discoverNotifierProvider.notifier)
                                  .fetchDiscover(),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite),
      decoration: InputDecoration(
        hintText: 'Search Products, Brands, Creators...',
        hintStyle: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.inputFieldPlaceholder,
        ),
        prefixIcon: const Icon(Icons.search, color: DesignTokens.iconLight),
        filled: true,
        fillColor: DesignTokens.inputFieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: const BorderSide(color: DesignTokens.primaryGreen),
        ),
      ),
      onSubmitted: (_) {
        /* TODO(discovery): run search → results screen */
      },
    );
  }
}

class _DiscoverBody extends StatelessWidget {
  const _DiscoverBody({required this.data});

  final DiscoverData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s24,
      ),
      children: [
        if (data.popularSearches.isNotEmpty) ...[
          const _SectionHeader('Popular Searches'),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              for (final term in data.popularSearches) _Pill(label: term),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),
        ],
        if (data.categories.isNotEmpty) ...[
          const _SectionHeader('Browse by Category'),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              for (final cat in data.categories)
                _Pill(label: '${cat.emoji} ${cat.label}'.trim()),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),
        ],
        if (data.trending.isNotEmpty) ...[
          const _SectionHeader('Trending Now 🔥'),
          for (final p in data.trending) ...[
            TrendingProductCard(
              product: p,
              onTap:
                  () => context.push(
                    '${RouteNames.productDetail}'.replaceFirst(
                      ':productId',
                      p.id,
                    ),
                  ),
            ),
            const SizedBox(height: DesignTokens.s12),
          ],
          Center(
            child: TextButton(
              onPressed: () {
                /* TODO(discovery): all trending screen */
              },
              child: Text(
                'View All Trending  →',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
        ],
        if (data.topCreators.isNotEmpty) ...[
          const _SectionHeader('Top Creators'),
          for (final creator in data.topCreators) ...[
            DiscoverCreatorCard(creator: creator),
            const SizedBox(height: DesignTokens.s12),
          ],
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Text(title, style: DesignTokens.sectionInnerTitle),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Text(
        label,
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textLight,
        ),
      ),
    );
  }
}
