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
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _label;
  late TextEditingController _fullNameCtl;
  late TextEditingController _phoneCtl;
  late TextEditingController _addressLine1Ctl;
  late TextEditingController _addressLine2Ctl;
  late TextEditingController _cityCtl;
  late TextEditingController _stateCtl;
  late TextEditingController _zipCodeCtl;
  late bool _isDefault;
  bool _saving = false;

  static const _labels = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _label = a?.label ?? 'Home';
    _fullNameCtl = TextEditingController(text: a?.fullName ?? '');
    _phoneCtl = TextEditingController(text: a?.phone ?? '');
    _addressLine1Ctl = TextEditingController(text: a?.addressLine1 ?? '');
    _addressLine2Ctl = TextEditingController(text: a?.addressLine2 ?? '');
    _cityCtl = TextEditingController(text: a?.city ?? '');
    _stateCtl = TextEditingController(text: a?.state ?? '');
    _zipCodeCtl = TextEditingController(text: a?.zipCode ?? '');
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _fullNameCtl.dispose();
    _phoneCtl.dispose();
    _addressLine1Ctl.dispose();
    _addressLine2Ctl.dispose();
    _cityCtl.dispose();
    _stateCtl.dispose();
    _zipCodeCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final notifier = ref.read(addressNotifierProvider.notifier);

    final address = ShippingAddress(
      id: widget.address?.id ?? '',
      label: _label,
      fullName: _fullNameCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      addressLine1: _addressLine1Ctl.text.trim(),
      addressLine2: _addressLine2Ctl.text.trim().isEmpty
          ? null
          : _addressLine2Ctl.text.trim(),
      city: _cityCtl.text.trim(),
      state: _stateCtl.text.trim(),
      zipCode: _zipCodeCtl.text.trim(),
      isDefault: _isDefault,
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
        title: Text(isEdit ? 'Edit Address' : 'Add Address'),
        backgroundColor: DesignTokens.bgAppFoundation,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            Text('Address Label', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: _labels.map((l) {
                final selected = l == _label;
                return GestureDetector(
                  onTap: () => setState(() => _label = l),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s8,
                    ),
                    decoration: selected
                        ? DesignTokens.chipDecorationSelected()
                        : DesignTokens.chipDecorationDefault(),
                    child: Text(
                      l,
                      style: DesignTokens.mediumRegular.copyWith(
                        color: selected
                            ? DesignTokens.textWhite
                            : DesignTokens.chipsDefaultText,
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: DesignTokens.s20),
            _buildField('Full Name', _fullNameCtl, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            }),
            const SizedBox(height: DesignTokens.s16),
            _buildField('Phone Number', _phoneCtl, keyboardType: TextInputType.phone, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            }),
            const SizedBox(height: DesignTokens.s16),
            _buildField('Address Line 1', _addressLine1Ctl, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            }),
            const SizedBox(height: DesignTokens.s16),
            _buildField('Address Line 2', _addressLine2Ctl),
            const SizedBox(height: DesignTokens.s16),
            _buildField('City', _cityCtl, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            }),
            const SizedBox(height: DesignTokens.s16),
            _buildField('State', _stateCtl, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            }),
            const SizedBox(height: DesignTokens.s16),
            _buildField('Zip Code', _zipCodeCtl, keyboardType: TextInputType.number, validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              return null;
            }),
            const SizedBox(height: DesignTokens.s20),
            SwitchListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: Text('Set as default address',
                  style: DesignTokens.mediumSemibold),
              activeColor: DesignTokens.primaryGreen,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: DesignTokens.s32),
            ElevatedButton(
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
                      isEdit ? 'Update Address' : 'Save Address',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: DesignTokens.mediumRegular.copyWith(
        color: DesignTokens.inputFieldData,
      ),
      decoration: DesignTokens.inputDecoration(labelText: label),
      validator: validator,
    );
  }
}
