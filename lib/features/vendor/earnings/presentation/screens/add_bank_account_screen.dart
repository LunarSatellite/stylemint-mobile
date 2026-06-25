import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class AddBankAccountScreen extends StatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _ifscController = TextEditingController();
  String? _selectedBankType;

  static const _bankTypes = ['Commercial Bank', 'Development Bank', 'Finance Company', 'Microfinance'];

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _holderNameController.dispose();
    _branchController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text('Add Bank A/C', style: DesignTokens.oneLinerSemibold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bank Details', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s4),
          Text('Enter your bank account details for payout.', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
          const SizedBox(height: DesignTokens.s20),

          _label('Bank Name'),
          _textField(controller: _bankNameController, hint: 'e.g. Bank of Kathmandu'),
          const SizedBox(height: DesignTokens.s16),

          _label('Bank Type'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBankType,
                hint: Text('Select bank type', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted)),
                isExpanded: true,
                dropdownColor: const Color(0xFF2C2C2E),
                icon: const Icon(Icons.keyboard_arrow_down, color: DesignTokens.textMuted),
                items: _bankTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite)))).toList(),
                onChanged: (val) => setState(() => _selectedBankType = val),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          _label('Account Number'),
          _textField(controller: _accountNumberController, hint: 'Enter account number', keyboardType: TextInputType.number),
          const SizedBox(height: DesignTokens.s16),

          _label('Account Holder Name'),
          _textField(controller: _holderNameController, hint: 'Enter full name as on bank record'),
          const SizedBox(height: DesignTokens.s16),

          _label('Branch Name'),
          _textField(controller: _branchController, hint: 'e.g. Kathmandu Main Branch'),
          const SizedBox(height: DesignTokens.s16),

          _label('SWIFT / IFSC Code'),
          _textField(controller: _ifscController, hint: 'Enter SWIFT or IFSC code'),
          const SizedBox(height: DesignTokens.s32),

          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: () => context.pushReplacement(RouteNames.vendorBankVerification),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('Submit', style: DesignTokens.smallRegular.copyWith(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
        ]),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s6),
      child: Text(text, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
    );
  }

  Widget _textField({required TextEditingController controller, required String hint, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
        filled: true,
        fillColor: DesignTokens.bgAppBody,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12, vertical: DesignTokens.s12),
      ),
    );
  }
}
