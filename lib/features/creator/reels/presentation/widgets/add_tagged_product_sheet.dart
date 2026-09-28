import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/notifiers/creator_reel_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Tags a product onto a reel that is already imported.
///
/// ## Why this exists
///
/// Tagging only ever happened inside the import wizard — preview, tag
/// products, review — and once a reel was imported there was no way back in:
/// the creator's reel detail sheet could *remove* a tag but never add one,
/// and re-importing to reach the wizard again is refused by the unique index
/// on (source platform, external id). A creator who imported a reel and only
/// afterwards had a partnership approved, or only afterwards had the product
/// listed, had no route to connect the two but to delete the reel and import
/// it again, losing its id and its counts.
///
/// `POST /v1/creator/reels/{id}/tagged-products` has always supported this,
/// and the datasource, repository and notifier calls for it were written and
/// left unreferenced. This sheet is the missing caller.
///
/// ## What backs the search
///
/// [productSearchSheetNotifierProvider] — the same notifier the import
/// wizard's own picker uses, so both surfaces show the same products from the
/// same endpoint and neither can drift into showing a set the other does not.
///
/// ## What it does not decide
///
/// Whether the creator may tag a given product is the server's ruling, not
/// this sheet's. Tagging requires an Active partnership with that product's
/// vendor, and a campaign-scoped partnership narrows it further to that
/// campaign's products; both are enforced in `TagProductAsync`, on the
/// partnership the tag is about to snapshot, because that is the one path
/// that reaches money. So a refusal is surfaced here as the error it is
/// rather than pre-empted by hiding products — a creator who cannot see why
/// a product is missing learns nothing, and a client-side guess at the rule
/// would drift the moment the rule changed.
class AddTaggedProductSheet extends ConsumerStatefulWidget {
  const AddTaggedProductSheet({required this.reelId, super.key});

  final String reelId;

  @override
  ConsumerState<AddTaggedProductSheet> createState() =>
      _AddTaggedProductSheetState();
}

class _AddTaggedProductSheetState extends ConsumerState<AddTaggedProductSheet> {
  final TextEditingController _controller = TextEditingController();

  /// Debounce for the search field, so a per-keystroke request storm does not
  /// reach the catalog and so results do not flicker between prefixes.
  Timer? _debounce;

  /// The product currently being tagged, so only its row shows a spinner
  /// instead of the whole list going busy.
  String? _taggingProductId;

  /// Shortest query worth sending. Matches the import wizard's own picker;
  /// a single letter matches most of a catalog and is not a search.
  static const _minQueryLength = 2;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    // Below the threshold nothing is sent, and build() shows the prompt
    // rather than results. Searching an empty string would set loadSuccess
    // with an empty list, which renders as "No products found" — telling the
    // creator their catalog is empty when they simply have not typed yet.
    if (value.trim().length < _minQueryLength) {
      setState(() {});
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(
        ref.read(productSearchSheetNotifierProvider.notifier).search(value),
      );
    });
  }

  Future<void> _tag(String productId) async {
    if (_taggingProductId != null) return;
    setState(() => _taggingProductId = productId);

    final ok = await ref
        .read(creatorReelActionsNotifierProvider.notifier)
        .tagProduct(widget.reelId, productId: productId);

    if (!mounted) return;
    setState(() => _taggingProductId = null);

    if (ok) {
      // Refresh the same two providers the remove path invalidates, so the
      // tagged list and the reel detail behind this sheet both catch up.
      ref
        ..invalidate(reelTaggedProductsProvider(widget.reelId))
        ..invalidate(creatorReelDetailProvider(widget.reelId));
      Navigator.of(context).pop();
    }
    // On failure the notifier surfaces the server's message — which for the
    // common case is the partnership refusal — and the sheet stays open so
    // the creator can pick something else.
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(productSearchSheetNotifierProvider);

    return SafeArea(
      child: Padding(
        // viewInsets so the list is not hidden behind the keyboard the search
        // field raises.
        padding: EdgeInsets.only(
          left: DesignTokens.s16,
          right: DesignTokens.s16,
          top: DesignTokens.s16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + DesignTokens.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tag a product', style: DesignTokens.sectionInnerTitle),
            const SizedBox(height: DesignTokens.s12),
            TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search products',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: _controller.text.trim().length < _minQueryLength
                  ? const Padding(
                      padding: EdgeInsets.all(DesignTokens.s24),
                      child: Text(
                        'Type at least two letters to find a product.',
                        style: DesignTokens.bodyText,
                      ),
                    )
                  : searchState.when(
                      initial: () => const SizedBox.shrink(),
                loadInProgress: () => const Padding(
                  padding: EdgeInsets.all(DesignTokens.s24),
                  child: SmPageLoader(),
                ),
                loadFailure: (failure) => Padding(
                  padding: const EdgeInsets.all(DesignTokens.s24),
                  child: Text(
                    failure.toString().replaceFirst('Exception: ', ''),
                    style: DesignTokens.bodyText,
                  ),
                ),
                loadSuccess: (products) => products.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(DesignTokens.s24),
                        child: Text(
                          'No products found.',
                          style: DesignTokens.bodyText,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: products.length,
                        itemBuilder: (_, i) {
                          final p = products[i];
                          final busy = _taggingProductId == p.productId;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: p.imageUrl.isEmpty
                                ? null
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      p.imageUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _e, _s) =>
                                          const SizedBox(width: 44, height: 44),
                                    ),
                                  ),
                            title: Text(
                              p.productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DesignTokens.bodyText,
                            ),
                            subtitle: Text(
                              '${formatMoney(p.price, decimalDigits: 0)}'
                              '  ·  ${p.vendorName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DesignTokens.bodyText,
                            ),
                            trailing: busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            onTap: busy ? null : () => unawaited(_tag(p.productId)),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
