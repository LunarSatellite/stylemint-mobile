import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtl = TextEditingController();
  final _expiryCtl = TextEditingController();
  final _cvvCtl = TextEditingController();
  final _cardholderCtl = TextEditingController();
  bool _saving = false;

  String get _maskedCardNumber {
    final digits = _cardNumberCtl.text.replaceAll(RegExp(r'\s+'), '');
    if (digits.isEmpty) return '•••• •••• •••• ••••';
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i >= digits.length) {
        buffer.write('•');
      } else if (i < 4) {
        buffer.write(digits[i]);
      } else if (i < 12) {
        buffer.write('•');
      } else {
        buffer.write(digits[i]);
      }
      if ((i + 1) % 4 == 0 && i < 15) buffer.write(' ');
    }
    return buffer.toString();
  }

  String? _detectedCardType() {
    final digits = _cardNumberCtl.text.replaceAll(RegExp(r'\s+'), '');
    if (digits.isEmpty) return null;
    final first = digits[0];
    final firstTwo = digits.length >= 2 ? digits.substring(0, 2) : '';
    if (first == '4') return 'Visa';
    if (firstTwo == '51' || firstTwo == '52' || firstTwo == '53' || firstTwo == '54' || firstTwo == '55') return 'Mastercard';
    if (firstTwo == '34' || firstTwo == '37') return 'Amex';
    return null;
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

    final digits = _cardNumberCtl.text.replaceAll(RegExp(r'\s+'), '');

    final success = await ref.read(paymentNotifierProvider.notifier).addCard(
      cardNumber: digits,
      expiry: _expiryCtl.text.trim(),
      cvv: _cvvCtl.text.trim(),
      cardholderName: _cardholderCtl.text.trim(),
    );

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add card')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: const Text('Add Card'),
        backgroundColor: DesignTokens.bgAppFoundation,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            _CardPreview(
              cardNumber: _maskedCardNumber,
              cardholderName:
                  _cardholderCtl.text.isNotEmpty
                      ? _cardholderCtl.text
                      : 'Your Name',
              expiry:
                  _expiryCtl.text.isNotEmpty ? _expiryCtl.text : 'MM/YY',
              cardType: _detectedCardType(),
            ),
            const SizedBox(height: DesignTokens.s24),
            TextFormField(
              controller: _cardNumberCtl,
              keyboardType: TextInputType.number,
              maxLength: 19,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardNumberFormatter(),
              ],
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.inputFieldData,
              ),
              decoration: DesignTokens.inputDecoration(
                labelText: 'Card Number',
              ),
              validator: (v) {
                final digits = v?.replaceAll(RegExp(r'\s+'), '') ?? '';
                if (digits.length < 13) return 'Enter valid card number';
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.s16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryCtl,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryFormatter(),
                    ],
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.inputFieldData,
                    ),
                    decoration: DesignTokens.inputDecoration(
                      labelText: 'Expiry (MM/YY)',
                    ),
                    validator: (v) {
                      final digits = v?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
                      if (digits.length < 4) return 'Required';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: DesignTokens.s16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvCtl,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.inputFieldData,
                    ),
                    decoration: DesignTokens.inputDecoration(labelText: 'CVV'),
                    validator: (v) {
                      if (v == null || v.trim().length < 3) return 'Required';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            TextFormField(
              controller: _cardholderCtl,
              textCapitalization: TextCapitalization.words,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.inputFieldData,
              ),
              decoration: DesignTokens.inputDecoration(
                labelText: 'Cardholder Name',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                return null;
              },
              onChanged: (_) => setState(() {}),
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
                      'Save Card',
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
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.cardNumber,
    required this.cardholderName,
    required this.expiry,
    this.cardType,
  });

  final String cardNumber;
  final String cardholderName;
  final String expiry;
  final String? cardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(DesignTokens.s20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        gradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF1A7A44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.credit_card_rounded,
                  color: DesignTokens.textWhite, size: 32),
              if (cardType != null)
                Text(cardType!,
                    style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite)),
            ],
          ),
          Text(
            cardNumber,
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.textWhite,
              letterSpacing: 2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CARD HOLDER',
                        style: DesignTokens.tiny.copyWith(
                            color: DesignTokens.textWhite.withValues(alpha: 0.7))),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      cardholderName.toUpperCase(),
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPIRES',
                      style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textWhite.withValues(alpha: 0.7))),
                  const SizedBox(height: DesignTokens.s4),
                  Text(expiry,
                      style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite)),
                ],
              ),
            ],
          ),
        ],
      ),
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
