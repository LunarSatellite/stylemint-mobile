import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/print/shelf_card_output.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/print/shelf_card_pdf.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/print/store_shelf_cards.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/widgets/vendor_code_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One store: its details, its own StyleMint code, every product shelf card
/// in one PDF, edit and archive.
class VendorStoreDetailScreen extends ConsumerStatefulWidget {
  const VendorStoreDetailScreen({required this.storeId, this.store, super.key});

  final String storeId;

  /// The store from the list, shown until the list has loaded.
  final VendorStore? store;

  @override
  ConsumerState<VendorStoreDetailScreen> createState() =>
      _VendorStoreDetailScreenState();
}

class _VendorStoreDetailScreenState
    extends ConsumerState<VendorStoreDetailScreen> {
  bool _preparingCards = false;

  void _openStoreCode(VendorStore store) {
    unawaited(
      showVendorCodeSheet(
        context,
        target: (productId: null, storeId: store.id),
        subject: VendorCodeSubject(
          title: store.name,
          storeName: store.name,
          storeCity: store.city,
        ),
      ),
    );
  }

  Future<void> _printAllCards(VendorStore store) async {
    if (_preparingCards) return;
    setState(() => _preparingCards = true);
    final result = await loadStoreShelfCards(
      codes: ref.read(vendorCodesRepositoryProvider),
      products: ref.read(vendorProductsRepositoryProvider),
      store: store,
    );
    if (!mounted) return;
    setState(() => _preparingCards = false);

    final failure = result.getLeft().toNullable();
    if (failure != null) {
      SmSnackbar.error(context, NetworkExceptions.getMessage(failure));
      return;
    }
    final cards = result.getRight().toNullable() ?? const <ShelfCardData>[];
    if (cards.isEmpty) {
      SmSnackbar.info(
        context,
        "No shelf codes in this store yet. Make them from a product's "
        'In-store codes.',
      );
      return;
    }
    final slug = store.name
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    await showShelfCardOutputSheet(
      context,
      documentName: 'StyleMint shelf cards - ${store.name}',
      fileName: 'stylemint-shelf-cards${slug.isEmpty ? '' : '-$slug'}.pdf',
      format: PdfPageFormat.a4,
      build: (mark) => ShelfCardPdf.sheets(cards, markPng: mark),
    );
  }

  Future<void> _archive(VendorStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text(
          'Archive this store?',
          style: DesignTokens.sectionInnerTitle,
        ),
        content: Text(
          'It leaves your stores list and gets no new shelf codes. Remove its '
          'printed cards and tags from the shelves.',
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirm-archive-store'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Archive',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref
        .read(vendorStoresNotifierProvider.notifier)
        .archive(store.id);
    if (!mounted) return;
    if (failure != null) {
      SmSnackbar.error(context, NetworkExceptions.getMessage(failure));
      return;
    }
    SmSnackbar.success(context, 'Store archived');
    context.popOrHome();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorStoresNotifierProvider);
    final fromList = state is VendorStoresLoaded
        ? state.stores.firstWhereOrNull((s) => s.id == widget.storeId)
        : null;
    // Once the list has loaded it is the truth: an archived store is gone.
    final store =
        fromList ?? (state is VendorStoresLoaded ? null : widget.store);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text('Store', style: DesignTokens.sectionInnerTitle),
      ),
      body: store == null
          ? state is VendorStoresLoading
                ? const SmPageLoader()
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(DesignTokens.s24),
                      child: Text(
                        "This store isn't available any more.",
                        textAlign: TextAlign.center,
                        style: DesignTokens.mediumRegular,
                      ),
                    ),
                  )
          : ListView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              children: [
                _StoreCard(store: store),
                const SizedBox(height: DesignTokens.s16),
                _DetailAction(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Store code',
                  subtitle: 'A QR and NFC tag for the shop door or counter',
                  onTap: () => _openStoreCode(store),
                ),
                _DetailAction(
                  icon: Icons.print_outlined,
                  title: _preparingCards
                      ? 'Preparing shelf cards…'
                      : 'Print all shelf cards',
                  subtitle: 'Every product code in this store, four to an A4',
                  onTap: _preparingCards
                      ? null
                      : () => unawaited(_printAllCards(store)),
                ),
                _DetailAction(
                  icon: Icons.edit_outlined,
                  title: 'Edit store',
                  onTap: () => unawaited(
                    context.push(
                      RouteNames.vendorStoreEdit.replaceFirst(
                        ':storeId',
                        store.id,
                      ),
                      extra: store,
                    ),
                  ),
                ),
                _DetailAction(
                  icon: Icons.archive_outlined,
                  title: 'Archive store',
                  destructive: true,
                  onTap: () => unawaited(_archive(store)),
                ),
              ],
            ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});

  final VendorStore store;

  @override
  Widget build(BuildContext context) {
    final phone = store.phone;
    final lat = store.latitude;
    final lng = store.longitude;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(store.name, style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s8),
          Text(store.addressLine, style: DesignTokens.mediumRegular),
          Text(store.city, style: DesignTokens.mediumRegular),
          if (phone != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(phone, style: DesignTokens.smallRegular),
          ],
          if (lat != null && lng != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text('$lat, $lng', style: DesignTokens.smallRegular),
          ],
        ],
      ),
    );
  }
}

class _DetailAction extends StatelessWidget {
  const _DetailAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? DesignTokens.colorError
        : onTap == null
        ? DesignTokens.textMuted
        : DesignTokens.textWhite;
    final sub = subtitle;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.s12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8,
          vertical: DesignTokens.s12,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.mediumRegular.copyWith(color: color),
                  ),
                  if (sub != null) Text(sub, style: DesignTokens.smallRegular),
                ],
              ),
            ),
            if (!destructive)
              const Icon(
                Icons.chevron_right_rounded,
                color: DesignTokens.iconLight,
              ),
          ],
        ),
      ),
    );
  }
}
