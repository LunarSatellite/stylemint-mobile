import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class Step4ShippingScreen extends ConsumerStatefulWidget {
  const Step4ShippingScreen({super.key});

  @override
  ConsumerState<Step4ShippingScreen> createState() =>
      _Step4ShippingScreenState();
}

class _Step4ShippingScreenState extends ConsumerState<Step4ShippingScreen> {
  late TextEditingController _weightController;
  String _weightUnit = 'kg';
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  bool _requiresShipping = true;
  late TextEditingController _shippingFeeController;
  late TextEditingController _freeShippingOverController;
  double _deliveryEstimateMin = 3;
  double _deliveryEstimateMax = 7;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _lengthController = TextEditingController();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _shippingFeeController = TextEditingController();
    _freeShippingOverController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _shippingFeeController.dispose();
    _freeShippingOverController.dispose();
    super.dispose();
  }

  ShippingInfo _buildInfo() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final shippingFee =
        double.tryParse(_shippingFeeController.text);
    final freeShipping =
        double.tryParse(_freeShippingOverController.text);

    return ShippingInfo(
      weight: weight,
      weightUnit: _weightUnit,
      dimensionsLength: length,
      dimensionsWidth: width,
      dimensionsHeight: height,
      requiresShipping: _requiresShipping,
      shippingFee:
          shippingFee != null ? Money(amount: shippingFee, currency: 'NPR') : null,
      freeShippingOver: freeShipping != null
          ? Money(amount: freeShipping, currency: 'NPR')
          : null,
      deliveryEstimateMin: _deliveryEstimateMin.toInt(),
      deliveryEstimateMax: _deliveryEstimateMax.toInt(),
    );
  }

  void _onNext() {
    ref.read(addProductNotifierProvider.notifier).updateShipping(_buildInfo());
    ref.read(addProductNotifierProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shipping', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s16),
          SwitchListTile(
            title: Text('Requires Shipping',
                style: DesignTokens.mediumSemibold),
            value: _requiresShipping,
            activeColor: DesignTokens.primaryGreen,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _requiresShipping = v),
          ),
          if (_requiresShipping) ...[
            const SizedBox(height: DesignTokens.s16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: DesignTokens.bodyText,
                    decoration:
                        DesignTokens.inputDecoration(labelText: 'Weight'),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Container(
                  height: DesignTokens.inputHeight,
                  width: 80,
                  decoration: BoxDecoration(
                    color: DesignTokens.inputFieldFill,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.inputRadius),
                    border: Border.all(
                        color: DesignTokens.inputFieldBorder, width: 1),
                  ),
                  child: DropdownButton<String>(
                    value: _weightUnit,
                    dropdownColor: DesignTokens.bgAppBody,
                    underline: const SizedBox(),
                    isExpanded: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
                    style: DesignTokens.bodyText,
                    items: ['kg', 'g', 'lb']
                        .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u, style: DesignTokens.mediumRegular)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _weightUnit = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            Text('Dimensions (cm)',
                style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textMuted)),
            const SizedBox(height: DesignTokens.s8),
            Row(
              children: [
                _DimensionField(
                    controller: _lengthController, label: 'L'),
                const SizedBox(width: DesignTokens.s8),
                _DimensionField(
                    controller: _widthController, label: 'W'),
                const SizedBox(width: DesignTokens.s8),
                _DimensionField(
                    controller: _heightController, label: 'H'),
              ],
            ),
            const SizedBox(height: DesignTokens.s20),
            TextField(
              controller: _shippingFeeController,
              keyboardType: TextInputType.number,
              style: DesignTokens.bodyText,
              decoration: DesignTokens.inputDecoration(
                labelText: 'Shipping Fee (NPR, optional)',
                hintText: 'e.g. 100',
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            TextField(
              controller: _freeShippingOverController,
              keyboardType: TextInputType.number,
              style: DesignTokens.bodyText,
              decoration: DesignTokens.inputDecoration(
                labelText: 'Free Shipping Over (NPR, optional)',
                hintText: 'e.g. 5000',
              ),
            ),
            const SizedBox(height: DesignTokens.s20),
            Text(
              'Delivery Estimate: ${_deliveryEstimateMin.toInt()} - ${_deliveryEstimateMax.toInt()} days',
              style: DesignTokens.mediumSemibold,
            ),
            RangeSlider(
              values: RangeValues(_deliveryEstimateMin, _deliveryEstimateMax),
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: DesignTokens.primaryGreen,
              labels: RangeLabels(
                '${_deliveryEstimateMin.toInt()} days',
                '${_deliveryEstimateMax.toInt()} days',
              ),
              onChanged: (v) {
                setState(() {
                  _deliveryEstimateMin = v.start;
                  _deliveryEstimateMax = v.end;
                });
              },
            ),
          ],
          const SizedBox(height: DesignTokens.s32),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: _onNext,
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

class _DimensionField extends StatelessWidget {
  const _DimensionField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: DesignTokens.bodyText,
        decoration:
            DesignTokens.inputDecoration(labelText: label),
      ),
    );
  }
}
