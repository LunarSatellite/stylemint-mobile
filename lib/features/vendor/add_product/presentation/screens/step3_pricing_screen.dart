import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class Step3PricingScreen extends ConsumerStatefulWidget {
  const Step3PricingScreen({super.key});

  @override
  ConsumerState<Step3PricingScreen> createState() =>
      _Step3PricingScreenState();
}

class _Step3PricingScreenState extends ConsumerState<Step3PricingScreen> {
  late TextEditingController _basePriceController;
  late TextEditingController _compareAtPriceController;
  late TextEditingController _discountController;
  late TextEditingController _costPerItemController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _quantityController;
  late TextEditingController _commissionRateController;
  bool _trackInventory = true;
  bool _allowOverselling = false;

  @override
  void initState() {
    super.initState();
    _basePriceController = TextEditingController();
    _compareAtPriceController = TextEditingController();
    _discountController = TextEditingController();
    _costPerItemController = TextEditingController();
    _skuController = TextEditingController();
    _barcodeController = TextEditingController();
    _quantityController = TextEditingController();
    _commissionRateController = TextEditingController();
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _compareAtPriceController.dispose();
    _discountController.dispose();
    _costPerItemController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _commissionRateController.dispose();
    super.dispose();
  }

  double get _basePrice =>
      double.tryParse(_basePriceController.text) ?? 0;
  double? get _discountPercent =>
      double.tryParse(_discountController.text);
  double? get _costPerItem =>
      double.tryParse(_costPerItemController.text);
  double? get _commissionRate =>
      double.tryParse(_commissionRateController.text);

  double get _effectivePrice {
    final disc = _discountPercent;
    if (disc != null && disc > 0) {
      return _basePrice * (1 - disc / 100);
    }
    return _basePrice;
  }

  double get _profit {
    final cost = _costPerItem ?? 0;
    return _effectivePrice - cost;
  }

  double get _creatorsEarn {
    final rate = _commissionRate ?? 0;
    return _effectivePrice * rate / 100;
  }

  PricingInfo _buildInfo() {
    final disc = _discountPercent;
    return PricingInfo(
      basePrice: Money(amount: _basePrice, currency: 'NPR'),
      compareAtPrice: _compareAtPriceController.text.isNotEmpty
          ? Money(
              amount:
                  double.tryParse(_compareAtPriceController.text) ?? 0,
              currency: 'NPR')
          : null,
      costPerItem: _costPerItem != null
          ? Money(amount: _costPerItem!, currency: 'NPR')
          : null,
      taxRate: 13,
      discountEnabled: disc != null && disc > 0,
      discountPercent: disc,
      sku: _skuController.text.trim(),
      quantityOnHand:
          int.tryParse(_quantityController.text.trim()) ?? 0,
      trackInventory: _trackInventory,
      allowOverselling: _allowOverselling,
    );
  }

