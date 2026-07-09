import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/review_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TagProductsScreen extends ConsumerStatefulWidget {
  const TagProductsScreen({super.key});

  @override
  ConsumerState<TagProductsScreen> createState() => _TagProductsScreenState();
}

class _TagProductsScreenState extends ConsumerState<TagProductsScreen> {
  final _searchController = TextEditingController();
  final _taggedProducts = <String, TaggedProductForImport>{};
  bool _potentialEarningsExpanded = false;
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

  void _toggleProduct(TaggedProductForImport product) {
    setState(() {
      if (_taggedProducts.containsKey(product.productId)) {
        _taggedProducts.remove(product.productId);
      } else {
        _taggedProducts[product.productId] = product;
      }
    });
  }

  int get _potentialEarnings => _taggedProducts.values
      .map((p) => (p.price.amount * 0.10).toInt())
      .fold(0, (a, b) => a + b);

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      final thousands = amount ~/ 1000;
      final remainder = amount % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return amount.toString();
  }

  Future<void> _showSearchSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SearchSheet(
        taggedProductIds: _taggedProducts.keys.toSet(),
        onToggle: _toggleProduct,
      ),
    );
    if (mounted) {
      ref.read(productSearchNotifierProvider.notifier).search('');
    }
  }

  void _showTaggedProductsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaggedProductsSheet(
        taggedProducts: _taggedProducts.values.toList(),
        onUntag: (product) {
          _toggleProduct(product);
        },
      ),
    );
  }

  void _handleContinue() {
    if (_reel != null) {
      ref.read(reelImportNotifierProvider.notifier).importReel(_reel!);
    }
    context.push(
      RouteNames.reelImportReview,
      extra: ReviewReelArgs(
        reel: _reel,
        taggedProducts: _taggedProducts.values.toList(growable: false),
        potentialEarningsPerSale: _potentialEarnings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(productSearchNotifierProvider);
    final taggedList = _taggedProducts.values.toList();

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
          // ── Sticky header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16, 0, DesignTokens.s16, DesignTokens.s12,
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
                // Potential earnings (shown when any product is tagged)
                if (_taggedProducts.isNotEmpty) ...[
                  _PotentialEarningsCard(
                    amount: _formatAmount(_potentialEarnings),
                    isExpanded: _potentialEarningsExpanded,
                    onToggle: () => setState(
                      () => _potentialEarningsExpanded = !_potentialEarningsExpanded,
                    ),
                    taggedProducts: _taggedProducts.values.toList(),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                ],
                // Search bar — taps open the search sheet
                GestureDetector(
                  onTap: _showSearchSheet,
                  child: Container(
                    decoration: BoxDecoration(
                      color: DesignTokens.bgAppBody,
                      borderRadius: BorderRadius.circular(DesignTokens.s12),
                      border: Border.all(color: DesignTokens.borderDefault),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s4,
                    ),
                    child: AbsorbPointer(
                      child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            readOnly: true,
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
                  ),
                ),
              ],
            ),
          ),

          // ── Product list ────────────────────────────────────────────────
          Expanded(
            child: searchState.when(
              initial: () => const SizedBox.shrink(),
              loadInProgress: () => const Center(
                child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
              ),
              loadSuccess: (products) {
                final untagged = products
                    .where((p) => !_taggedProducts.containsKey(p.productId))
                    .toList();
                if (untagged.isEmpty) {
                  return Center(
                    child: Text(
                      'All products tagged!',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16, 0, DesignTokens.s16, DesignTokens.s32,
                  ),
                  itemCount: untagged.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: DesignTokens.s12),
                        child: Text(
                          'Suggested Products (Based on your reel)',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                      );
                    }
                    final product = untagged[i - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
                      child: _ProductCard(
                        product: product,
                        onTagTap: () => _toggleProduct(product),
                      ),
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

          // ── View Tagged Products bar ─────────────────────────────────────
          if (taggedList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16, 0, DesignTokens.s16, DesignTokens.s8,
              ),
              child: _ViewTaggedProductsBar(
                products: taggedList,
                onTap: _showTaggedProductsSheet,
              ),
            ),

          // ── Continue button ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16, DesignTokens.s8,
              DesignTokens.s16, DesignTokens.s24,
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

// ── Potential earnings card ───────────────────────────────────────────────────

class _PotentialEarningsCard extends StatelessWidget {
  const _PotentialEarningsCard({
    required this.amount,
    required this.isExpanded,
    required this.onToggle,
    required this.taggedProducts,
  });

  final String amount;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<TaggedProductForImport> taggedProducts;

  static const _projectedSales = 50;

  String _fmt(int n) {
    if (n >= 1000) return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final n = taggedProducts.length;
    final salesPerProduct = n > 0 ? _projectedSales ~/ n : 0;
    final remainder = n > 0 ? _projectedSales % n : 0;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Potential Earnings: Rs $amount',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: DesignTokens.textMuted,
                  size: 22,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: DesignTokens.s12),
              Text(
                'If this reel generates $_projectedSales sales:',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              for (int i = 0; i < taggedProducts.length; i++) ...[
                _BreakdownRow(
                  product: taggedProducts[i],
                  qty: salesPerProduct + (i < remainder ? 1 : 0),
                  fmt: _fmt,
                ),
                if (i < taggedProducts.length - 1)
                  const SizedBox(height: DesignTokens.s8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.product,
    required this.qty,
    required this.fmt,
  });

  final TaggedProductForImport product;
  final int qty;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final commission = (product.price.amount * 0.10).toInt();
    final total = qty * commission;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            product.productName,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textWhite,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        Text(
          '$qty * Rs ${fmt(commission)} = Rs ${fmt(total)}',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
      ],
    );
  }
}

// ── View tagged products bar ──────────────────────────────────────────────────

class _ViewTaggedProductsBar extends StatelessWidget {
  const _ViewTaggedProductsBar({required this.products, required this.onTap});

  final List<TaggedProductForImport> products;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const thumbSize = 36.0;
    const overlap = 10.0;
    final shown = products.take(4).toList();
    final stackWidth = thumbSize + (shown.length - 1) * (thumbSize - overlap);

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        border: Border.all(color: DesignTokens.primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          // Stacked thumbnails
          SizedBox(
            width: stackWidth,
            height: thumbSize,
            child: Stack(
              children: [
                for (int i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * (thumbSize - overlap),
                    child: _ProductThumb(product: shown[i], size: thumbSize),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          // Label + count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'View Tagged Products',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
                Text(
                  '${products.length}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Green arrow button
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: DesignTokens.primaryGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Search bottom sheet ───────────────────────────────────────────────────────

class _SearchSheet extends ConsumerStatefulWidget {
  const _SearchSheet({
    required this.taggedProductIds,
    required this.onToggle,
  });

  final Set<String> taggedProductIds;
  final ValueChanged<TaggedProductForImport> onToggle;

  @override
  ConsumerState<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<_SearchSheet> {
  final _controller = TextEditingController();
  late final Set<String> _localTaggedIds;

  @override
  void initState() {
    super.initState();
    _localTaggedIds = Set.from(widget.taggedProductIds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productSearchNotifierProvider.notifier).search('');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleToggle(TaggedProductForImport product) {
    widget.onToggle(product);
    setState(() {
      if (_localTaggedIds.contains(product.productId)) {
        _localTaggedIds.remove(product.productId);
      } else {
        _localTaggedIds.add(product.productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(productSearchNotifierProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DesignTokens.s12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Search and Tag Products',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close_rounded,
                      color: DesignTokens.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            // Search field with green border
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(DesignTokens.s12),
                  border: Border.all(color: DesignTokens.primaryGreen),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
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
                        onChanged: (v) => ref
                            .read(productSearchNotifierProvider.notifier)
                            .search(v),
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
            ),
            const SizedBox(height: DesignTokens.s12),
            // Results
            Expanded(
              child: searchState.when(
                initial: () => const SizedBox.shrink(),
                loadInProgress: () => const Center(
                  child: CircularProgressIndicator(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
                loadSuccess: (products) {
                  final visible = products
                      .where((p) => !_localTaggedIds.contains(p.productId))
                      .toList();
                  if (visible.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/Crossed.png',
                            width: 80,
                            height: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Oops! No Results Found',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.textWhite,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "We couldn't find what you were looking for.\nTry searching again",
                            textAlign: TextAlign.center,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.s16, 0, DesignTokens.s16, DesignTokens.s24,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
                      child: _ProductCard(
                        product: visible[i],
                        onTagTap: () => _handleToggle(visible[i]),
                      ),
                    ),
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
          ],
        ),
      ),
    );
  }
}

// ── Product thumb ─────────────────────────────────────────────────────────────

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product, required this.size});

  final TaggedProductForImport product;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DesignTokens.bgAppBodyLight,
        border: Border.all(color: DesignTokens.bgAppBody, width: 2),
      ),
      child: product.imageUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.image_outlined, color: DesignTokens.textMuted, size: 16),
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
            child: reel.thumbnailUrl.isNotEmpty
                ? Image.network(
                    reel.thumbnailUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                  )
                : _thumbPlaceholder(),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reel.caption.isNotEmpty
                      ? reel.caption
                      : 'New Year calls for rich, delicious cakes to celebrate with your near an...',
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
                const SizedBox(height: 6),
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

  Widget _thumbPlaceholder() => Container(
        width: 72,
        height: 72,
        color: DesignTokens.bgAppBodyLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.play_circle_outline_rounded,
          color: DesignTokens.textMuted,
          size: 28,
        ),
      );
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTagTap,
  });

  final TaggedProductForImport product;
  final VoidCallback onTagTap;

  String _commissionLabel() {
    const pct = 10;
    final amount = (product.price.amount * pct / 100).toStringAsFixed(0);
    if (product.price.amount > 5000) {
      return '$pct% commission (Rs $amount per sale)';
    }
    return 'Rs $amount per sale';
  }

  String _formattedPrice() {
    final amt = product.price.amount.toStringAsFixed(0);
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
                      errorBuilder: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
            Positioned(
              bottom: 4,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onTagTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: DesignTokens.s4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tag',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.add, size: 13, color: Colors.white),
                      ],
                    ),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                  color: const Color(0xFFBAE6FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _commissionLabel(),
                  style: DesignTokens.smallRegular.copyWith(
                    color: const Color(0xFF075985),
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

  Widget _imgPlaceholder() => Container(
        width: 110,
        height: 110,
        color: DesignTokens.bgAppBodyLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_outlined,
          color: DesignTokens.textMuted,
          size: 32,
        ),
      );
}

// ── Tagged products bottom sheet ──────────────────────────────────────────────

class TaggedProductsSheet extends StatefulWidget {
  const TaggedProductsSheet({
    super.key,
    required this.taggedProducts,
    required this.onUntag,
    this.allowUntag = true,
  });

  final List<TaggedProductForImport> taggedProducts;
  final ValueChanged<TaggedProductForImport> onUntag;
  final bool allowUntag;

  @override
  State<TaggedProductsSheet> createState() => _TaggedProductsSheetState();
}

class _TaggedProductsSheetState extends State<TaggedProductsSheet> {
  late final List<TaggedProductForImport> _products;

  @override
  void initState() {
    super.initState();
    _products = List.from(widget.taggedProducts);
  }

  void _untag(TaggedProductForImport product) {
    widget.onUntag(product);
    setState(() => _products.remove(product));
    if (_products.isEmpty) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: DesignTokens.s12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: Row(
                children: [
                  Text(
                    'Your Tagged Products(${_products.length})',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: DesignTokens.textLight, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            // Product list
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16, 0, DesignTokens.s16, DesignTokens.s24,
                ),
                itemCount: _products.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.s16),
                  child: _SheetProductRow(
                    product: _products[i],
                    onUntag: () => _untag(_products[i]),
                    allowUntag: widget.allowUntag,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetProductRow extends StatelessWidget {
  const _SheetProductRow({
    required this.product,
    required this.onUntag,
    this.allowUntag = true,
  });

  final TaggedProductForImport product;
  final VoidCallback onUntag;
  final bool allowUntag;

  String _commissionLabel() {
    const pct = 10;
    final amount = (product.price.amount * pct / 100).toStringAsFixed(0);
    if (product.price.amount > 5000) {
      return '$pct% commission (Rs $amount per sale)';
    }
    return 'Rs $amount per sale';
  }

  String _formattedPrice() {
    final n = product.price.amount.toInt();
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail + Untag button
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s12),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            if (allowUntag)
              Positioned(
                bottom: DesignTokens.s8,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: onUntag,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: DesignTokens.s4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Untag',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(Icons.remove, size: 13, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: DesignTokens.s12),
        // Info
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
                maxLines: allowUntag ? 2 : null,
                overflow: allowUntag ? TextOverflow.ellipsis : null,
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
                  color: const Color(0xFFBAE6FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _commissionLabel(),
                  style: DesignTokens.smallRegular.copyWith(
                    color: const Color(0xFF075985),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: DesignTokens.s4),
          child: Icon(Icons.drag_indicator, color: DesignTokens.textMuted, size: 22),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        width: 90,
        height: 90,
        color: DesignTokens.bgAppBodyLight,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: DesignTokens.textMuted, size: 28),
      );
}
