import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class Step1BasicInfoScreen extends ConsumerStatefulWidget {
  const Step1BasicInfoScreen({super.key});

  @override
  ConsumerState<Step1BasicInfoScreen> createState() =>
      _Step1BasicInfoScreenState();
}

class _Step1BasicInfoScreenState extends ConsumerState<Step1BasicInfoScreen> {
  late TextEditingController _nameController;
  // MOCK/local — BasicInfo has no `sku` / `shortDescription` field yet, so
  // these are collected but not persisted (TODO: add to the entity + DTO).
  late TextEditingController _skuController;
  late TextEditingController _shortDescController;
  late TextEditingController _descriptionController; // Full Description
  late TextEditingController _brandController;
  late TextEditingController _tagController;
  final List<String> _selectedCategories = [];
  final List<String> _tags = [];

  // Spec counter: "n/max Characters".
  static Widget? _counter(BuildContext context,
      {required int currentLength, required int? maxLength, required bool isFocused}) {
    return Text('$currentLength/$maxLength Characters',
        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight));
  }

  static const _categories = [
    'Electronics',
    'Fashion',
    'Home',
    'Beauty',
    'Sports',
    'Food',
    'Books',
    'Toys',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _skuController = TextEditingController();
    _shortDescController = TextEditingController();
    _descriptionController = TextEditingController();
    _brandController = TextEditingController();
    _tagController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _shortDescController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }

  void _onNext() {
    final info = BasicInfo(
      productName: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      categories: List.from(_selectedCategories),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      tags: List.from(_tags),
    );
    ref.read(addProductNotifierProvider.notifier).updateBasicInfo(info);
    ref.read(addProductNotifierProvider.notifier).nextStep();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s20),
          TextField(
            controller: _nameController,
            maxLength: 100,
            buildCounter: _counter,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              labelText: 'Product Name',
              hintText: 'Enter product name',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          TextField(
            controller: _skuController,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              labelText: 'SKU (Stock Keeping Unit)',
              hintText: 'e.g. SM-CAKE-001',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          TextField(
            controller: _shortDescController,
            maxLines: 2,
            maxLength: 200,
            buildCounter: _counter,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              labelText: 'Short Description',
              hintText: 'A one-line summary',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 2000,
            buildCounter: _counter,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              labelText: 'Full Description',
              hintText: 'Describe your product',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),
          Text('Categories', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: _categories.map((cat) {
              final selected = _selectedCategories.contains(cat);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedCategories.remove(cat);
                    } else {
                      _selectedCategories.add(cat);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s8,
                  ),
                  decoration: selected
                      ? DesignTokens.chipDecorationSelected()
                      : DesignTokens.chipDecorationDefault(),
                  child: Text(
                    cat,
                    style: DesignTokens.mediumRegular.copyWith(
                      color: selected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.chipsDefaultText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: DesignTokens.s20),
          TextField(
            controller: _brandController,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              labelText: 'Brand (optional)',
              hintText: 'Enter brand name',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),
          Text('Tags', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  style: DesignTokens.bodyText,
                  decoration: DesignTokens.inputDecoration(
                    hintText: 'Add a tag',
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              IconButton(
                icon: const Icon(Icons.add_circle,
                    color: DesignTokens.primaryGreen),
                onPressed: _addTag,
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag,
                      style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite)),
                  backgroundColor: DesignTokens.bgAppBodyLight,
                  deleteIcon: const Icon(Icons.close,
                      size: 16, color: DesignTokens.textMuted),
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                  },
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: DesignTokens.s32),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty ||
                    _descriptionController.text.trim().isEmpty ||
                    _selectedCategories.isEmpty) return;
                _onNext();
              },
              style: DesignTokens.primaryButtonStyle(),
              child: Text('Next',
                  style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText)),
            ),
          ),
        ],
      ),
    );
  }
}
