import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/notifiers/vendor_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Product row ⋮ action sheet.
/// Active    → Edit / View Analytics / Deactivate / Update Stock  (4 items)
/// OutOfStock → Edit / View Analytics / Update Stock              (3 items)
/// Draft      → Edit / View Analytics / Update Stock              (3 items)
Future<void> showVendorProductActions(
    BuildContext context, WidgetRef ref, VendorProduct product) {
  final isActive = product.status == VendorProductStatus.active;
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
          // Drag handle
          const SizedBox(height: DesignTokens.s12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // 1 — Edit Product Details
          _ActionRow(
            icon: Icons.edit_outlined,
            title: 'Edit Product Details',
            onTap: () {
              Navigator.pop(sheetCtx);
              SmSnackbar.success(context, 'Edit product (coming soon).');
            },
          ),
          const _ActionDivider(),

          // 2 — View Analytics
          _ActionRow(
            icon: Icons.bar_chart_outlined,
            title: 'View Analytics',
            onTap: () {
              Navigator.pop(sheetCtx);
              context.push(RouteNames.vendorProductAnalytics, extra: product);
            },
          ),
          const _ActionDivider(),

          // 3 — Deactivate (Active only)
          if (isActive) ...[
            _ActionRow(
              icon: Icons.do_not_disturb_on_outlined,
              title: 'Deactivate',
              onTap: () async {
                Navigator.pop(sheetCtx);
                final ok = await _confirmDeactivate(context, product);
                if (ok == true) {
                  await ref
                      .read(vendorProductsNotifierProvider.notifier)
                      .updateStatus(
                          product.id, VendorProductStatus.discontinued);
                }
              },
            ),
            const _ActionDivider(),
          ],

          // 4 — Update Product Stock
          _ActionRow(
            icon: Icons.inventory_2_outlined,
            title: 'Update Product Stock',
            onTap: () {
              Navigator.pop(sheetCtx);
              context.push(RouteNames.vendorUpdateStock, extra: product);
            },
          ),

          const SizedBox(height: DesignTokens.s20),
        ],
      ),
    ),
  );
}

Future<bool?> _confirmDeactivate(BuildContext context, VendorProduct product) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: DesignTokens.bgAppFoundation,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _ConfirmDeactivateSheet(product: product),
  );
}

// ── Action row ────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: DesignTokens.iconLight),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(
                title,
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: DesignTokens.iconLight,
            ),
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

// ── Confirm deactivate sheet ──────────────────────────────────────────────────

class _ConfirmDeactivateSheet extends StatefulWidget {
  const _ConfirmDeactivateSheet({required this.product});

  final VendorProduct product;

  @override
  State<_ConfirmDeactivateSheet> createState() =>
      _ConfirmDeactivateSheetState();
}

class _ConfirmDeactivateSheetState extends State<_ConfirmDeactivateSheet> {
  bool _ack = false;
  String? _reason;

  static const _reasons = [
    'Out of season',
    'Low demand',
    'Product discontinued',
    'Quality issues',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16, DesignTokens.s12, DesignTokens.s16, DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DesignTokens.s20),

            // Info icon
            Image.asset('assets/images/vendordashboard/infoicon.png', width: 52, height: 52),
            const SizedBox(height: DesignTokens.s16),

            // Title
            Text(
              'Confirm Deactivate',
              style: DesignTokens.titleLarge.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.s8),

            // Body text
            Text(
              'Are your sure you want to Deactivate this product? Once deactivated the product will be removed from search and product list but the orders will be fulfilled',
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.s16),

            // Product card
            Container(
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: DesignTokens.cardDecoration(),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.s8),
                    child: Image.network(
                      widget.product.imageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: DesignTokens.bgAppBodyLight,
                        child: const Icon(Icons.image,
                            color: DesignTokens.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: DesignTokens.smallRegular
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: DesignTokens.s6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.s8, vertical: 3),
                          decoration: BoxDecoration(
                            color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Active Orders: ${widget.product.totalSales}',
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s16),

            // Reason dropdown
            Container(
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                border: Border.all(color: DesignTokens.borderDefault),
              ),
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _reason,
                  hint: Text('Reason',
                      style: DesignTokens.mediumRegular
                          .copyWith(color: DesignTokens.textMuted)),
                  isExpanded: true,
                  dropdownColor: DesignTokens.bgAppBodyLight,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: DesignTokens.textMuted),
                  style: DesignTokens.mediumRegular
                      .copyWith(color: DesignTokens.textWhite),
                  items: _reasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _reason = v),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),

            // Checkbox
            GestureDetector(
              onTap: () => setState(() => _ack = !_ack),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Checkbox(
                    value: _ack,
                    onChanged: (v) => setState(() => _ack = v ?? false),
                    activeColor: DesignTokens.primaryGreen,
                    checkColor: Colors.black,
                    side: const BorderSide(color: DesignTokens.borderDefault),
                  ),
                  Expanded(
                    child: Text(
                      'I understand this product will be delisted',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textWhite),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s16),

            // Deactivate button
            SmPrimaryButton(
              label: 'Deactivate',
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              disabled: !_ack,
              onPressed: () async => Navigator.pop(context, true),
            ),
            const SizedBox(height: DesignTokens.s8),

            // Cancel button
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.bgAppBodyLight,
                  foregroundColor: DesignTokens.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                ),
                child: Text('Cancel', style: DesignTokens.mediumSemibold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
