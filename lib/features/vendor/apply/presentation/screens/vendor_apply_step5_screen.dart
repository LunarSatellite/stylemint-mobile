import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplyStep5Screen extends ConsumerStatefulWidget {
  const VendorApplyStep5Screen({super.key});

  @override
  ConsumerState<VendorApplyStep5Screen> createState() =>
      _VendorApplyStep5ScreenState();
}

class _VendorApplyStep5ScreenState
    extends ConsumerState<VendorApplyStep5Screen> {
  static const int _totalSteps = 6;
  static const int _currentStep = 5;

  static const _categories = [
    'Shoes', 'Watches', 'Electronics', 'Sports Wear', 'Fitness',
    'Home Appliances', 'Mobile Accessories', 'Beauty Products', 'Jackets',
    'Women\'s Clothing', 'Computers & Laptops', 'Books & Magazines',
    'Skin Care', 'Kitchen Supplies', 'Men\'s Clothing', 'Stationary',
    'Decorations', 'Action Figures', 'TV\'s', 'Jewellery', 'Keyboards',
    'Furniture',
  ];

  static const _catalogSizes = [
    '1-10 products',
    '11-50 products',
    '51-100 products',
    '101-500 products',
    '500+ products',
  ];

  final _selectedCategories = <String>{};
  String? _selectedCatalogSize;

  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _commissionMinController = TextEditingController();
  final _commissionMaxController = TextEditingController();
  final _brandStoryController = TextEditingController();

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _commissionMinController.dispose();
    _commissionMaxController.dispose();
    _brandStoryController.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _showCatalogSizePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: DesignTokens.s12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Estimated Product Catalog Size',
                    style: DesignTokens.oneLinerSemibold),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _catalogSizes.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: DesignTokens.borderDefault, height: 1),
                itemBuilder: (_, i) => ListTile(
                  title: Text(_catalogSizes[i], style: DesignTokens.oneLinerRegular),
                  onTap: () {
                    setState(() => _selectedCatalogSize = _catalogSizes[i]);
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
          ],
        ),
      ),
    ).ignore();
  }

  void _proceed() {
    final current = ref.read(vendorApplyDraftProvider);
    if (current != null) {
      final minP = _minPriceController.text.trim();
      final maxP = _maxPriceController.text.trim();
      final commissionMin = _commissionMinController.text.trim();
      final commissionMax = _commissionMaxController.text.trim();
      final story = _brandStoryController.text.trim();
      ref.read(vendorApplyDraftProvider.notifier).draft = current.copyWith(
        productCategories: _selectedCategories.toList(growable: false),
        catalogSize: _selectedCatalogSize,
        minPrice: minP.isEmpty ? null : minP,
        maxPrice: maxP.isEmpty ? null : maxP,
        commissionMinRate: commissionMin.isEmpty ? null : commissionMin,
        commissionMaxRate: commissionMax.isEmpty ? null : commissionMax,
        brandStory: story.isEmpty ? null : story,
      );
    }
    unawaited(context.push(RouteNames.vendorApplyStep6));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: Text('Vendor Application', style: DesignTokens.oneLinerSemibold),
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.textWhite),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: DesignTokens.textWhite),
          onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RouteNames.vendorApplyStep4),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s8,
                ),
                child: _buildFormCard(),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(
                right: index < _totalSteps - 1 ? DesignTokens.s4 : 0,
              ),
              decoration: BoxDecoration(
                color: index < _currentStep
                    ? DesignTokens.primaryGreen
                    : DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s24,
      ),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Information', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'This helps us target creators for partnerships and potential customers to boost sales',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s20),

          // Category chips
          Text(
            'What will you be selling? (Select all that apply)',
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: _categories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return GestureDetector(
                onTap: () => _toggleCategory(category),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s12,
                    vertical: DesignTokens.s8,
                  ),
                  decoration: isSelected
                      ? DesignTokens.chipDecorationSelected()
                      : DesignTokens.chipDecorationDefault(),
                  child: Text(
                    category,
                    style: DesignTokens.smallRegular.copyWith(
                      color: isSelected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textLight,
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: DesignTokens.s16),

          // Catalog size dropdown
          GestureDetector(
            onTap: _showCatalogSizePicker,
            child: Container(
              height: DesignTokens.inputHeight,
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.inputFieldFill,
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                border: Border.all(color: DesignTokens.inputFieldBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCatalogSize ?? 'Estimated Product Catalog Size',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        color: _selectedCatalogSize != null
                            ? DesignTokens.inputFieldData
                            : DesignTokens.inputFieldPlaceholder,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: DesignTokens.inputFieldDropdownIcon,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          // Price range
          Text(
            'Average Product Price Range',
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  style: DesignTokens.oneLinerRegular.copyWith(
                    color: DesignTokens.inputFieldData,
                  ),
                  decoration: DesignTokens.inputDecoration(hintText: 'Min.'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                ),
                child: Text(
                  '—',
                  style: DesignTokens.oneLinerRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  style: DesignTokens.oneLinerRegular.copyWith(
                    color: DesignTokens.inputFieldData,
                  ),
                  decoration: DesignTokens.inputDecoration(hintText: 'Max'),
                ),
              ),
            ],
          ),

          const SizedBox(height: DesignTokens.s24),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          const SizedBox(height: DesignTokens.s20),

          // Creator Commission Settings
          Text('Creator Commission Settings', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commissionMinController,
                  keyboardType: TextInputType.number,
                  style: DesignTokens.oneLinerRegular.copyWith(
                    color: DesignTokens.inputFieldData,
                  ),
                  decoration: DesignTokens.inputDecoration(hintText: 'Min %'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                ),
                child: Text(
                  '—',
                  style: DesignTokens.oneLinerRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _commissionMaxController,
                  keyboardType: TextInputType.number,
                  style: DesignTokens.oneLinerRegular.copyWith(
                    color: DesignTokens.inputFieldData,
                  ),
                  decoration: DesignTokens.inputDecoration(hintText: 'Max %'),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: DesignTokens.textMuted,
                size: 14,
              ),
              const SizedBox(width: DesignTokens.s4),
              Expanded(
                child: Text(
                  'Recommended rate is 12%-18%. You can adjust commission rates per product later',
                  style: DesignTokens.smallRegular,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),

          // Brand Story
          TextField(
            controller: _brandStoryController,
            maxLines: 6,
            maxLength: 500,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Brand Story (Optional)',
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                color: DesignTokens.textMuted,
                size: 14,
              ),
              const SizedBox(width: DesignTokens.s4),
              Expanded(
                child: Text(
                  'Tell creators and customers about your brand in 500 characters',
                  style: DesignTokens.smallRegular,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      color: DesignTokens.bgAppFoundation,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s16,
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RouteNames.vendorApplyStep4),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F3F46),
                foregroundColor: DesignTokens.textWhite,
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                ),
                minimumSize: const Size(0, DesignTokens.buttonHeight),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 18),
                  const SizedBox(width: DesignTokens.s8),
                  Text('Previous', style: DesignTokens.oneLinerSemibold),
                ],
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: ElevatedButton(
              onPressed: _proceed,
              style: DesignTokens.primaryButtonStyle(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Proceed',
                    style: DesignTokens.oneLinerSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  const Icon(
                    Icons.arrow_forward,
                    color: DesignTokens.buttonPrimaryText,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
