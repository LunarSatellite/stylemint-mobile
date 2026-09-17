import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Discover search box: submit searches, edits drive live suggestions.
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
          fillColor: const Color(0xFF1A1E1B),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s12,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: DesignTokens.textMuted,
          ),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('discover-search-clear'),
                  tooltip: 'Clear search',
                  color: DesignTokens.textLight,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClear,
                ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(
              color: Color(0x9932D477),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
