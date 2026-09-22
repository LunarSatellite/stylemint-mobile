import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Custom OTP/Code input field.
///
/// Renders [codeLength] digit boxes, but they are **presentation only** — the
/// text lives in a single hidden [TextField] stretched across the row.
///
/// It used to be one real `TextField` per box, which broke editing in two
/// ways:
///
///  * Backspace in an already-empty box changes no text, so `onChanged` never
///    fired and focus never moved to the previous box. Correcting a code meant
///    tapping the boxes by hand.
///  * On the last digit the field called `unfocus()`, so after the code
///    auto-submitted nothing held focus and Backspace did nothing at all.
///
/// With one string behind the row, deletion is just deletion: it works at
/// every position, including straight after the code has been submitted.
/// It also lets iOS offer the SMS/email code above the keyboard
/// ([AutofillHints.oneTimeCode]), which cannot work across several
/// single-character fields, and makes pasting a whole code work.
class AuthCodeField extends StatefulWidget {
  final ValueChanged<String> onCompleted;

  /// Fired on every digit change (entry or deletion). Lets the parent clear
  /// an error state as soon as the user starts correcting the code.
  ///
  /// Only user edits fire this — [AuthCodeFieldState.clearCode] does not, so a
  /// caller can show an error and reset the boxes in either order.
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
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  static const double _boxSize = 48;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handleChanged(String value) {
    // The caret is never shown, so keep it pinned to the end — otherwise an
    // autofilled or pasted code can leave it mid-string and the next digit
    // lands in the wrong place.
    final end = TextSelection.collapsed(offset: value.length);
    if (_controller.selection != end) _controller.selection = end;

    setState(() {});
    widget.onChanged?.call();

    if (value.length == widget.codeLength) {
      // Deliberately NOT unfocusing here: dropping focus on the last digit is
      // what left the user unable to backspace a wrong code.
      widget.onCompleted(value);
    }
  }

  String getCode() => _controller.text;

  void clearCode() {
    // Programmatic — does not fire widget.onChanged, matching the behaviour
    // callers already rely on when showing a verification error.
    _controller.clear();
    if (mounted) setState(() {});
    _focusNode.requestFocus();
  }

  /// The box the next digit will land in, so it can carry the focused border.
  int get _activeIndex =>
      _controller.text.length.clamp(0, widget.codeLength - 1);

  @override
  Widget build(BuildContext context) {
    // In an error state every box (idle / enabled / focused) shows red.
    final restingBorderColor = widget.hasError
        ? DesignTokens.colorError
        : DesignTokens.inputFieldBorder;
    final focusedBorderColor = widget.hasError
        ? DesignTokens.colorError
        : DesignTokens.primaryGreen;

    final code = _controller.text;
    final hasFocus = _focusNode.hasFocus;

    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.codeLength, (index) {
            final filled = index < code.length;
            final isActive =
                hasFocus && widget.enabled && index == _activeIndex;
            return Padding(
              padding: EdgeInsets.only(
                right: index == widget.codeLength - 1 ? 0 : DesignTokens.s8,
              ),
              child: Container(
                width: _boxSize,
                height: _boxSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DesignTokens.inputFieldFill,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.inputRadius,
                  ),
                  border: Border.all(
                    color: isActive ? focusedBorderColor : restingBorderColor,
                    width: isActive ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  filled ? code[index] : '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.inputFieldData,
                    fontFamily: DesignTokens.fontFamily,
                  ),
                ),
              ),
            );
          }),
        ),
        // The real input: invisible, but stretched over the boxes so tapping
        // anywhere on the row opens the keyboard.
        Positioned.fill(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.codeLength),
            ],
            onChanged: _handleChanged,
            // Hidden, not absent: the text and caret are transparent and the
            // selection toolbar is off, so the boxes above are all the user
            // ever sees.
            showCursor: false,
            cursorColor: Colors.transparent,
            enableInteractiveSelection: false,
            style: const TextStyle(
              color: Colors.transparent,
              fontSize: 18,
              height: 1,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
              filled: false,
            ),
          ),
        ),
      ],
    );
  }
}
