import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  const AddEditAddressScreen({this.address, super.key});

  final ShippingAddress? address;

  bool get isEditing => address != null;

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _receiverNameCtl;
  late TextEditingController _receiverPhoneCtl;
  late TextEditingController _line1Ctl;
  late TextEditingController _landmarkCtl;
  late TextEditingController _zipCodeCtl;
  late TextEditingController _cityCtl;
  late TextEditingController _labelCtl;

  late String _country;
  late String _province;

  bool _saving = false;

  static const _countryMap = {
    'Nepal': 'NP',
    'India': 'IN',
    'China': 'CN',
    'Bangladesh': 'BD',
    'Bhutan': 'BT',
    'Pakistan': 'PK',
    'Sri Lanka': 'LK',
  };

  static const _nepalProvinces = [
    'Koshi', 'Madhesh', 'Bagmati', 'Gandaki', 'Lumbini', 'Karnali', 'Sudurpashchim',
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _receiverNameCtl = TextEditingController(text: a?.receiverName ?? '');
    _receiverPhoneCtl = TextEditingController(text: a?.receiverPhone ?? '');
    _line1Ctl = TextEditingController(text: a?.addressLine1 ?? '');
    _landmarkCtl = TextEditingController(text: a?.landmark ?? '');
    _zipCodeCtl = TextEditingController(text: a?.zipCode ?? '');
    _cityCtl = TextEditingController(text: a?.city ?? '');
    _labelCtl = TextEditingController(text: a?.label ?? 'Home');
    final existing = a?.country;
    _country = _countryMap.containsValue(existing)
        ? existing!
        : (_countryMap[existing] ?? 'NP');
    _province = _nepalProvinces.contains(a?.state) ? (a!.state) : 'Bagmati';
  }

  @override
  void dispose() {
    _receiverNameCtl.dispose();
    _receiverPhoneCtl.dispose();
    _line1Ctl.dispose();
    _landmarkCtl.dispose();
    _zipCodeCtl.dispose();
    _cityCtl.dispose();
    _labelCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final notifier = ref.read(addressNotifierProvider.notifier);
    final address = ShippingAddress(
      id: widget.address?.id ?? '',
      label: _labelCtl.text.trim().isEmpty ? 'Home' : _labelCtl.text.trim(),
      receiverName: _receiverNameCtl.text.trim(),
      receiverPhone: _receiverPhoneCtl.text.trim(),
      addressLine1: _line1Ctl.text.trim(),
      landmark: _landmarkCtl.text.trim().isEmpty ? null : _landmarkCtl.text.trim(),
      country: _country,
      city: _cityCtl.text.trim(),
      state: _province,
      zipCode: _zipCodeCtl.text.trim(),
      isDefault: widget.address?.isDefault ?? false,
      rowVersion: widget.address?.rowVersion ?? '',
    );

    final success = widget.isEditing
        ? await notifier.update(widget.address!.id, address)
        : await notifier.add(address);

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save address')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditing;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: const BackButton(color: DesignTokens.textWhite),
        title: Text(
          isEdit ? 'Edit Shipping Address' : 'Add Shipping Address',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(DesignTokens.s16),
                children: [
                  _field('Receiver Name', _receiverNameCtl, required: true),
                  const SizedBox(height: DesignTokens.s16),
                  _field(
                    'Receiver Phone',
                    _receiverPhoneCtl,
                    keyboardType: TextInputType.phone,
                    required: true,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _field('Address Line 1', _line1Ctl, required: true),
                  const SizedBox(height: DesignTokens.s16),
                  _field('Nearest Landmark (Optional)', _landmarkCtl),
                  const SizedBox(height: DesignTokens.s16),
                  DropdownButtonFormField<String>(
                    value: _country,
                    onChanged: (v) => setState(() => _country = v ?? 'NP'),
                    style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.inputFieldData),
                    dropdownColor: DesignTokens.bgAppBodyLight,
                    iconEnabledColor: DesignTokens.inputFieldDropdownIcon,
                    decoration: DesignTokens.inputDecoration(labelText: 'Country'),
                    items: _countryMap.entries
                        .map((e) => DropdownMenuItem(
                              value: e.value,
                              child: Text('${e.key} (${e.value})'),
                            ))
                        .toList(growable: false),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _dropdown(
                    label: 'State/Province',
                    value: _province,
                    items: _nepalProvinces,
                    onChanged: (v) => setState(() => _province = v ?? 'Bagmati'),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _field(
                    'Zip/Postal Code',
                    _zipCodeCtl,
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _field('City', _cityCtl, required: true),
                  const SizedBox(height: DesignTokens.s16),
                  _field('Save Address As', _labelCtl),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: DesignTokens.borderDefault, width: 1),
                ),
              ),
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: DesignTokens.primaryButtonStyle(),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        )
                      : Text(
                          isEdit ? 'Update Address Details' : 'Add Address Details',
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.inputFieldData),
      decoration: DesignTokens.inputDecoration(labelText: label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.inputFieldData),
      dropdownColor: DesignTokens.bgAppBodyLight,
      iconEnabledColor: DesignTokens.inputFieldDropdownIcon,
      decoration: DesignTokens.inputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(growable: false),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}
