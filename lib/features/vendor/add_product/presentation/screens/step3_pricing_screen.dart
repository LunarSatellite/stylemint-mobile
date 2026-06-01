import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
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
  late TextEditingController _costPerItemController;
  double _taxRate = 13.0;
  bool _discountEnabled = false;
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _basePriceController = TextEditingController();
    _compareAtPriceController = TextEditingController();
    _costPerItemController = TextEditingController();
    _discountController = TextEditingController();
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _compareAtPriceController.dispose();
    _costPerItemController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  PricingInfo _buildInfo() {
    final baseAmount = double.tryParse(_basePriceController.text) ?? 0;
    final compareAt =
        double.tryParse(_compareAtPriceController.text);
    final cost = double.tryParse(_costPerItemController.text);
    final discount =
        double.tryParse(_discountController.text);

    return PricingInfo(
      basePrice: Money(amount: baseAmount, currency: 'NPR'),
      compareAtPrice:
          compareAt != null ? Money(amount: compareAt, currency: 'NPR') : null,
      costPerItem:
          cost != null ? Money(amount: cost, currency: 'NPR') : null,
      taxRate: _taxRate,
      discountEnabled: _discountEnabled,
      discountPercent: _discountEnabled ? discount : null,
    );
  }

  void _onNext() {
    ref.read(addProductNotifierProvider.notifier).updatePricing(_buildInfo());
    ref.read(addProductNotifierProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final info = _buildInfo();
    final displayPrice = _discountEnabled && info.discountPercent != null
        ? info.basePrice.amount * (1 - info.discountPercent! / 100)
        : info.basePrice.amount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pricing', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s20),
          TextField(
            controller: _basePriceController,
            keyboardType: TextInputType.number,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              labelText: 'Base Price (NPR)',
              hintText: 'Enter base price',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          TextField(
            controller: _compareAtPriceController,
            keyboardType: TextInputType.number,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              labelText: 'Compare at Price (optional)',
              hintText: 'Original/strikethrough price',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          TextField(
            controller: _costPerItemController,
            keyboardType: TextInputType.number,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              labelText: 'Cost per Item (optional)',
              hintText: 'Your cost',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),
          Text(
            'Tax Rate: ${_taxRate.toStringAsFixed(0)}%',
            style: DesignTokens.mediumSemibold,
          ),
          Slider(
            value: _taxRate,
            min: 0,
            max: 30,
            divisions: 30,
            activeColor: DesignTokens.primaryGreen,
            onChanged: (v) => setState(() => _taxRate = v),
          ),
          const SizedBox(height: DesignTokens.s16),
          SwitchListTile(
            title: Text('Enable Discount',
                style: DesignTokens.mediumSemibold),
            value: _discountEnabled,
            activeColor: DesignTokens.primaryGreen,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _discountEnabled = v),
          ),
          if (_discountEnabled) ...[
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              style: DesignTokens.bodyText,
              decoration: DesignTokens.inputDecoration(
                labelText: 'Discount Percentage (%)',
                hintText: 'e.g. 10',
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Price Preview',
                    style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.primaryGreen)),
                const SizedBox(height: DesignTokens.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Price', style: DesignTokens.mediumRegular),
                    if (_discountEnabled && info.discountPercent != null)
                      Text(
                        formatMoney(info.basePrice),
                        style: DesignTokens.mediumRegular.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    Text(
                      formatMoney(Money(amount: displayPrice, currency: 'NPR')),
                      style: DesignTokens.sectionInnerTitle.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s32),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: (_basePriceController.text.isNotEmpty)
                  ? _onNext
                  : null,
              style: DesignTokens.primaryButtonStyle(),
              child: Text('Next',
                  style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText)),
            ),
          ),
        ],
      ),
    );
  }
}
