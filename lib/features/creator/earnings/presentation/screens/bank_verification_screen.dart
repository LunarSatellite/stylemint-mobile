import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class BankVerificationScreen extends StatefulWidget {
  const BankVerificationScreen({super.key});

  @override
  State<BankVerificationScreen> createState() => _BankVerificationScreenState();
}

class _BankVerificationScreenState extends State<BankVerificationScreen> {
  static const _length = 5;
  static const _resendSeconds = 60;

  final _controllers = List.generate(_length, (_) => TextEditingController());
  final _focusNodes = List.generate(_length, (_) => FocusNode());

  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  bool get _isFilled => _controllers.every((c) => c.text.isNotEmpty);

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Bank Verification',
            style: DesignTokens.sectionInnerTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: DesignTokens.s32),
            Image.asset(
              'assets/images/doneicon.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: DesignTokens.s20),
            Text(
              'Enter OTP',
              style: DesignTokens.sectionInnerTitle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              "We've deposited a small amount into your entered account. "
              "Find it in your bank's mobile app statement and enter the "
              "code from the transaction description",
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight, height: 1.6),
            ),
            const SizedBox(height: DesignTokens.s32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_length, (i) {
                final isLast = i == _length - 1;
                return Row(
                  children: [
                    _OtpBox(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      onChanged: (v) => _onChanged(v, i),
                      onKeyEvent: (e) => _onKeyEvent(e, i),
                    ),
                    if (!isLast) const SizedBox(width: DesignTokens.s12),
                  ],
                );
              }),
            ),
            const SizedBox(height: DesignTokens.s24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Did not receive code? Resend in ',
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textLight),
                ),
                if (_secondsLeft > 0)
                  Text(
                    _timerLabel,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _startTimer,
                    child: Text(
                      'Resend',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
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
              onPressed: _isFilled ? () => context.pop() : null,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Submit',
                      style: DesignTokens.mediumSemibold
                          .copyWith(color: DesignTokens.buttonPrimaryText)),
                  const SizedBox(width: DesignTokens.s8),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: DesignTokens.buttonPrimaryText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: SizedBox(
        width: 52,
        height: 56,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          maxLength: 1,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textWhite,
          ),
          cursorColor: DesignTokens.primaryGreen,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: DesignTokens.bgAppBodyLight,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: DesignTokens.primaryGreen, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
