import 'dart:ui';

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
  final _taggedProducts = <String, TaggedProductForImport>{};
  bool _potentialEarningsExpanded = false;
  ImportableReel? _reel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reel = GoRouterState.of(context).extra as ImportableReel?;
      setState(() {});
      final reel = _reel;
      if (reel != null) {
        ref.read(suggestedProductsNotifierProvider.notifier).loadSuggestions(
          platform: reel.platform,
          externalId: reel.platformPostId,
        );
      }
    });
  }

  @override
  void dispose() {
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
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, anim, secAnim) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Blurred backdrop covering the whole screen
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              // The actual search bar, anchored to the top of the screen
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: _SearchSheet(onSubmit: _toggleProduct),
                ),
              ),
            ],
          ),
        ),
        transitionsBuilder: (ctx, anim, secAnim, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
      ),
    );
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
    final suggestedState = ref.watch(suggestedProductsNotifierProvider);
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
      body: SafeArea(
        child: Column(
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
                    height: DesignTokens.inputHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.bgAppBody,
                      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                      border: Border.all(color: DesignTokens.borderDefault),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Search products or brands...',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
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
              ],
            ),
          ),

          // ── Suggested Products section ────────────────────────────────────────────
          Expanded(
            child: switch (suggestedState) {
              SuggestedProductsInitial() => _SuggestedProductsBody(
                products: const [],
                onTagTap: _toggleProduct,
                originalCount: 0,
                hasAnyTagged: _taggedProducts.isNotEmpty,
              ),
              SuggestedProductsLoadInProgress() => _SuggestedProductsBody(
                products: const [],
                onTagTap: _toggleProduct,
                isLoading: true,
                originalCount: 0,
                hasAnyTagged: _taggedProducts.isNotEmpty,
              ),
              SuggestedProductsLoadSuccess(:final products) => () {
                final untagged = products
                    .where((p) => !_taggedProducts.containsKey(p.productId))
                    .toList();
                return _SuggestedProductsBody(
                  products: untagged,
                  onTagTap: _toggleProduct,
                  originalCount: products.length,
                  hasAnyTagged: _taggedProducts.isNotEmpty,
                );
              }(),
              SuggestedProductsLoadFailure() => _SuggestedProductsBody(
                products: const [],
                onTagTap: _toggleProduct,
                isLoading: false,
                hasFailure: true,
                originalCount: 0,
                hasAnyTagged: _taggedProducts.isNotEmpty,
              ),
            },
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
                    'Est. Potential Earnings: ~Rs $amount',
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
    // Estimate only — real commission is a partnership term confirmed
    // server-side when the tag is submitted, not known at search time.
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
          '$qty * ~Rs ${fmt(commission)} = ~Rs ${fmt(total)} (est.)',
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

class _SuggestedProductsBody extends StatelessWidget {
  const _SuggestedProductsBody({
    required this.products,
    required this.onTagTap,
    required this.originalCount,
    required this.hasAnyTagged,
    this.isLoading = false,
    this.hasFailure = false,
  });

  final List<TaggedProductForImport> products;
  final ValueChanged<TaggedProductForImport> onTagTap;
  final int originalCount;
  final bool hasAnyTagged;
  final bool isLoading;
  final bool hasFailure;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16, 0, DesignTokens.s16, DesignTokens.s32,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s12),
          child: Text(
            'Suggested Products (Based on your reel)',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.s24),
            child: Center(
              child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
            ),
          )
        else if (hasFailure)
          const _EmptyProductsState(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn’t load products',
            subtitle: 'Check your connection and try again.',
          )
        else if (products.isEmpty && originalCount == 0)
          const _EmptyProductsState(
            icon: Icons.shopping_bag_outlined,
            title: 'No suggested products',
            subtitle: 'We don’t have product suggestions for this reel yet.',
          )
        else if (products.isEmpty && hasAnyTagged)
          const _EmptyProductsState(
            icon: Icons.check_circle_outline_rounded,
            title: 'You’ve tagged all the suggested products',
            subtitle: 'You can still search above to tag more products.',
          )
        else
          for (int i = 0; i < products.length; i++) ...[
            _ProductCard(
              product: products[i],
              onTagTap: () => onTagTap(products[i]),
            ),
            if (i < products.length - 1)
              const SizedBox(height: DesignTokens.s16),
          ],
      ],
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s24),
      child: Column(
        children: [
          Icon(icon, size: 56, color: DesignTokens.textMuted),
          const SizedBox(height: DesignTokens.s12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            subtitle,
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
}

class _SearchSheet extends ConsumerStatefulWidget {
  const _SearchSheet({this.onSubmit});

  /// Called when the user picks a product from the search results. The
  /// parent typically uses this to tag the product on the in-progress reel.
  final void Function(TaggedProductForImport product)? onSubmit;

  @override
  ConsumerState<_SearchSheet> createState() => _SearchSheetState();
}
class _SearchSheetState extends ConsumerState<_SearchSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(productSearchSheetNotifierProvider);
    final hasResults = searchState.maybeWhen(
      loadSuccess: (_) => true,
      loadInProgress: () => true,
      loadFailure: (_) => true,
      orElse: () => false,
    );
    final hasQuery = _controller.text.trim().length >= 2;
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s12, DesignTokens.s16, 0,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search input — pinned at the top, focused ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
                vertical: DesignTokens.s8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: DesignTokens.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search products or brands...',
                        hintStyle: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          color: DesignTokens.textMuted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isCollapsed: true,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (v) {
                        final q = v.trim();
                        if (q.length >= 2) {
                          ref
                              .read(productSearchSheetNotifierProvider.notifier)
                              .search(q);
                          FocusScope.of(context).unfocus();
                        }
                      },
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        ref
                            .read(productSearchSheetNotifierProvider.notifier)
                            .search('');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.close_rounded,
                          color: DesignTokens.textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                  const SizedBox(width: DesignTokens.s4),
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
            // ── Results section — below the search bar ──
            if (hasResults) ...[
              const Divider(
                height: 1,
                thickness: 1,
                color: DesignTokens.borderDefault,
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: mq.size.height * 0.75,
                ),
                child: searchState.when(
                  initial: () => const SizedBox.shrink(),
                  loadInProgress: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.s24),
                      child: CircularProgressIndicator(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ),
                  loadSuccess: (products) {
                    if (products.isEmpty && hasQuery) {
                      return const _EmptyProductsState(
                        icon: Icons.sentiment_dissatisfied_rounded,
                        title: 'Oops! No Results Found',
                        subtitle: "We couldn't find what you were looking for.\nTry searching again.",
                      );
                    }
                    if (products.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s12,
                        vertical: DesignTokens.s8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                        child: _ProductCard(
                          product: products[i],
                          onTagTap: () {
                            widget.onSubmit?.call(products[i]);
                            Navigator.pop(context);
                          },
                        )),
                    );
                  },
                  loadFailure: (_) => const _EmptyProductsState(
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    subtitle: 'Failed to load products.\nPlease try again.',
                  ),
                ),
              ),
            ],
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

  // The real per-sale commission is a creator↔vendor partnership term,
  // snapshotted server-side only when the tag is actually submitted — no
  // endpoint returns it at search time, so this is a rough estimate, not
  // the confirmed rate.
  String _commissionLabel() {
    const pct = 10;
    final amount = (product.price.amount * pct / 100).toStringAsFixed(0);
    if (product.price.amount > 5000) {
      return 'Est. $pct% commission (~Rs $amount per sale)';
    }
    return '~Rs $amount per sale (est.)';
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

  // The real per-sale commission is a creator↔vendor partnership term,
  // snapshotted server-side only when the tag is actually submitted — no
  // endpoint returns it at search time, so this is a rough estimate, not
  // the confirmed rate.
  String _commissionLabel() {
    const pct = 10;
    final amount = (product.price.amount * pct / 100).toStringAsFixed(0);
    if (product.price.amount > 5000) {
      return 'Est. $pct% commission (~Rs $amount per sale)';
    }
    return '~Rs $amount per sale (est.)';
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
