import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class RequestCreateSheet extends StatefulWidget {
  const RequestCreateSheet({required this.onSubmit, super.key});

  final void Function(String question, String? context, List<String>? categories)
      onSubmit;

  @override
  State<RequestCreateSheet> createState() => _RequestCreateSheetState();
}

class _RequestCreateSheetState extends State<RequestCreateSheet> {
  final _questionController = TextEditingController();
  final _contextController = TextEditingController();
  String? _selectedCategory;

  static const _categories = [
    'Streetwear',
    'Vintage',
    'Minimalist',
    'Luxury',
    'Y2K',
    'Gorpcore',
    'K-pop',
    'Formal',
    'Athleisure',
    'Business Casual',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        MediaQuery.of(context).viewInsets.bottom + DesignTokens.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Text(
            'Ask a Question',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s16),
          TextField(
            controller: _questionController,
            maxLines: 3,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              hintText: 'What style advice do you need?',
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          TextField(
            controller: _contextController,
            maxLines: 2,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              hintText: 'Add context (optional)',
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            'Category (optional)',
            style: DesignTokens.mediumSemibold,
          ),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s6,
            runSpacing: DesignTokens.s6,
            children:
                _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap:
                        () => setState(
                          () =>
                              _selectedCategory =
                                  isSelected ? null : cat,
                        ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s12,
                        vertical: DesignTokens.s6,
                      ),
                      decoration: isSelected
                          ? DesignTokens.chipDecorationSelected()
                          : DesignTokens.chipDecorationDefault(),
                      child: Text(
                        cat,
                        style: DesignTokens.smallRegular.copyWith(
                          color: isSelected
                              ? DesignTokens.primaryGreen
                              : DesignTokens.chipsDefaultText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: DesignTokens.s20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final question = _questionController.text.trim();
                if (question.isEmpty) return;
                widget.onSubmit(
                  question,
                  _contextController.text.trim().isEmpty
                      ? null
                      : _contextController.text.trim(),
                  _selectedCategory != null ? [_selectedCategory!] : null,
                );
                Navigator.of(context).pop();
              },
              style: DesignTokens.primaryButtonStyle(),
              child: const Text('Ask'),
            ),
          ),
        ],
      ),
    );
  }
}
