import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_sticky_bottom_bar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

const _kCountries = [
  'Nepal', 'United States', 'India', 'United Kingdom',
  'Australia', 'Canada', 'Germany', 'France', 'Japan', 'Singapore',
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class CreatorApplyScreen extends ConsumerStatefulWidget {
  const CreatorApplyScreen({super.key});

  @override
  ConsumerState<CreatorApplyScreen> createState() => _CreatorApplyScreenState();
}

class _CreatorApplyScreenState extends ConsumerState<CreatorApplyScreen> {
  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whyController   = TextEditingController();

  String? _selectedCountry;

  /// Selected content categories, keyed by backend GUID → display name.
  final Map<String, String> _selectedCategories = {};

  static const int _maxWhy = 500;

  bool get _canProceed =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty &&
      _selectedCountry != null &&
      _selectedCategories.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  void _proceed() {
    ref.read(creatorFormProvider.notifier).saveStep1(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          country: _selectedCountry ?? '',
          categories: _selectedCategories.values.toSet(),
          categoryIds: _selectedCategories.keys.toSet(),
          whyJoin: _whyController.text.trim(),
        );
    context.push(RouteNames.creatorApplySocial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s20,
          DesignTokens.s16, DesignTokens.s32,
        ),
        children: [
          // Personal Information card
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personal Information',
                    style: DesignTokens.sectionInnerTitle),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'We collect this information to verify your identity and '
                  'ensure the security of your account.',
                  style: DesignTokens.smallDescription,
                ),
                const SizedBox(height: DesignTokens.s24),
                _inputField(
                  controller: _nameController,
                  hint: 'Full Name',
                ),
                const SizedBox(height: DesignTokens.s12),
                _inputField(
                  controller: _emailController,
                  hint: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: DesignTokens.s12),
                _inputField(
                  controller: _phoneController,
                  hint: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: DesignTokens.s12),
                _countryDropdown(),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.s24),

          // Content Categories — loaded live from the backend so we submit
          // the real category GUIDs the API expects.
          const Text('Content Categories', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          ref.watch(creatorContentCategoriesProvider).when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.s16),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: DesignTokens.primaryGreen),
                  ),
                ),
                error: (_, _) => Row(
                  children: [
                    Expanded(
                      child: Text('Couldn’t load categories.',
                          style: DesignTokens.smallDescription),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(creatorContentCategoriesProvider),
                      child: const Text('Retry',
                          style: TextStyle(color: DesignTokens.primaryGreen)),
                    ),
                  ],
                ),
                data: (cats) => Wrap(
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s8,
                  children: cats.map((cat) {
                    final selected = _selectedCategories.containsKey(cat.id);
                    return _CategoryChip(
                      label: cat.name,
                      selected: selected,
                      onTap: () => setState(() {
                        selected
                            ? _selectedCategories.remove(cat.id)
                            : _selectedCategories[cat.id] = cat.name;
                      }),
                    );
                  }).toList(),
                ),
              ),

          const SizedBox(height: DesignTokens.s24),

          // Why join
          _whyTextArea(),
        ],
      ),
      bottomNavigationBar: SmStickyBottomBar(
        primaryLabel: 'Proceed',
        primaryEnabled: _canProceed,
        primaryTrailing: const Icon(Icons.arrow_forward_rounded,
            size: DesignTokens.iconSmall,
            color: DesignTokens.buttonPrimaryText),
        onPrimary: _proceed,
        showTopDivider: true,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: DesignTokens.bgAppFoundation,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: DesignTokens.textWhite),
        onPressed: () => context.go(RouteNames.userTypeSelection),
      ),
      title: const Text('Creator Form', style: DesignTokens.oneLinerSemibold),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16, 0, DesignTokens.s16, DesignTokens.s12),
          child: _StepBar(currentStep: 0, totalSteps: 3),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        color: DesignTokens.inputFieldData,
      ),
      cursorColor: DesignTokens.primaryGreen,
      onChanged: (_) => setState(() {}),
      decoration: DesignTokens.inputDecoration(hintText: hint),
    );
  }

  Widget _countryDropdown() {
    return Container(
        height: DesignTokens.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.inputFieldFill,
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          border: Border.all(color: DesignTokens.inputFieldBorder),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCountry,
            isExpanded: true,
            dropdownColor: DesignTokens.bgAppBody,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: DesignTokens.inputFieldDropdownIcon),
            hint: const Text(
              'Country/Region',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                color: DesignTokens.inputFieldPlaceholder,
              ),
            ),
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.inputFieldData,
            ),
            onChanged: (v) => setState(() => _selectedCountry = v),
            items: _kCountries
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
          ),
        ),
    );
  }

  Widget _whyTextArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _whyController,
          maxLines: 7,
          maxLength: _maxWhy,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: DesignTokens.inputFieldData,
            height: 1.5,
          ),
          cursorColor: DesignTokens.primaryGreen,
          onChanged: (_) => setState(() {}),
          decoration: DesignTokens.inputDecoration(
            hintText: 'Why do you want to join ReelCommerce ?',
          ).copyWith(
            counterText: '',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: DesignTokens.s4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${_whyController.text.length}/$_maxWhy',
            style: DesignTokens.smallRegular,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step bar — 3 horizontal segments, active = white, inactive = dimmed
// ---------------------------------------------------------------------------
class _StepBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepBar({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: i == currentStep
                  ? DesignTokens.textWhite
                  : DesignTokens.textWhite.withOpacity(0.25),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Personal Information card
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Category chip
// ---------------------------------------------------------------------------
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: selected ? DesignTokens.chipsSelectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
          border: Border.all(
            color: selected
                ? DesignTokens.chipsSelectedBorder
                : DesignTokens.chipsDefaultBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected
                ? DesignTokens.primaryGreen
                : DesignTokens.chipsDefaultText,
          ),
        ),
      ),
    );
  }
}
