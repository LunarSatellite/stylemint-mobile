import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Custom OTP/Code input field
/// Displays configurable number of individual digit inputs in a row
class AuthCodeField extends StatefulWidget {
  final ValueChanged<String> onCompleted;

  /// Fired on every digit change (entry or deletion). Lets the parent clear
  /// an error state as soon as the user starts correcting the code.
  final VoidCallback? onChanged;
  final bool enabled;

  /// When true, the digit boxes render with an error (red) border.
  final bool hasError;
  final int codeLength;

  const AuthCodeField({
    Key? key,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.hasError = false,
    this.codeLength = 5,
  }) : super(key: key);

  @override
  State<AuthCodeField> createState() => AuthCodeFieldState();
}

class AuthCodeFieldState extends State<AuthCodeField> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
      widget.codeLength,
      (index) => TextEditingController(),
    );
    focusNodes = List.generate(widget.codeLength, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleInput(String value, int index) {
    if (value.isNotEmpty) {
      // Only allow digits
      if (!RegExp(r'^\d$').hasMatch(value)) {
        controllers[index].clear();
        return;
      }

      // Move to next field
      if (index < widget.codeLength - 1) {
        focusNodes[index + 1].requestFocus();
      } else {
        // All fields filled - trigger callback
        final code = controllers.map((c) => c.text).join();
        widget.onCompleted(code);
        focusNodes[index].unfocus();
      }
    }
  }

  void _handleBackspace(int index) {
    if (index > 0 && controllers[index].text.isEmpty) {
      focusNodes[index - 1].requestFocus();
    }
  }

  String getCode() {
    return controllers.map((c) => c.text).join();
  }

  void clearCode() {
    for (var controller in controllers) {
      controller.clear();
    }
    focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    // In an error state every box (idle / enabled / focused) shows red.
    final restingBorderColor =
        widget.hasError ? DesignTokens.colorError : DesignTokens.inputFieldBorder;
    final focusedBorderColor =
        widget.hasError ? DesignTokens.colorError : DesignTokens.primaryGreen;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.codeLength, (index) {
        return Padding(
          padding: EdgeInsets.only(
            right: index == widget.codeLength - 1 ? 0 : DesignTokens.s8,
          ),
          child: SizedBox(
            width: 48,
            height: 48,
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              enabled: widget.enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              cursorColor: DesignTokens.primaryGreen,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              onChanged: (value) {
                widget.onChanged?.call();
                _handleInput(value, index);
                if (value.isEmpty && index > 0) {
                  _handleBackspace(index);
                }
              },
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: DesignTokens.inputFieldData,
                fontFamily: DesignTokens.fontFamily,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: DesignTokens.inputFieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide(color: restingBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide(color: restingBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide(
                    color: focusedBorderColor,
                    width: 1.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide(color: restingBorderColor),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        );
      }),
    );
  }
}
