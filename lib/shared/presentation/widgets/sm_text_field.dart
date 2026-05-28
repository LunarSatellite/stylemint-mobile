import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../theme/colors.dart';

/// Style Mint primary text field — adapted from vpt-mydawa PrimaryFormField.
/// Supports label, hint, password toggle, prefix/suffix icons, validation.
class SmTextField extends HookWidget {
  const SmTextField({
    super.key,
    required this.onSaved,
    this.label,
    this.hintText,
    this.controller,
    this.labelSideWidget,
    this.hintIcon,
    this.isFilled = false,
    this.isRequired = false,
    this.borderRadius = 10.0,
    this.hintStyle,
    this.labelStyle,
    this.validator,
    this.onTap,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.autoFocus = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.focusNode,
    this.autoFillHints,
    this.initialValue,
    this.textColor = kTextColor,
    this.fillColor,
    this.focusedBorderColor,
    this.readOnly = false,
    this.inputFormatters,
    this.globalKey,
    this.textInputAction,
    this.onFieldSubmitted,
    this.textCapitalization,
    this.labelHeight,
  });

  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final Widget? labelSideWidget;
  final Widget? hintIcon;
  final bool isFilled;
  final bool isRequired;
  final double borderRadius;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final void Function(String value) onSaved;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool autoFocus;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final Iterable<String>? autoFillHints;
  final String? initialValue;
  final Color textColor;
  final Color? fillColor;
  final Color? focusedBorderColor;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final GlobalKey<FormFieldState>? globalKey;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization? textCapitalization;
  final double? labelHeight;

  @override
  Widget build(BuildContext context) {
    final obscure = useState(isPassword);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            children: [
              if (prefixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: prefixIcon!,
                ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: label!,
                      style: labelStyle ??
                          theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: kTextColor,
                          ),
                    ),
                    if (isRequired)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: kErrorColor),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              if (labelSideWidget != null) labelSideWidget!,
            ],
          ),
          SizedBox(height: labelHeight ?? 6),
        ],
        TextFormField(
          key: globalKey,
          controller: controller,
          initialValue: initialValue,
          focusNode: focusNode,
          autofocus: autoFocus,
          autofillHints: autoFillHints,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          obscureText: obscure.value,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          onTap: onTap,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          onSaved: (v) => onSaved(v ?? ''),
          style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
          decoration: InputDecoration(
            counterText: '',
            hintText: hintText,
            hintStyle: hintStyle,
            filled: isFilled || fillColor != null,
            fillColor: fillColor,
            prefixIcon: hintIcon,
            suffixIcon: isPassword
                ? GestureDetector(
                    onTap: () => obscure.value = !obscure.value,
                    child: Icon(
                      obscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: kGrey400,
                      size: 20,
                    ),
                  )
                : suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: kBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: focusedBorderColor ?? kPrimaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: kErrorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: kErrorColor, width: 1.5),
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}
