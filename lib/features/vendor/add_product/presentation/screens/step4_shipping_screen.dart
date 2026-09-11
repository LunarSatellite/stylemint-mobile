import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/notifiers/shipping_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/notifiers/add_product_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class Step4ShippingScreen extends ConsumerStatefulWidget {
  const Step4ShippingScreen({
    this.isFinalStep = false,
    this.saving = false,
    this.onSave,
    super.key,
  });

  final bool isFinalStep;
  final bool saving;
  final Future<void> Function()? onSave;

  @override
  ConsumerState<Step4ShippingScreen> createState() =>
      _Step4ShippingScreenState();
}

class _Step4ShippingScreenState extends ConsumerState<Step4ShippingScreen> {
  late TextEditingController _weightController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  bool _standard = true;
  bool _express = false;
  String? _shipsFromAddressId;
  String? _processingTime = '1 business day';

  static const _processingTimeOptions = [
    '1 business day',
    '2-3 business days',
    '3-5 business days',
    '5-7 business days',
  ];

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _lengthController = TextEditingController();
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromState());
  }

  void _hydrateFromState() {
    if (!mounted) return;
    final fs = ref.read(addProductNotifierProvider).maybeWhen(
          loadSuccess: (s) => s,
          orElse: () => null,
        );
    final shipping = fs?.step4;
    if (shipping == null) return;
    final options = shipping.shippingOptions;
    setState(() {
      _weightController.text =
          shipping.weight > 0 ? shipping.weight.toString() : '';
      _lengthController.text = shipping.dimensionsLength > 0
          ? shipping.dimensionsLength.toString()
          : '';
      _widthController.text = shipping.dimensionsWidth > 0
          ? shipping.dimensionsWidth.toString()
          : '';
      _heightController.text = shipping.dimensionsHeight > 0
          ? shipping.dimensionsHeight.toString()
          : '';
      _standard = options.isEmpty
          ? shipping.deliveryEstimateMin >= 5
          : options.any((option) => option.kind == 1);
      _express = options.isEmpty
          ? shipping.deliveryEstimateMax <= 3
          : options.any((option) => option.kind == 2);
      _shipsFromAddressId = shipping.shipsFromAddressId;
      _processingTime = _processingLabelFor(shipping.processingTimeDays);
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  int get _processingTimeDays => switch (_processingTime) {
        '2-3 business days' => 2,
        '3-5 business days' => 3,
        '5-7 business days' => 5,
        _ => 1,
      };

  static String _processingLabelFor(int days) => switch (days) {
        >= 5 => '5-7 business days',
        >= 3 => '3-5 business days',
        >= 2 => '2-3 business days',
        _ => '1 business day',
      };

  ShippingAddress? _selectedAddress(List<ShippingAddress> addresses) {
    if (addresses.isEmpty) return null;
    for (final address in addresses) {
      if (address.id == _shipsFromAddressId) return address;
    }
    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }

  ShippingInfo _buildInfo(List<ShippingAddress> addresses) {
    final selectedAddress = _selectedAddress(addresses);
    final options = <ProductShippingOption>[
      if (_standard)
        const ProductShippingOption(
          kind: 1,
          label: 'Standard (5-7 days) - FREE',
          fee: Money(amount: 0, currency: 'NPR'),
          estimatedDaysMin: 5,
          estimatedDaysMax: 7,
        ),
      if (_express)
        const ProductShippingOption(
          kind: 2,
          label: 'Express (2-3 days) - Rs 500',
          fee: Money(amount: 500, currency: 'NPR'),
          estimatedDaysMin: 2,
          estimatedDaysMax: 3,
        ),
    ];
    final minDays = options.isEmpty
        ? 0
        : options
            .map((option) => option.estimatedDaysMin)
            .reduce((a, b) => a < b ? a : b);
    final maxDays = options.isEmpty
        ? 0
        : options
            .map((option) => option.estimatedDaysMax)
            .reduce((a, b) => a > b ? a : b);
    final highestFee = options.isEmpty
        ? null
        : options
            .map((option) => option.fee)
            .reduce((a, b) => a.amount >= b.amount ? a : b);

    return ShippingInfo(
      weight: double.tryParse(_weightController.text) ?? 0,
      weightUnit: 'lbs',
      dimensionsLength: double.tryParse(_lengthController.text) ?? 0,
      dimensionsWidth: double.tryParse(_widthController.text) ?? 0,
      dimensionsHeight: double.tryParse(_heightController.text) ?? 0,
      requiresShipping: options.isNotEmpty,
      shippingFee: highestFee,
      deliveryEstimateMin: minDays,
      deliveryEstimateMax: maxDays,
      shipsFromAddressId: selectedAddress?.id,
      shipsFromLabel: selectedAddress == null
          ? null
          : '${selectedAddress.label} — '
              '${selectedAddress.addressLine1}, ${selectedAddress.city}',
      processingTimeDays: _processingTimeDays,
      shippingOptions: options,
    );
  }

  Future<void> _onProceed(List<ShippingAddress> addresses) async {
    final info = _buildInfo(addresses);
    if (info.shipsFromAddressId == null) {
      SmSnackbar.error(context, 'Add and select a real dispatch address.');
      return;
    }
    if (info.shippingOptions.isEmpty) {
      SmSnackbar.error(context, 'Select at least one shipping option.');
      return;
    }
    if (info.weight <= 0 ||
        info.dimensionsLength <= 0 ||
        info.dimensionsWidth <= 0 ||
        info.dimensionsHeight <= 0) {
      SmSnackbar.error(context, 'Enter a positive weight and all dimensions.');
      return;
    }

    final notifier = ref.read(addProductNotifierProvider.notifier);
    notifier.updateShipping(info);
    if (widget.isFinalStep) {
      await widget.onSave?.call();
    } else {
      notifier.nextStep();
    }
  }

  Future<void> _openAddressManager() async {
    await context.push(RouteNames.shippingAddresses);
    if (!mounted) return;
    await ref.read(addressNotifierProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(addProductNotifierProvider.notifier);
    final addressState = ref.watch(addressNotifierProvider);
    final addresses = addressState.maybeWhen(
      loadSuccess: (items) => items,
      orElse: () => const <ShippingAddress>[],
    );
    final addressesLoading = addressState.maybeWhen(
      initial: () => true,
      loadInProgress: () => true,
      orElse: () => false,
    );
    final addressesFailed = addressState.maybeWhen(
      loadFailure: (_) => true,
      orElse: () => false,
    );
    final selectedAddress = _selectedAddress(addresses);

    return Column(
      children: [
        // â”€â”€ Scrollable content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                  const SizedBox(height: DesignTokens.s20),

                  // 3.7 Ships From
                  if (addressesLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.primaryGreen,
                      ),
                    )
                  else if (addresses.isEmpty)
                    _MissingDispatchAddress(
                      loadFailed: addressesFailed,
                      onManage: _openAddressManager,
                    )
                  else ...[
                    _AddressDropdownField(
                      value: selectedAddress?.id,
                      addresses: addresses,
                      onChanged: (value) =>
                          setState(() => _shipsFromAddressId = value),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _openAddressManager,
                        child: const Text('Manage dispatch addresses'),
                      ),
                    ),
                  ],
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

        // â”€â”€ Sticky Previous + Proceed â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
                    onPressed: widget.saving
                        ? null
                        : () => _onProceed(addresses),
                    style: DesignTokens.primaryButtonStyle(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.saving
                              ? 'Saving...'
                              : widget.isFinalStep
                              ? 'Save Changes'
                              : 'Proceed',
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.s8),
                        Icon(
                          widget.isFinalStep
                              ? Icons.save_outlined
                              : Icons.arrow_forward,
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

// â”€â”€ Plain text field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Single shipping option row (checkbox + label) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

// â”€â”€ Dropdown field (Ships From / Processing Time) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MissingDispatchAddress extends StatelessWidget {
  const _MissingDispatchAddress({
    required this.loadFailed,
    required this.onManage,
  });

  final bool loadFailed;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.inputFieldFill,
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          border: Border.all(color: DesignTokens.inputFieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loadFailed
                  ? 'Dispatch addresses could not be loaded.'
                  : 'No dispatch address is saved yet.',
              style: DesignTokens.bodyText,
            ),
            const SizedBox(height: DesignTokens.s8),
            TextButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(loadFailed ? 'Retry or manage addresses' : 'Add address'),
            ),
          ],
        ),
      );
}

class _AddressDropdownField extends StatelessWidget {
  const _AddressDropdownField({
    required this.value,
    required this.addresses,
    required this.onChanged,
  });

  final String? value;
  final List<ShippingAddress> addresses;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: DesignTokens.inputFieldFill,
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          border: Border.all(color: DesignTokens.inputFieldBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: const Text('Ships From'),
            isExpanded: true,
            dropdownColor: DesignTokens.bgAppBodyLight,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF71717B),
            ),
            style: DesignTokens.bodyText,
            items: addresses
                .map(
                  (address) => DropdownMenuItem(
                    value: address.id,
                    child: Text(
                      '${address.label} — ${address.addressLine1}, ${address.city}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: onChanged,
          ),
        ),
      );
}
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