  void _onProceed() {
    ref
        .read(addProductNotifierProvider.notifier)
        .updatePricing(_buildInfo());
    ref.read(addProductNotifierProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(addProductNotifierProvider.notifier);
    final canProceed = _basePriceController.text.isNotEmpty;

    return Column(
      children: [
        // ── Scrollable content ───────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3.1 Title
                  const Text(
                    'Pricing & Inventory',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.2 Base Price
                  _PricingField(
                    controller: _basePriceController,
                    label: 'Base Price',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.3 Compare at Price
                  _PricingField(
                    controller: _compareAtPriceController,
                    label: 'Compare at Price (Optional)',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.4 Discount Percent
                  _PricingField(
                    controller: _discountController,
                    label: 'Discount Percent',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.5 Cost Per Item
                  _PricingField(
                    controller: _costPerItemController,
                    label: 'Cost Per Item (Optional)',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.6 Your Profit
                  _YourProfitRow(profit: _profit),
                  const SizedBox(height: DesignTokens.s20),

                  const Divider(
                      color: DesignTokens.borderDefault, height: 1),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.7 Inventory section title
                  const Text(
                    'Inventory',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.8 SKU
                  _PricingField(
                    controller: _skuController,
                    label: 'SKU',
                    hintText: 'NK-AM-2024-BLK-056',
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.9 Barcode (cosmetic)
                  _DropdownStyleField(
                    controller: _barcodeController,
                    label: 'Barcode',
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.10 Quantity
                  _PricingField(
                    controller: _quantityController,
                    label: 'Quantity',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.11 Track Inventory checkbox
                  _SpecCheckbox(
                    value: _trackInventory,
                    title: 'Track Inventory',
                    description:
                        'Notify you when you need to restock inventory',
                    onChanged: (v) =>
                        setState(() => _trackInventory = v ?? true),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.12 Allow Overselling checkbox
                  _SpecCheckbox(
                    value: _allowOverselling,
                    title: 'Allow Overselling',
                    description:
                        'Sell product above the inventory stock',
                    onChanged: (v) =>
                        setState(() => _allowOverselling = v ?? false),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  const Divider(
                      color: DesignTokens.borderDefault, height: 1),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.13 Creator Commission info tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s8,
                        vertical: DesignTokens.s4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8E6FE),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'Creator Commission',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF024A70),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.14 Commission Rate
                  _PricingField(
                    controller: _commissionRateController,
                    label: 'Commission Rate',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    helperText: 'Recommended Rate: 10-20%',
                  ),
                  const SizedBox(height: DesignTokens.s4),

                  // 3.15 Creators Earn
                  _CreatorsEarnRow(amount: _creatorsEarn),
                ],
              ),
            ),
          ),
        ),

        // ── Sticky Previous + Proceed ────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s24,
            DesignTokens.s16,
            DesignTokens.s16,
          ),
          decoration: const BoxDecoration(
            color: DesignTokens.bgAppFoundation,
            border: Border(
              top: BorderSide(color: DesignTokens.borderDefault),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: DesignTokens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: notifier.prevStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.bgAppBodyLight,
                      foregroundColor: DesignTokens.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            DesignTokens.buttonRadius),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 16),
                        SizedBox(width: DesignTokens.s8),
                        Text(
                          'Previous',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s16),
              Expanded(
                child: SizedBox(
                  height: DesignTokens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: canProceed ? _onProceed : null,
                    style: DesignTokens.primaryButtonStyle(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Proceed',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: canProceed
                                ? DesignTokens.buttonPrimaryText
                                : DesignTokens.textMuted,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.s8),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: canProceed
                              ? DesignTokens.buttonPrimaryText
                              : DesignTokens.textMuted,
                        ),
                      ],
                    ),
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

// ── Plain input field ─────────────────────────────────────────────

class _PricingField extends StatelessWidget {
  const _PricingField({
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.onChanged,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: DesignTokens.bodyText,
      onChanged: onChanged,
      decoration: DesignTokens.inputDecoration(
        labelText: label,
        hintText: hintText,
      ).copyWith(
        helperText: helperText,
        helperStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: DesignTokens.textLight,
        ),
      ),
    );
  }
}

// ── Barcode field with trailing chevron icon ──────────────────────

class _DropdownStyleField extends StatelessWidget {
  const _DropdownStyleField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: DesignTokens.bodyText,
      decoration: DesignTokens.inputDecoration(labelText: label).copyWith(
        suffixIcon: const Icon(
          Icons.keyboard_arrow_down,
          size: 16,
          color: Color(0xFF71717B),
        ),
      ),
    );
  }
}

// ── Your Profit display row ───────────────────────────────────────

class _YourProfitRow extends StatelessWidget {
  const _YourProfitRow({required this.profit});

  final double profit;

  @override
  Widget build(BuildContext context) {
    final isPositive = profit >= 0;
    final color =
        isPositive ? DesignTokens.primaryGreen : DesignTokens.colorError;
    return Row(
      children: [
        const Text(
          'Your Profit',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: DesignTokens.s4),
        Text(
          'NPR ${profit.toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Creators Earn display row ─────────────────────────────────────

class _CreatorsEarnRow extends StatelessWidget {
  const _CreatorsEarnRow({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Creators Earn',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        Text(
          amount > 0 ? 'NPR ${amount.toStringAsFixed(2)}' : '-',
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: DesignTokens.textLight,
          ),
        ),
      ],
    );
  }
}

// ── Spec-style checkbox (square check + title + description) ──────

class _SpecCheckbox extends StatelessWidget {
  const _SpecCheckbox({
    required this.value,
    required this.title,
    required this.description,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String description;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: DesignTokens.primaryGreen,
            checkColor: Colors.black,
            side: const BorderSide(color: Color(0xFF9F9FA9)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: DesignTokens.s6),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: DesignTokens.textLight,
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
