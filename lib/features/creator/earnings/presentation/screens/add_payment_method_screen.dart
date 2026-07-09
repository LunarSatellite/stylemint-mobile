import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// TODO(backend-confirm): verify _kindBank and _kindVenmo with backend
const int _kindBank = 1;
const int _kindVenmo = 2;
const int _kindPayPal = 3;
const int _kindEsewa = 4;

enum _Platform { bank, paypal, venmo, esewa }

class AddPaymentMethodScreen extends ConsumerStatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  ConsumerState<AddPaymentMethodScreen> createState() =>
      _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState
    extends ConsumerState<AddPaymentMethodScreen> {
  _Platform _selected = _Platform.bank;

  // Bank A/C
  String? _bankName;
  final _holderCtrl = TextEditingController();
  final _routingCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  String? _accountType;

  // PayPal
  final _paypalCtrl = TextEditingController();

  // Venmo
  final _venmoCtrl = TextEditingController();

  // Esewa
  final _esewaCtrl = TextEditingController();

  static const _banks = [
    'Nepal Bank Limited',
    'Rastriya Banijya Bank',
    'Nabil Bank',
    'Standard Chartered Bank',
    'Himalayan Bank',
    'Nepal Investment Bank',
    'Everest Bank',
    'Global IME Bank',
    'NMB Bank',
    'Kumari Bank',
    'Laxmi Sunrise Bank',
    'Citizens Bank',
    'Prime Commercial Bank',
    'Machhapuchchhre Bank',
    'Siddhartha Bank',
    'NIC Asia Bank',
    'Prabhu Bank',
    'Sanima Bank',
    'Bank of Kathmandu',
    'Chase Bank',
  ];

  static const _accountTypes = ['Savings', 'Checking', 'Current'];

  @override
  void dispose() {
    _holderCtrl.dispose();
    _routingCtrl.dispose();
    _accountCtrl.dispose();
    _paypalCtrl.dispose();
    _venmoCtrl.dispose();
    _esewaCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_selected) {
      case _Platform.bank:
        return _bankName != null &&
            _holderCtrl.text.trim().isNotEmpty &&
            _routingCtrl.text.trim().isNotEmpty &&
            _accountCtrl.text.trim().isNotEmpty &&
            _accountType != null;
      case _Platform.paypal:
        return _paypalCtrl.text.trim().isNotEmpty;
      case _Platform.venmo:
        return _venmoCtrl.text.trim().isNotEmpty;
      case _Platform.esewa:
        return _esewaCtrl.text.trim().isNotEmpty;
    }
  }

  String _buildLabel() {
    switch (_selected) {
      case _Platform.bank:
        final acct = _accountCtrl.text.trim();
        final last4 = acct.length >= 4 ? acct.substring(acct.length - 4) : acct;
        return '${_bankName!} — ****$last4';
      case _Platform.paypal:
        return 'PayPal — ${_paypalCtrl.text.trim()}';
      case _Platform.venmo:
        return 'Venmo — ${_venmoCtrl.text.trim()}';
      case _Platform.esewa:
        return 'eSewa — ${_esewaCtrl.text.trim()}';
    }
  }

  Future<void> _onProceed() async {
    final notifier = ref.read(addPayoutMethodNotifierProvider.notifier);
    switch (_selected) {
      case _Platform.bank:
        final acct = _accountCtrl.text.trim();
        final last4 =
            acct.length >= 4 ? acct.substring(acct.length - 4) : acct;
        await notifier.addBank(
          kind: _kindBank,
          label: _buildLabel(),
          maskedAccountNumber: '****$last4',
          beneficiaryName: _holderCtrl.text.trim(),
          processorReference: _routingCtrl.text.trim(),
        );
      case _Platform.paypal:
        await notifier.addExternalWallet(
          kind: _kindPayPal,
          label: _buildLabel(),
          externalIdentifier: _paypalCtrl.text.trim(),
        );
      case _Platform.venmo:
        await notifier.addExternalWallet(
          kind: _kindVenmo,
          label: _buildLabel(),
          externalIdentifier: _venmoCtrl.text.trim(),
        );
      case _Platform.esewa:
        await notifier.addExternalWallet(
          kind: _kindEsewa,
          label: _buildLabel(),
          externalIdentifier: _esewaCtrl.text.trim(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(addPayoutMethodNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(earningsNotifierProvider.notifier).load();
          if (_selected == _Platform.bank) {
            context.push(RouteNames.creatorBankVerification);
          } else {
            context.pop();
          }
        },
        error: (error, _) {
          final msg = error is NetworkExceptions
              ? NetworkExceptions.getMessage(error)
              : 'Failed to add payment method.';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    });

    final addState = ref.watch(addPayoutMethodNotifierProvider);
    final isLoading = addState.isLoading;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add Payment Method',
            style: DesignTokens.sectionInnerTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Platform',
                style: DesignTokens.mediumSemibold
                    .copyWith(color: DesignTokens.textWhite)),
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: _Platform.values.map((p) {
                final isLast = p == _Platform.values.last;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : DesignTokens.s4),
                    child: _PlatformCard(
                      platform: p,
                      selected: _selected == p,
                      onTap: () => setState(() => _selected = p),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: DesignTokens.s20),
            Container(
              padding: const EdgeInsets.all(DesignTokens.s16),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
              child: _buildForm(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16, DesignTokens.s8,
              DesignTokens.s16, DesignTokens.s16),
          child: SizedBox(
            height: DesignTokens.buttonHeight,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_canProceed && !isLoading) ? _onProceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                disabledBackgroundColor:
                    DesignTokens.primaryGreen.withValues(alpha: 0.4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Proceed',
                            style: DesignTokens.mediumSemibold
                                .copyWith(color: DesignTokens.buttonPrimaryText)),
                        const SizedBox(width: DesignTokens.s8),
                        Icon(Icons.arrow_forward_rounded,
                            color: DesignTokens.buttonPrimaryText, size: 18),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    switch (_selected) {
      case _Platform.bank:
        return Column(
          children: [
            _DropdownField<String>(
              hint: 'Bank Name',
              value: _bankName,
              items: _banks,
              itemLabel: (b) => b,
              onChanged: (v) => setState(() => _bankName = v),
            ),
            const SizedBox(height: DesignTokens.s12),
            _InputField(
              ctrl: _holderCtrl,
              hint: 'Account Holder Name',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.s12),
            _InputField(
              ctrl: _routingCtrl,
              hint: 'Routing Number',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.s12),
            _InputField(
              ctrl: _accountCtrl,
              hint: 'Account Number',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.s12),
            _DropdownField<String>(
              hint: 'Account Type',
              value: _accountType,
              items: _accountTypes,
              itemLabel: (t) => t,
              onChanged: (v) => setState(() => _accountType = v),
            ),
          ],
        );
      case _Platform.paypal:
        return _InputField(
          ctrl: _paypalCtrl,
          hint: 'PayPal Email',
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
        );
      case _Platform.venmo:
        return _InputField(
          ctrl: _venmoCtrl,
          hint: 'Venmo Username',
          onChanged: (_) => setState(() {}),
        );
      case _Platform.esewa:
        return _InputField(
          ctrl: _esewaCtrl,
          hint: 'eSewa ID / Mobile Number',
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
        );
    }
  }
}

// ── Platform selector card ────────────────────────────────────────────────────

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.platform,
    required this.selected,
    required this.onTap,
  });

  final _Platform platform;
  final bool selected;
  final VoidCallback onTap;

  static const _labels = {
    _Platform.bank: 'Bank A/C',
    _Platform.paypal: 'Paypal',
    _Platform.venmo: 'Venmo',
    _Platform.esewa: 'Esewa',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: DesignTokens.s8),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? DesignTokens.primaryGreen
                    : DesignTokens.borderDefault,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlatformIcon(platform: platform),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  _labels[platform]!,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 13, color: DesignTokens.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({required this.platform});
  final _Platform platform;

  @override
  Widget build(BuildContext context) {
    switch (platform) {
      case _Platform.bank:
        return Image.asset(
          'assets/images/creatordash/Institution.png',
          width: 46,
          height: 46,
          fit: BoxFit.contain,
        );
      case _Platform.paypal:
        return Image.asset(
          'assets/images/creatordash/paypal.png',
          width: 46,
          height: 46,
          fit: BoxFit.contain,
        );
      case _Platform.venmo:
        return Image.asset(
          'assets/images/creatordash/venmo.png',
          width: 46,
          height: 46,
          fit: BoxFit.contain,
        );
      case _Platform.esewa:
        return Image.asset(
          'assets/images/creatordash/esewa.png',
          width: 46,
          height: 46,
          fit: BoxFit.contain,
        );
    }
  }
}

// ── Form helpers ──────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.ctrl,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
  });

  final TextEditingController ctrl;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite),
      cursorColor: DesignTokens.primaryGreen,
      decoration: _dec(hint),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      dropdownColor: DesignTokens.bgAppBody,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: DesignTokens.textMuted),
      style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite),
      decoration: _dec(hint),
      items: items
          .map((i) => DropdownMenuItem<T>(
                value: i,
                child: Text(itemLabel(i)),
              ))
          .toList(),
    );
  }
}

InputDecoration _dec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: DesignTokens.textMuted,
      ),
      filled: true,
      fillColor: DesignTokens.bgAppBodyLight,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        borderSide: const BorderSide(color: DesignTokens.inputFieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        borderSide: const BorderSide(color: DesignTokens.primaryGreen),
      ),
    );
