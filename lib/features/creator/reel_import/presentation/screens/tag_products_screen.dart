import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TagProductsScreen extends ConsumerStatefulWidget {
  const TagProductsScreen({super.key});

  @override
  ConsumerState<TagProductsScreen> createState() => _TagProductsScreenState();
}

class _TagProductsScreenState extends ConsumerState<TagProductsScreen> {
  final _searchController = TextEditingController();
  final _selectedIds = <String>{};
  ImportableReel? _reel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reel = GoRouterState.of(context).extra as ImportableReel?;
      setState(() {});
      ref.read(productSearchNotifierProvider.notifier).search('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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

  void _handleContinue() {
    if (_reel != null) {
      ref.read(reelImportNotifierProvider.notifier).importReel(
            _reel!.platformPostId,
            _reel!.caption,
            _selectedIds.toList(growable: false),
          );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reel published successfully!')),
    );
    context.go('/creator/home');
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(productSearchNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Tag Products', style: DesignTokens.titleMedium),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Reel preview + search (not scrollable) ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              0,
              DesignTokens.s16,
              DesignTokens.s12,
            ),
            child: Column(
              children: [
                if (_reel != null) ...[
                  _ReelPreviewCard(
                    reel: _reel!,
                    formatDuration: _formatDuration,
                  ),
                  const SizedBox(height: DesignTokens.s12),
                ],
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: DesignTokens.bgAppBody,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.s12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search products or brands....',
                            hintStyle: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: DesignTokens.s12,
                            ),
                          ),
                          onChanged: (value) => ref
                              .read(productSearchNotifierProvider.notifier)
                              .search(value),
                        ),
                      ),
                      const Icon(
                        Icons.search_rounded,
                        color: DesignTokens.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Product list (scrollable) ───────────────────────────────────
          Expanded(
            child: searchState.when(
              initial: () => const SizedBox.shrink(),
              loadInProgress: () => const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
              loadSuccess: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Text(
                      'No products found',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16,
                    0,
                    DesignTokens.s16,
                    DesignTokens.s32,
                  ),
                  itemCount: products.length + 1,
                  separatorBuilder: (_, _i) =>
                      const SizedBox(height: DesignTokens.s12),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.s4,
                        ),
                        child: Text(
                          'Suggested Products (Based on your reel)',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                      );
                    }
                    final product = products[i - 1];
                    return _ProductCard(
                      product: product,
                      isTagged: _selectedIds.contains(product.productId),
                      onTagTap: () => _toggleProduct(product.productId),
                    );
                  },
                );
              },
              loadFailure: (_) => Center(
                child: Text(
                  'Failed to load products',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
            ),
          ),

          // ── Continue button ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s24,
            ),
            color: DesignTokens.bgAppFoundation,
            child: SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: DesignTokens.primaryButtonStyle(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continue to Review'),
                    SizedBox(width: DesignTokens.s8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reel preview card ─────────────────────────────────────────────────────────

class _ReelPreviewCard extends StatelessWidget {
  const _ReelPreviewCard({
    required this.reel,
    required this.formatDuration,
  });

  final ImportableReel reel;
  final String Function(int) formatDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: Container(
              width: 64,
              height: 64,
              color: DesignTokens.bgAppBodyLight,
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_circle_outline_rounded,
                color: DesignTokens.textMuted,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reel.caption.isNotEmpty
                      ? reel.caption
                      : 'Imported Reel',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Duration ${formatDuration(reel.videoDuration)}'
                  ' · ${reel.platform.displayName}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
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

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isTagged,
    required this.onTagTap,
  });

  final TaggedProductForImport product;
  final bool isTagged;
  final VoidCallback onTagTap;

  String _commission() {
    final amount = (product.price.amount * 0.10).toStringAsFixed(0);
    return 'Rs $amount per sale';
  }

  String _formattedPrice() {
    final amt = product.price.amount.toStringAsFixed(0);
    // Add thousands separator
    final n = int.tryParse(amt) ?? 0;
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(0)},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return amt;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Thumbnail + Tag button ─────────────────────────────────────
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s12),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      color: DesignTokens.bgAppBodyLight,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        color: DesignTokens.textMuted,
                        size: 32,
                      ),
                    ),
            ),
            Positioned(
              bottom: DesignTokens.s8,
              left: DesignTokens.s8,
              child: GestureDetector(
                onTap: onTagTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s12,
                    vertical: DesignTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: isTagged
                        ? DesignTokens.primaryGreen
                        : Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tag',
                        style: DesignTokens.smallRegular.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        isTagged ? Icons.check : Icons.add,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: DesignTokens.s12),

        // ── Product info ───────────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DesignTokens.s4),
              Text(
                product.productName,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                '${_formattedPrice()} · ${product.vendorName}',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s8,
                  vertical: DesignTokens.s4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2D3A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _commission(),
                  style: DesignTokens.smallRegular.copyWith(
                    color: const Color(0xFF4DD8C0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
