import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/entities/creator_search_result.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/presentation/notifiers/creator_search_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Creator-facing search — distinct from the customer shopping [SearchScreen]
/// (trending hashtags/categories for browsing to buy). A creator searches
/// for a different reason: brands to partner with, products to make content
/// about, or other creators — so this defaults to Brands, not a shopping feed.
class CreatorSearchScreen extends ConsumerStatefulWidget {
  const CreatorSearchScreen({super.key});

  @override
  ConsumerState<CreatorSearchScreen> createState() => _CreatorSearchScreenState();
}

class _CreatorSearchScreenState extends ConsumerState<CreatorSearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _searchBrandProducts(String brandName) {
    _controller.text = brandName;
    final notifier = ref.read(creatorSearchNotifierProvider.notifier);
    notifier.setType(CreatorSearchType.products);
    notifier.onQueryChanged(brandName);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(creatorSearchNotifierProvider.notifier);
    final state = ref.watch(creatorSearchNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Search', style: DesignTokens.sectionInnerTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: DesignTokens.textWhite),
              onChanged: notifier.onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search brands, products, creators…',
                hintStyle: const TextStyle(color: DesignTokens.textMuted),
                filled: true,
                fillColor: DesignTokens.bgAppBodyLight,
                prefixIcon: const Icon(Icons.search_rounded,
                    color: DesignTokens.iconLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: Row(
              children: CreatorSearchType.values.map((type) {
                final selected = notifier.type == type;
                return Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.s8),
                  child: ChoiceChip(
                    label: Text(_label(type)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {});
                      notifier.setType(type);
                    },
                    selectedColor: DesignTokens.primaryGreen,
                    backgroundColor: DesignTokens.bgAppBodyLight,
                    labelStyle: TextStyle(
                      color: selected
                          ? DesignTokens.textDark
                          : DesignTokens.textWhite,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          Expanded(
            child: _Results(state: state, onBrandTap: _searchBrandProducts),
          ),
        ],
      ),
    );
  }

  String _label(CreatorSearchType type) => switch (type) {
        CreatorSearchType.brands => 'Brands',
        CreatorSearchType.products => 'Products',
        CreatorSearchType.creators => 'Creators',
      };
}

class _Results extends StatelessWidget {
  const _Results({required this.state, required this.onBrandTap});

  final CreatorSearchState state;
  final void Function(String brandName) onBrandTap;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      CreatorSearchIdle() => const _HintMessage(
          'Search for brands to partner with, products to feature, or other creators.'),
      CreatorSearchLoading() => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen)),
      CreatorSearchFailed(message: final m) => _HintMessage(m),
      CreatorSearchBrandsLoaded(results: final results) => results.isEmpty
          ? const _HintMessage('No brands found.')
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              itemCount: results.length,
              separatorBuilder: (_, _i) =>
                  const SizedBox(height: DesignTokens.s8),
              itemBuilder: (_, i) => _BrandTile(
                brand: results[i],
                onTap: () => onBrandTap(results[i].name),
              ),
            ),
      CreatorSearchProductsLoaded(results: final results) => results.isEmpty
          ? const _HintMessage('No products found.')
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: DesignTokens.s8,
                mainAxisSpacing: DesignTokens.s8,
                childAspectRatio: 0.75,
              ),
              itemCount: results.length,
              itemBuilder: (_, i) => _ProductTile(product: results[i]),
            ),
      CreatorSearchCreatorsLoaded(results: final results) => results.isEmpty
          ? const _HintMessage('No creators found.')
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              itemCount: results.length,
              separatorBuilder: (_, _i) =>
                  const SizedBox(height: DesignTokens.s8),
              itemBuilder: (_, i) => _CreatorTile(creator: results[i]),
            ),
    };
  }
}

class _HintMessage extends StatelessWidget {
  const _HintMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
        ),
      );
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.brand, required this.onTap});
  final SearchBrandResult brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: (brand.logoUrl?.isNotEmpty ?? false)
                    ? Image.network(brand.logoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, _e, _s) =>
                            const ColoredBox(color: DesignTokens.bgAppBody))
                    : const ColoredBox(color: DesignTokens.bgAppBody),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brand.name, style: DesignTokens.oneLinerSemibold),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    '${brand.productCount} products · ${brand.commissionRange} commission',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});
  final SearchProductResult product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        RouteNames.productDetail.replaceFirst(':productId', product.productId),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              child: product.heroImageUrl.isNotEmpty
                  ? Image.network(product.heroImageUrl,
                      fit: BoxFit.cover, width: double.infinity,
                      errorBuilder: (_, _e, _s) =>
                          const ColoredBox(color: DesignTokens.bgAppBodyLight))
                  : const ColoredBox(color: DesignTokens.bgAppBodyLight),
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.smallRegular),
          Text('${product.currency} ${product.price.toStringAsFixed(0)}',
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.primaryGreen)),
        ],
      ),
    );
  }
}

class _CreatorTile extends StatelessWidget {
  const _CreatorTile({required this.creator});
  final SearchCreatorResult creator;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        RouteNames.creatorProfile.replaceFirst(':accountId', creator.creatorProfileId),
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: (creator.avatarUrl?.isNotEmpty ?? false)
                    ? Image.network(creator.avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, _e, _s) =>
                            const ColoredBox(color: DesignTokens.bgAppBody))
                    : const ColoredBox(color: DesignTokens.bgAppBody),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(creator.displayName, style: DesignTokens.oneLinerSemibold),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    '@${creator.handle} · ${creator.followerCount} followers · ${creator.reelCount} reels',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
