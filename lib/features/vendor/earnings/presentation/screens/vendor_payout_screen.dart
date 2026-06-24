import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorPayoutScreen extends StatefulWidget {
  const VendorPayoutScreen({super.key});

  @override
  State<VendorPayoutScreen> createState() => _VendorPayoutScreenState();
}

class _VendorPayoutScreenState extends State<VendorPayoutScreen> {
  final _amountController = TextEditingController();
  String? _selectedMethodId;

  static const _methods = [
    _PayoutMethod(id: '1', label: 'Bank of Kathmandu', accountInfo: 'A/C ******8799', isDefault: true),
    _PayoutMethod(id: '2', label: 'eSewa', accountInfo: '980*****12'),
    _PayoutMethod(id: '3', label: 'Nepal Investment Bank', accountInfo: 'A/C ******3421'),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selectedMethodId != null && _amountController.text.isNotEmpty;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text('Request Payout', style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            tooltip: 'Payment methods',
            icon: const Icon(Icons.account_balance_wallet_outlined, color: DesignTokens.textWhite),
            onPressed: () => context.push(RouteNames.vendorPaymentMethods),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Available balance
          Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: DesignTokens.cardDecoration(),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Available Balance', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted)),
              Text('Rs 8,24,224.95', style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.primaryGreen)),
            ]),
          ),
          const SizedBox(height: DesignTokens.s20),
          Text('Amount (NPR)', style: DesignTokens.h3),
          const SizedBox(height: DesignTokens.s8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: DesignTokens.titleLarge,
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: 'Rs ',
              filled: true,
              fillColor: DesignTokens.bgAppBody,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: DesignTokens.s24),
          Text('Payout Method', style: DesignTokens.h3),
          const SizedBox(height: DesignTokens.s8),
          Container(
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              children: _methods.asMap().entries.map((e) {
                final m = e.value;
                return Column(children: [
                  if (e.key > 0) const Divider(color: DesignTokens.borderDefault, height: 1),
                  RadioListTile<String>(
                    value: m.id,
                    groupValue: _selectedMethodId,
                    onChanged: (val) => setState(() => _selectedMethodId = val),
                    title: Row(children: [
                      Text(m.label, style: DesignTokens.oneLinerRegular),
                      if (m.isDefault) ...[
                        const SizedBox(width: DesignTokens.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF1A3A1A), borderRadius: BorderRadius.circular(4)),
                          child: Text('Default', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.primaryGreen, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ]),
                    subtitle: Text(m.accountInfo, style: DesignTokens.smallRegular),
                    activeColor: DesignTokens.primaryGreen,
                    tileColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12, vertical: DesignTokens.s4),
                  ),
                ]);
              }).toList(),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: canSubmit ? () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout requested!')));
                context.pop();
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                disabledBackgroundColor: DesignTokens.primaryGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('Confirm Payout', style: DesignTokens.smallRegular.copyWith(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
        ]),
      ),
    );
  }
}

class _PayoutMethod {
  const _PayoutMethod({required this.id, required this.label, required this.accountInfo, this.isDefault = false});
  final String id;
  final String label;
  final String accountInfo;
  final bool isDefault;
}
