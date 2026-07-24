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
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  // Shipping options — multi-select
  bool _standard = true;
  bool _express = false;
  bool _overnight = false;

  // Cosmetic dropdowns (not in ShippingInfo entity)
  String? _shipsFrom;
  String? _processingTime;

  static const _shipsFromOptions = [
    'Kathmandu', 'Pokhara', 'Lalitpur', 'Bhaktapur', 'Biratnagar',
  ];
  static const _processingTimeOptions = [
    '1 business day', '2-3 business days', '3-5 business days',
    '5-7 business days',
  ];

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _lengthController = TextEditingController();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  ShippingInfo _buildInfo() {
    // Derive estimate range + fee from selected options.
    final selectedMins = <int>[];
    final selectedMaxes = <int>[];
    Money? highestFee;

    if (_standard) {
      selectedMins.add(5);
      selectedMaxes.add(7);
      // Standard is FREE — no fee
    }
    if (_express) {
      selectedMins.add(2);
      selectedMaxes.add(3);
      highestFee = const Money(amount: 500, currency: 'NPR');
    }
    if (_overnight) {
      selectedMins.add(1);
      selectedMaxes.add(1);
      if (highestFee == null ||
          highestFee.amount < 800) {
        highestFee = const Money(amount: 800, currency: 'NPR');
      }
    }

    final minDays = selectedMins.isNotEmpty
        ? selectedMins.reduce((a, b) => a < b ? a : b)
        : 5;
    final maxDays = selectedMaxes.isNotEmpty
        ? selectedMaxes.reduce((a, b) => a > b ? a : b)
        : 7;

    return ShippingInfo(
      weight: double.tryParse(_weightController.text) ?? 0,
      weightUnit: 'lbs',
      dimensionsLength:
          double.tryParse(_lengthController.text) ?? 0,
      dimensionsWidth:
          double.tryParse(_widthController.text) ?? 0,
      dimensionsHeight:
          double.tryParse(_heightController.text) ?? 0,
      requiresShipping: true,
      shippingFee: highestFee,
      deliveryEstimateMin: minDays,
      deliveryEstimateMax: maxDays,
    );
  }

  void _onProceed() {
    ref
        .read(addProductNotifierProvider.notifier)
        .updateShipping(_buildInfo());
    ref.read(addProductNotifierProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(addProductNotifierProvider.notifier);

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
                    'Shipping Details',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.2 Weight
                  _ShippingField(
                    controller: _weightController,
                    label: 'Weight (In lbs)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.3 Length
                  _ShippingField(
                    controller: _lengthController,
                    label: 'Length (In inches)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.4 Width
                  _ShippingField(
                    controller: _widthController,
                    label: 'Width (In inches)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.5 Height
                  _ShippingField(
                    controller: _heightController,
                    label: 'Height (In inches)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.6 Shipping Options
                  const Text(
                    'Shipping Options',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  _ShippingOptionRow(
                    label: 'Standard (5-7 days) - FREE',
                    value: _standard,
                    onChanged: (v) =>
                        setState(() => _standard = v ?? false),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  _ShippingOptionRow(
                    label: 'Express (2-3 days) - Rs 500',
                    value: _express,
                    onChanged: (v) =>
                        setState(() => _express = v ?? false),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  _ShippingOptionRow(
                    label: 'Overnight (1 day) - Rs 800',
                    value: _overnight,
                    onChanged: (v) =>
                        setState(() => _overnight = v ?? false),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.7 Ships From
                  _DropdownField(
                    label: 'Ships From',
                    value: _shipsFrom,
                    options: _shipsFromOptions,
                    onChanged: (v) => setState(() => _shipsFrom = v),
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // 3.8 Processing Time
                  _DropdownField(
                    label: 'Processing Time',
                    value: _processingTime,
                    options: _processingTimeOptions,
                    onChanged: (v) =>
                        setState(() => _processingTime = v),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Sticky Previous + Proceed ────────────────────────────
        SafeArea(
          top: false,
          child: Container(
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
                    onPressed: _onProceed,
                    style: DesignTokens.primaryButtonStyle(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Proceed',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        ),
                        SizedBox(width: DesignTokens.s8),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: DesignTokens.buttonPrimaryText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ],
    );
  }
}

// ── Plain text field ──────────────────────────────────────────────

class _ShippingField extends StatelessWidget {
  const _ShippingField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: DesignTokens.bodyText,
      decoration: DesignTokens.inputDecoration(labelText: label),
    );
  }
}

// ── Single shipping option row (checkbox + label) ─────────────────

class _ShippingOptionRow extends StatelessWidget {
  const _ShippingOptionRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
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
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: DesignTokens.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dropdown field (Ships From / Processing Time) ─────────────────

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.inputFieldFill,
        borderRadius:
            BorderRadius.circular(DesignTokens.inputRadius),
        border: Border.all(color: DesignTokens.inputFieldBorder),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9F9FA9),
            ),
          ),
          isExpanded: true,
          dropdownColor: DesignTokens.bgAppBodyLight,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: Color(0xFF71717B),
          ),
          style: DesignTokens.bodyText,
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
