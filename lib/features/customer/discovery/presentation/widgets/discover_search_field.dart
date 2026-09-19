import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Discover search box: submit searches, edits drive live suggestions.
class DiscoverSearchField extends StatefulWidget {
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

  @override
  State<DiscoverSearchField> createState() => _DiscoverSearchFieldState();
}

class _DiscoverSearchFieldState extends State<DiscoverSearchField> {
  static const TextStyle _textStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  final SpeechToText _speech = SpeechToText();
  bool _listening = false;

  Future<void> _toggleVoiceSearch() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        final active = status == 'listening';
        if (_listening != active) setState(() => _listening = active);
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Voice search is unavailable. You can still type your search.',
          ),
        ),
      );
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        widget.controller.value = TextEditingValue(
          text: words,
          selection: TextSelection.collapsed(offset: words.length),
        );
        widget.onChanged(words);
        if (result.finalResult) widget.onSubmitted(words);
      },
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        listenMode: ListenMode.search,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_speech.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      borderSide: BorderSide.none,
    );
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) => TextField(
        key: const ValueKey('discover-search-field'),
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
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
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value.text.isNotEmpty)
                IconButton(
                  key: const ValueKey('discover-search-clear'),
                  tooltip: 'Clear search',
                  color: DesignTokens.textLight,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: widget.onClear,
                ),
              IconButton(
                key: const ValueKey('discover-voice-search'),
                tooltip: _listening ? 'Stop listening' : 'Search by voice',
                color: _listening
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textLight,
                icon: Icon(
                  _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                ),
                onPressed: _toggleVoiceSearch,
              ),
            ],
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 48),
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
