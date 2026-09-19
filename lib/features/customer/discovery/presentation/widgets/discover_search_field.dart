import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Discover search box: submit searches, edits drive live suggestions.
///
/// Speaking and scanning live in SearchInputActions beside the field, not
/// in it: both need a screen of their own for permission recovery, and the
/// voice transcript has to be reviewable before it searches.
class DiscoverSearchField extends StatelessWidget {
  const DiscoverSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  static const TextStyle _textStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      borderSide: BorderSide.none,
    );
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        key: const ValueKey('discover-search-field'),
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        style: _textStyle,
        cursorColor: DesignTokens.primaryGreen,
        decoration: InputDecoration(
          hintText: 'Search products, brands, creators',
          hintMaxLines: 1,
          hintStyle: _textStyle.copyWith(color: DesignTokens.textMuted),
          filled: true,
          fillColor: DesignTokens.surfaceRaised,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s12,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: DesignTokens.textMuted,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value.text.isNotEmpty)
                IconButton(
                  key: const ValueKey('discover-search-clear'),
                  tooltip: 'Clear search',
                  color: DesignTokens.textLight,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
                ),
            ],
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 48),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(
              color: DesignTokens.primaryGreen,
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
