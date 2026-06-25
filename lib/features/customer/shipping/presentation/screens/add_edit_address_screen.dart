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

  late TextEditingController _fullNameCtl;
  late TextEditingController _phoneCtl;
  late TextEditingController _addressLine1Ctl;
  late TextEditingController _landmarkCtl;
  late TextEditingController _zipCodeCtl;
  late TextEditingController _cityCtl;
  late TextEditingController _labelCtl;

  late String _country;
  late String _province;

  bool _saving = false;

  static const _countries = [
    'Nepal', 'India', 'China', 'Bangladesh', 'Bhutan', 'Pakistan', 'Sri Lanka',
  ];

  static const _nepalProvinces = [
    'Koshi', 'Madhesh', 'Bagmati', 'Gandaki', 'Lumbini', 'Karnali', 'Sudurpashchim',
  ];

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _fullNameCtl = TextEditingController(text: a?.fullName ?? '');
    _phoneCtl = TextEditingController(text: a?.phone ?? '');
    _addressLine1Ctl = TextEditingController(text: a?.addressLine1 ?? '');
    _landmarkCtl = TextEditingController(text: a?.addressLine2 ?? '');
    _zipCodeCtl = TextEditingController(text: a?.zipCode ?? '');
    _cityCtl = TextEditingController(text: a?.city ?? '');
    _labelCtl = TextEditingController(text: a?.label ?? 'Home');
    _country = _countries.contains(a?.country) ? (a!.country) : 'Nepal';
    _province = _nepalProvinces.contains(a?.state) ? (a!.state) : 'Bagmati';
  }

  @override
  void dispose() {
    _fullNameCtl.dispose();
    _phoneCtl.dispose();
    _addressLine1Ctl.dispose();
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
      fullName: _fullNameCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      addressLine1: _addressLine1Ctl.text.trim(),
      addressLine2: _landmarkCtl.text.trim().isEmpty ? null : _landmarkCtl.text.trim(),
      country: _country,
      city: _cityCtl.text.trim(),
      state: _province,
      zipCode: _zipCodeCtl.text.trim(),
      isDefault: widget.address?.isDefault ?? false,
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
                  _field('Full Name', _fullNameCtl, required: true),
                  const SizedBox(height: DesignTokens.s16),
                  _field(
                    "Receiver's Phone No.",
                    _phoneCtl,
                    keyboardType: TextInputType.phone,
                    required: true,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _field('Address Line 1', _addressLine1Ctl, required: true),
                  const SizedBox(height: DesignTokens.s16),
                  _field('Nearest Landmark (Optional)', _landmarkCtl),
                  const SizedBox(height: DesignTokens.s16),
                  _dropdown(
                    label: 'Country',
                    value: _country,
                    items: _countries,
                    onChanged: (v) => setState(() => _country = v ?? 'Nepal'),
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
          Container(
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
