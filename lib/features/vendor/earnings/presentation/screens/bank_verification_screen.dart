import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class BankVerificationScreen extends StatefulWidget {
  const BankVerificationScreen({super.key});

  @override
  State<BankVerificationScreen> createState() => _BankVerificationScreenState();
}

class _BankVerificationScreenState extends State<BankVerificationScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
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
        title: Text('Bank Verification', style: DesignTokens.oneLinerSemibold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(children: [
          const SizedBox(height: DesignTokens.s32),
          // Green shield icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: DesignTokens.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_outlined, color: Colors.black, size: 40),
          ),
          const SizedBox(height: DesignTokens.s20),
          Text('Enter OTP', style: DesignTokens.mediumSemibold.copyWith(fontSize: 20)),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Enter the OTP sent to your registered number\nto verify your bank account.',
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.s32),
          // OTP field
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DesignTokens.textMuted.withValues(alpha: 0.4),
                letterSpacing: 8,
              ),
              counterText: '',
              filled: true,
              fillColor: DesignTokens.bgAppBody,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: DesignTokens.s16),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Didn't receive OTP? ", style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 13)),
            GestureDetector(
              onTap: () {},
              child: Text('Resend', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ]),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: _otpController.text.length == 6
                  ? () => context.go(RouteNames.vendorEarnings)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                disabledBackgroundColor: DesignTokens.primaryGreen.withValues(alpha: 0.4),
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
}
