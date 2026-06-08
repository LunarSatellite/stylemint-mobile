import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/notifiers/vendor_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Product row actions — matches "Products - Active/Out of Stock Action":
/// a bottom sheet (Edit Product Details / Update Product Stock /
/// Deactivate (or Reactivate) Product) and the "Confirm Deactivate" dialog.
Future<void> showVendorProductActions(
    BuildContext context, WidgetRef ref, VendorProduct product) {
  final isActive = product.status != VendorProductStatus.discontinued;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: DesignTokens.bgAppBodyLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignTokens.s12),
          _ActionRow(
            icon: Icons.edit_outlined,
            title: 'Edit Product Details',
            onTap: () {
              Navigator.pop(sheetCtx);
              // TODO(vendor): open the Add/Edit Product wizard in edit mode.
              SmSnackbar.success(context, 'Edit product (coming soon).');
            },
          ),
          const _ActionDivider(),
          _ActionRow(
            icon: Icons.inventory_2_outlined,
            title: 'Update Product Stock',
            onTap: () {
              Navigator.pop(sheetCtx);
              // TODO(vendor): open the stock-update sheet (no stock endpoint yet).
              SmSnackbar.success(context, 'Update stock (coming soon).');
            },
          ),
          const _ActionDivider(),
          _ActionRow(
            icon: isActive
                ? Icons.do_not_disturb_on_outlined
                : Icons.check_circle_outline,
            title: isActive ? 'Deactivate Product' : 'Reactivate Product',
            danger: isActive,
            onTap: () async {
              Navigator.pop(sheetCtx);
              if (isActive) {
                final ok = await _confirmDeactivate(context);
                if (ok == true) {
                  await ref
                      .read(vendorProductsNotifierProvider.notifier)
                      .updateStatus(
                          product.id, VendorProductStatus.discontinued);
                }
              } else {
                await ref
                    .read(vendorProductsNotifierProvider.notifier)
                    .updateStatus(product.id, VendorProductStatus.active);
              }
            },
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
      ),
    ),
  );
}

Future<bool?> _confirmDeactivate(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: DesignTokens.bgAppFoundation,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => const _ConfirmDeactivateSheet(),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(
      {required this.icon,
      required this.title,
      required this.onTap,
      this.danger = false});

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? DesignTokens.colorError : DesignTokens.textWhite;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
        child: Row(
          children: [
            Icon(icon,
                size: 24,
                color: danger ? DesignTokens.colorError : DesignTokens.iconLight),
            const SizedBox(width: DesignTokens.s12),
            Text(title,
                style: DesignTokens.mediumRegular.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: DesignTokens.s16),
        child: Divider(color: DesignTokens.borderDefault, height: 1),
      );
}

class _ConfirmDeactivateSheet extends StatefulWidget {
  const _ConfirmDeactivateSheet();

  @override
  State<_ConfirmDeactivateSheet> createState() =>
      _ConfirmDeactivateSheetState();
}

class _ConfirmDeactivateSheetState extends State<_ConfirmDeactivateSheet> {
  bool _ack = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm Deactivate',
                textAlign: TextAlign.center,
                style: DesignTokens.titleLarge.copyWith(fontSize: 20)),
            const SizedBox(height: DesignTokens.s12),
            Text(
              'Are you sure you want to Deactivate this product? Once deactivated the product will be delisted.',
              style: DesignTokens.mediumRegular
                  .copyWith(color: DesignTokens.textLight),
            ),
            const SizedBox(height: DesignTokens.s8),
            CheckboxListTile(
              value: _ack,
              onChanged: (v) => setState(() => _ack = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: DesignTokens.primaryGreen,
              title: Text('I understand this product will be delisted',
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textWhite)),
            ),
            const SizedBox(height: DesignTokens.s16),
            SmPrimaryButton(
              label: 'Deactivate',
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              color: DesignTokens.colorError,
              labelColor: DesignTokens.textWhite,
              disabled: !_ack,
              onPressed: () async => Navigator.pop(context, true),
            ),
            const SizedBox(height: DesignTokens.s8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
              ),
              child: Text('Cancel',
                  style: DesignTokens.mediumSemibold
                      .copyWith(color: DesignTokens.textLight)),
            ),
          ],
        ),
      ),
    );
  }
}
