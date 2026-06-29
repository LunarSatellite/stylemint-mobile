import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class EditCategoryNicheScreen extends StatefulWidget {
  const EditCategoryNicheScreen({super.key});

  @override
  State<EditCategoryNicheScreen> createState() =>
      _EditCategoryNicheScreenState();
}

class _EditCategoryNicheScreenState extends State<EditCategoryNicheScreen> {
  static const List<String> _allCategories = [
    'Shoes',
    'Watches',
    'Electronics',
    'Sports Wear',
    'Fitness',
    'Home Appliances',
    'Mobile Accessories',
    'Beauty Products',
    'Jackets',
    "Women's Clothing",
    'Computers & Laptops',
    'Books & Magazines',
    'Skin Care',
    'Kitchen Supplies',
    "Men's Clothing",
    'Stationary',
    'Decorations',
    'Action Figures',
    "TV's",
    'Jewellery',
    'Keyboards',
    'Furniture',
  ];

  final Set<String> _selected = {'Electronics', 'Sports Wear', 'Fitness'};
  String _query = '';

  List<String> get _filtered {
    if (_query.trim().isEmpty) return _allCategories;
    final q = _query.trim().toLowerCase();
    return _allCategories
        .where((c) => c.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Category Niche',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s20,
            ),
            child: _SearchBar(
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16),
              child: Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                children: _filtered
                    .map(
                      (cat) => _CategoryChip(
                        label: cat,
                        isSelected: _selected.contains(cat),
                        onTap: () => setState(() {
                          if (_selected.contains(cat)) {
                            _selected.remove(cat);
                          } else {
                            _selected.add(cat);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              bottomPadding,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.textWhite,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Submit',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: DesignTokens.s8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 14,
          color: DesignTokens.textWhite,
        ),
        decoration: const InputDecoration(
          hintText: 'Search Category',
          hintStyle: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: DesignTokens.textMuted,
          ),
          suffixIcon: Icon(Icons.search_rounded,
              size: 20, color: DesignTokens.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.primaryGreen
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
    );
  }
}
