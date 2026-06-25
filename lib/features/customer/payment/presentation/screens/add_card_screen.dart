import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/entities/payment_method.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({this.card, super.key});

  final PaymentMethod? card;

  bool get isEditing => card != null;

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cardNumberCtl;
  late TextEditingController _expiryCtl;
  late TextEditingController _cvvCtl;
  late TextEditingController _cardholderCtl;

  bool _billingSameAsShipping = true;
  bool _setAsDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _cardNumberCtl = TextEditingController(
      text: c?.lastFour != null ? '•••• •••• •••• ${c!.lastFour}' : '',
    );
    _expiryCtl = TextEditingController(text: c?.expiryDate ?? '');
    _cvvCtl = TextEditingController();
    _cardholderCtl = TextEditingController(text: c?.cardholderName ?? '');
    _setAsDefault = c?.isDefault ?? false;
  }

  @override
  void dispose() {
    _cardNumberCtl.dispose();
    _expiryCtl.dispose();
    _cvvCtl.dispose();
    _cardholderCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final notifier = ref.read(paymentNotifierProvider.notifier);
    final digits = _cardNumberCtl.text.replaceAll(RegExp(r'[\s•]'), '');
    final bool success;

    if (widget.isEditing) {
      success = await notifier.updateCard(
        id: widget.card!.id,
        cardNumber: digits,
        expiry: _expiryCtl.text.trim(),
        cvv: _cvvCtl.text.trim(),
        cardholderName: _cardholderCtl.text.trim(),
      );
    } else {
      success = await notifier.addCard(
        cardNumber: digits,
        expiry: _expiryCtl.text.trim(),
        cvv: _cvvCtl.text.trim(),
        cardholderName: _cardholderCtl.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditing ? 'Failed to update card' : 'Failed to add card')),
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
          isEdit ? 'Edit Card Details' : 'Add Card Details',
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
                  _field(
                    'Card Number',
                    _cardNumberCtl,
                    keyboardType: TextInputType.number,
                    maxLength: 19,
                    inputFormatters: isEdit
                        ? null
                        : [
                            FilteringTextInputFormatter.digitsOnly,
                            _CardNumberFormatter(),
                          ],
                    validator: (v) {
                      final clean = v?.replaceAll(RegExp(r'[\s•]'), '') ?? '';
                      if (clean.length < 13) return 'Enter a valid card number';
                      return null;
                    },
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _field(
                    'Expiry Date',
                    _expiryCtl,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryFormatter(),
                    ],
                    suffixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Color(0xFF71717B),
                    ),
                    validator: (v) {
                      final digits = v?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
                      if (digits.length < 4) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _field(
                    'CVV',
                    _cvvCtl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        (v == null || v.trim().length < 3) ? 'Required' : null,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _field(
                    'Cardholder Name',
                    _cardholderCtl,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: DesignTokens.s24),
                  // Billing Address checkbox
                  _CheckboxRow(
                    label: 'Billing Address',
                    subtitle: "Set your card's billing address same as your shipping address",
                    value: _billingSameAsShipping,
                    onChanged: (v) => setState(() => _billingSameAsShipping = v ?? true),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  // Set as Default checkbox
                  _CheckboxRow(
                    label: 'Set as Default Payment',
                    subtitle: 'Set this card as your default payment option',
                    value: _setAsDefault,
                    onChanged: (v) => setState(() => _setAsDefault = v ?? false),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                ],
              ),
            ),
          ),
          // Secure banner + pinned button
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignTokens.cardRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  color: DesignTokens.bgAppBodyLight,
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset('assets/icons/SecureIcon.svg', width: 36, height: 36),
                      const SizedBox(width: DesignTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Secure & Encrypted', style: DesignTokens.mediumSemibold),
                            const SizedBox(height: DesignTokens.s4),
                            Text(
                              "Don't worry about your card details, they are protected with high level encryption",
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: DesignTokens.bgAppFoundation,
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16,
                    DesignTokens.s16,
                    DesignTokens.s16,
                    DesignTokens.s32,
                  ),
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
                            isEdit ? 'Update Card Details' : 'Add Card Details',
                            style: DesignTokens.mediumSemibold.copyWith(
                              color: DesignTokens.buttonPrimaryText,
                            ),

                          ),
                  ),
                ),
              ],
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
    int? maxLength,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.inputFieldData),
      decoration: DesignTokens.inputDecoration(labelText: label, suffixIcon: suffixIcon),
      validator: validator,
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: DesignTokens.primaryGreen,
            side: const BorderSide(color: DesignTokens.borderDefault, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s4),
              Text(
                subtitle,
                style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\s+'), '');
    if (text.length > 16) return oldValue;
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > 4) return oldValue;
    if (text.length >= 2) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}/${text.substring(2)}',
        selection: TextSelection.collapsed(
          offset: text.length + (text.length >= 2 ? 1 : 0),
        ),
      );
    }
    return newValue;
  }
}
