import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class UpdateProductStockScreen extends StatefulWidget {
  const UpdateProductStockScreen({required this.product, super.key});

  final VendorProduct product;

  @override
  State<UpdateProductStockScreen> createState() =>
      _UpdateProductStockScreenState();
}

class _UpdateProductStockScreenState extends State<UpdateProductStockScreen> {
  final _addQtyController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _restockDate;
  bool _alertCustomers = true;

  int get _addQty => int.tryParse(_addQtyController.text) ?? 0;
  int get _newStock => widget.product.stockCount + _addQty;

  @override
  void initState() {
    super.initState();
    _addQtyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _addQtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _restockDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: DesignTokens.primaryGreen,
            onPrimary: Colors.black,
            surface: DesignTokens.bgAppBodyLight,
            onSurface: DesignTokens.textWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _restockDate = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Update Product Stock',
            style: DesignTokens.oneLinerSemibold),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product card
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.s12),
                      decoration: DesignTokens.cardDecoration(),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(DesignTokens.s8),
                            child: Image.network(
                              widget.product.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
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
                                  style: DesignTokens.mediumSemibold,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: DesignTokens.s6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: DesignTokens.s8,
                                      vertical: 3),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.primaryGreen
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Current Stock: ${widget.product.stockCount}',
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
                    const SizedBox(height: DesignTokens.s20),

                    // Add Qty
                    _inputDecoration(
                      child: TextField(
                        controller: _addQtyController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: DesignTokens.mediumRegular
                            .copyWith(color: DesignTokens.textWhite),
                        decoration: InputDecoration(
                          hintText: 'Add Qty.',
                          hintStyle: DesignTokens.mediumRegular
                              .copyWith(color: DesignTokens.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.s16,
                              vertical: DesignTokens.s12),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s12),

                    // New stock formula
                    Text(
                      'New Stock Qty. (Current Stock + Add Qty.)',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textMuted),
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s12, vertical: 6),
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${widget.product.stockCount} + $_addQty = $_newStock',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s20),

                    // Restock Date
                    GestureDetector(
                      onTap: _pickDate,
                      child: _inputDecoration(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.s16,
                              vertical: DesignTokens.s12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _restockDate != null
                                      ? _formatDate(_restockDate!)
                                      : 'Restock Date',
                                  style: DesignTokens.mediumRegular.copyWith(
                                    color: _restockDate != null
                                        ? DesignTokens.textWhite
                                        : DesignTokens.textMuted,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_month_outlined,
                                  size: 18, color: DesignTokens.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s12),

                    // Notes
                    _inputDecoration(
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        style: DesignTokens.mediumRegular
                            .copyWith(color: DesignTokens.textWhite),
                        decoration: InputDecoration(
                          hintText: 'Notes (Optional)',
                          hintStyle: DesignTokens.mediumRegular
                              .copyWith(color: DesignTokens.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.s16,
                              vertical: DesignTokens.s12),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s20),

                    // Alert customers checkbox
                    GestureDetector(
                      onTap: () =>
                          setState(() => _alertCustomers = !_alertCustomers),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _alertCustomers,
                            onChanged: (v) =>
                                setState(() => _alertCustomers = v ?? false),
                            activeColor: DesignTokens.primaryGreen,
                            checkColor: Colors.black,
                            side: const BorderSide(
                                color: DesignTokens.primaryGreen),
                          ),
                          const SizedBox(width: DesignTokens.s4),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alert Customers',
                                    style: DesignTokens.mediumSemibold,
                                  ),
                                  Text(
                                    'Notify customers on wait list',
                                    style: DesignTokens.smallRegular.copyWith(
                                        color: DesignTokens.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16, 0, DesignTokens.s16, DesignTokens.s16),
              child: SmPrimaryButton(
                label: 'Update Stock',
                height: DesignTokens.buttonHeight,
                borderRadius: DesignTokens.buttonRadius,
                onPressed: () async => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputDecoration({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
      ),
      child: child,
    );
  }
}
