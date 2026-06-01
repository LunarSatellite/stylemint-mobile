import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TagProductsScreen extends ConsumerStatefulWidget {
  const TagProductsScreen({super.key});

  @override
  ConsumerState<TagProductsScreen> createState() => _TagProductsScreenState();
}

class _TagProductsScreenState extends ConsumerState<TagProductsScreen> {
  final _searchController = TextEditingController();
  final _selectedIds = <String>{};
  String _caption = '';
  ImportableReel? _reel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reel = GoRouterState.of(context).extra as ImportableReel?;
      if (_reel != null) {
        _caption = _reel!.caption;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(productSearchNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Tag Products', style: DesignTokens.titleMedium),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: TextField(
              controller: _searchController,
              style: DesignTokens.bodyText,
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: DesignTokens.bodyText.copyWith(
                  color: DesignTokens.textMuted,
                ),
                filled: true,
                fillColor: DesignTokens.bgAppBody,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                ref
                    .read(productSearchNotifierProvider.notifier)
                    .search(value);
              },
            ),
          ),
          Expanded(child: _buildProductList(searchState)),
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  style: DesignTokens.primaryButtonStyle(),
                  onPressed: _handleTag,
                  child: Text(
                    'Tag ${_selectedIds.length} products',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductList(ProductSearchState searchState) {
    return searchState.when(
      initial: _empty,
      loadInProgress: _loader,
      loadSuccess: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Text(
              'No products found',
              style: DesignTokens.mediumRegular,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s8),
          itemBuilder: (_, i) {
            final product = products[i];
            final isSelected = _selectedIds.contains(product.productId);
            return ListTile(
              tileColor: DesignTokens.bgAppBody,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(product.imageUrl),
              ),
              title: Text(
                product.productName,
                style: DesignTokens.oneLinerSemibold,
              ),
              subtitle: Text(
                '${product.vendorName}  ·  NPR ${product.price.amount}',
                style: DesignTokens.smallRegular,
              ),
              trailing: Checkbox(
                value: isSelected,
                activeColor: DesignTokens.primaryGreen,
                onChanged: (val) => _toggleProduct(product.productId),
              ),
              onTap: () => _toggleProduct(product.productId),
            );
          },
        );
      },
      loadFailure: (failure) => const Center(
        child: Text(
          'Search failed',
          style: TextStyle(color: DesignTokens.colorError),
        ),
      ),
    );
  }

  void _toggleProduct(String productId) {
    setState(() {
      if (_selectedIds.contains(productId)) {
        _selectedIds.remove(productId);
      } else {
        _selectedIds.add(productId);
      }
    });
  }

  void _handleTag() {
    if (_reel != null) {
      ref.read(reelImportNotifierProvider.notifier).importReel(
        _reel!.platformPostId,
        _caption,
        _selectedIds.toList(growable: false),
      );
      context.pop();
    }
  }

  Widget _empty() => const Center(
    child: Text(
      'Search for products to tag',
      style: DesignTokens.mediumRegular,
    ),
  );

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
