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

// Number of categories shown inline before showing "+N more" pill.
const int _kCategoryPreviewCount = 7;

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
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s16,
                0,
              ),
              child: Text('Search', style: DesignTokens.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: _SearchBar(),
            ),
            Expanded(
              child: state.when(
                initial: _loader,
                loadInProgress: _loader,
                loadSuccess: (data) => _DiscoverBody(data: data),
                loadFailure: (failure) => SmErrorView(
                  message: 'Failed to load Discover.',
                  onRetry: () => ref
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

// ─── SEARCH BAR ───────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    context.push('${RouteNames.searchResults}?q=${Uri.encodeComponent(q)}');
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite),
      decoration: InputDecoration(
        hintText: 'Search Products, Brands, Creators...',
        hintStyle: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.inputFieldPlaceholder,
        ),
        suffixIcon: const Icon(Icons.search, color: DesignTokens.iconLight),
        filled: true,
        fillColor: DesignTokens.inputFieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
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
      textInputAction: TextInputAction.search,
      onSubmitted: _submit,
    );
  }
}

// ─── DISCOVER BODY ────────────────────────────────────────────────────────────
class _DiscoverBody extends StatelessWidget {
  const _DiscoverBody({required this.data});

  final DiscoverData data;

  @override
  Widget build(BuildContext context) {
    final extraCategories = data.categories.length > _kCategoryPreviewCount
        ? data.categories.length - _kCategoryPreviewCount
        : 0;
    final visibleCategories = data.categories.length > _kCategoryPreviewCount
        ? data.categories.sublist(0, _kCategoryPreviewCount)
        : data.categories;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s24,
      ),
      children: [
        // ── Popular Searches ─────────────────────────────────────────────
        if (data.popularSearches.isNotEmpty) ...[
          const _SectionHeader('Popular Searches'),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              for (final term in data.popularSearches)
                _HashtagPill(
                  label: term.startsWith('#') ? term : '#$term',
                  onTap: () => context.push(
                    '${RouteNames.searchResults}?q=${Uri.encodeComponent(term.replaceAll('#', ''))}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),
        ],

        // ── Browse by Category ────────────────────────────────────────────
        if (data.categories.isNotEmpty) ...[
          const _SectionHeader('Browse by Category'),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              for (final cat in visibleCategories)
                _CategoryPill(
                  label: '${cat.emoji} ${cat.label}'.trim(),
                  onTap: () => context.push(
                    RouteNames.searchCategory.replaceFirst(
                          ':categoryId',
                          cat.id,
                        ) +
                        '?label=${Uri.encodeComponent(cat.label)}',
                  ),
                ),
              if (extraCategories > 0)
                _MorePill(
                  count: extraCategories,
                  onTap: () => _showMoreCategories(context, data.categories),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),
        ],

        // ── Trending Now ──────────────────────────────────────────────────
        if (data.trending.isNotEmpty) ...[
          const _SectionHeader('Trending Now 🔥'),
          for (final p in data.trending.take(2)) ...[
            TrendingProductCard(
              product: p,
              onTap: () => context.push(
                RouteNames.productDetail.replaceFirst(':productId', p.id),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
          ],
          Center(
            child: TextButton(
              onPressed: () => context.push(RouteNames.searchTrending),
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

        // ── Top Creators ──────────────────────────────────────────────────
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

  void _showMoreCategories(BuildContext context, List<DiscoverCategory> all) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreCategoriesSheet(
        categories: all,
        onSelect: (cat) {
          Navigator.pop(context);
          context.push(
            RouteNames.searchCategory.replaceFirst(':categoryId', cat.id) +
                '?label=${Uri.encodeComponent(cat.label)}',
          );
        },
      ),
    );
  }
}

// ─── SECTION HEADER ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Text(
        title,
        style: DesignTokens.mediumSemibold.copyWith(
          color: DesignTokens.textWhite,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── HASHTAG PILL ─────────────────────────────────────────────────────────────
class _HashtagPill extends StatelessWidget {
  const _HashtagPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: DesignTokens.borderDefault, width: 1),
        ),
        child: Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── CATEGORY PILL ────────────────────────────────────────────────────────────
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: DesignTokens.borderDefault, width: 1),
        ),
        child: Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textWhite,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── +N MORE PILL ─────────────────────────────────────────────────────────────
class _MorePill extends StatelessWidget {
  const _MorePill({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: DesignTokens.primaryGreenLight,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '+$count more',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.primaryGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── MORE CATEGORIES BOTTOM SHEET ─────────────────────────────────────────────
class _MoreCategoriesSheet extends StatelessWidget {
  const _MoreCategoriesSheet({
    required this.categories,
    required this.onSelect,
  });

  final List<DiscoverCategory> categories;
  final ValueChanged<DiscoverCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.88,
      expand: false,
      builder: (_, controller) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: DesignTokens.bgAppBody,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 14),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title + close
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'More Categories',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: DesignTokens.textWhite,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable category grid
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Wrap(
                    spacing: DesignTokens.s8,
                    runSpacing: DesignTokens.s12,
                    children: [
                      for (final cat in categories)
                        _CategoryPill(
                          label: '${cat.emoji} ${cat.label}'.trim(),
                          onTap: () => onSelect(cat),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
