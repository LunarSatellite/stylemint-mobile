import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/notifiers/add_product_notifier.dart';
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
  late TextEditingController _skuController;
  late TextEditingController _brandController;
  late TextEditingController _shortDescController;
  late TextEditingController _descriptionController;
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  static Widget? _counter(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) {
    return Text(
      '$currentLength/$maxLength Characters',
      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _skuController = TextEditingController();
    _brandController = TextEditingController();
    _shortDescController = TextEditingController();
    _descriptionController = TextEditingController();
    // Edit-mode pre-population: when the wizard mounts in Edit mode the
    // notifier already has step1 populated from the backend
    // (loadForEdit ran before this screen was built). Pull the data here
    // so the controllers don't start blank. Safe to call in Create mode
    // too — step1 is null on a fresh wizard, so nothing is copied.
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromState());
  }

  void _hydrateFromState() {
    if (!mounted) return;
    final fs = ref.read(addProductNotifierProvider).maybeWhen(
          loadSuccess: (s) => s,
          orElse: () => null,
        );
    final info = fs?.step1;
    if (info == null) return;
    setState(() {
      _nameController.text = info.productName;
      _shortDescController.text = info.shortDescription;
      _descriptionController.text = info.description;
      _selectedCategoryId =
          info.categoryId.isEmpty ? null : info.categoryId;
      _selectedCategoryName = info.categories.isEmpty
          ? null
          : info.categories.first;
      _brandController.text = info.brand ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _brandController.dispose();
    _shortDescController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onNext() {
    final info = BasicInfo(
      productName: _nameController.text.trim(),
      shortDescription: _shortDescController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: _selectedCategoryId ?? '',
      categories: _selectedCategoryName != null
          ? [_selectedCategoryName!]
          : const [],
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      tags: const [],
    );
    ref.read(addProductNotifierProvider.notifier).updateBasicInfo(info);
    ref.read(addProductNotifierProvider.notifier).nextStep();
  }

  bool get _canProceed =>
      _nameController.text.trim().isNotEmpty &&
      _shortDescController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      _selectedCategoryId != null;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(productCategoriesProvider);

    // If the categories load after mount and the selected one was
    // previously stored by id only, fill in the display name once it
    // becomes available.
    categoriesAsync.whenData((categories) {
      if (_selectedCategoryId != null && _selectedCategoryName == null) {
        final match = categories.where((c) => c.id == _selectedCategoryId);
        if (match.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedCategoryName = match.first.name);
          });
        }
      }
    });

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Container(
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Information',
                    style: DesignTokens.sectionInnerTitle,
                  ),
                  const SizedBox(height: DesignTokens.s20),

                  // Product Name
                  TextField(
                    controller: _nameController,
                    maxLength: 100,
                    buildCounter: _counter,
                    style: DesignTokens.bodyText,
                    onChanged: (_) => setState(() {}),
                    decoration: DesignTokens.inputDecoration(
                      labelText: 'Product Name',
                      hintText: 'Enter product name',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // SKU
                  TextField(
                    controller: _skuController,
                    style: DesignTokens.bodyText,
                    decoration: DesignTokens.inputDecoration(
                      labelText: 'SKU (Stock Keeping Unit)',
                      hintText: 'e.g. SM-CAKE-001',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // Category â€" dropdown
                  categoriesAsync.when(
                    loading: () => const _CategoryShell(
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    error: (e, _) => _CategoryShell(
                      child: Text(
                        'Failed to load categories',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.colorError,
                        ),
                      ),
                    ),
                    data: (categories) => _CategoryShell(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryId,
                          hint: Text(
                            'Select category',
                            style: DesignTokens.mediumRegular.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                          isExpanded: true,
                          dropdownColor: DesignTokens.bgAppBodyLight,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: DesignTokens.textMuted,
                          ),
                          style: DesignTokens.mediumRegular.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                          items: categories
                              .map(
                                (cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Text(cat.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _selectedCategoryId = v;
                              _selectedCategoryName = categories
                                  .firstWhere((c) => c.id == v)
                                  .name;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // Brand (optional)
                  TextField(
                    controller: _brandController,
                    style: DesignTokens.bodyText,
                    decoration: DesignTokens.inputDecoration(
                      labelText: 'Brand (optional)',
                      hintText: 'Enter brand name',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // Short Description
                  TextField(
                    controller: _shortDescController,
                    maxLines: 2,
                    maxLength: 200,
                    buildCounter: _counter,
                    style: DesignTokens.bodyText,
                    onChanged: (_) => setState(() {}),
                    decoration: DesignTokens.inputDecoration(
                      labelText: 'Short Description',
                      hintText: 'A one-line summary',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // Full Description
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    maxLength: 2000,
                    buildCounter: _counter,
                    style: DesignTokens.bodyText,
                    onChanged: (_) => setState(() {}),
                    decoration: DesignTokens.inputDecoration(
                      labelText: 'Full Description',
                      hintText: 'Describe your product',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                ],
              ),
            ),
          ),
        ),

        // Fixed Proceed button at bottom
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: _canProceed ? _onNext : null,
                style: DesignTokens.primaryButtonStyle(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: DesignTokens.buttonPrimaryText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryShell extends StatelessWidget {
  const _CategoryShell({required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        border: Border.all(color: borderColor ?? DesignTokens.borderDefault),
      ),
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: child,
    );
  }
}