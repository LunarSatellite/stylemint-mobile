import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplyStep6Screen extends StatefulWidget {
  const VendorApplyStep6Screen({super.key});

  @override
  State<VendorApplyStep6Screen> createState() => _VendorApplyStep6ScreenState();
}

class _VendorApplyStep6ScreenState extends State<VendorApplyStep6Screen> {
  static const int _totalSteps = 6;
  static const int _currentStep = 6;

  bool _agreeTerms = false;
  bool _agreeCommission = false;
  bool _agreePayout = false;
  bool _agreeInventory = false;

  void _submit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application submitted successfully!'),
        backgroundColor: DesignTokens.primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: DesignTokens.s16),
                    _buildSection(
                      title: 'Business Information',
                      stepRoute: RouteNames.vendorApply,
                      child: _buildBusinessInfo(),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _buildSection(
                      title: 'Contact Information',
                      stepRoute: RouteNames.vendorApplyStep2,
                      child: _buildContactInfo(),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _buildSection(
                      title: 'Documents Uploaded',
                      stepRoute: RouteNames.vendorApplyStep3,
                      child: _buildDocumentsInfo(),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _buildSection(
                      title: 'Banking & Tax Details',
                      stepRoute: RouteNames.vendorApplyStep4,
                      child: _buildBankingInfo(),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _buildSection(
                      title: 'Product Information',
                      stepRoute: RouteNames.vendorApplyStep5,
                      child: _buildProductInfo(),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    _buildTermsSection(),
                    const SizedBox(height: DesignTokens.s24),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s20),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Your Application', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Review the details you entered before submission',
            style: DesignTokens.smallRegular,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String stepRoute,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: DesignTokens.mediumSemibold),
              ),
              GestureDetector(
                onTap: () => context.go(stepRoute),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s12,
                    vertical: DesignTokens.s6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit',
                        style: DesignTokens.smallRegular.copyWith(fontWeight: FontWeight.w600).copyWith(
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s4),
                      const Icon(
                        Icons.edit,
                        color: DesignTokens.primaryGreen,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          const SizedBox(height: DesignTokens.s12),
          child,
        ],
      ),
    );
  }

  Widget _buildBusinessInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nike Official Store LLC', style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Corporation  •  EIN: 12-523637',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Beaverton, Oregon, USA',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('John Smith, VP of E-Commerce', style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'john@nike.com  •  +1 503-555-1234',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Support: support@nike.com',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
        ),
      ],
    );
  }

  Widget _buildDocumentsInfo() {
    const docs = [
      'Business License',
      'Tax Certificate',
      'Proof of Address',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: docs.map((doc) {
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s6),
          child: Row(
            children: [
              Text(
                '•  ',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              Text(
                doc,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  decoration: TextDecoration.underline,
                  decorationColor: DesignTokens.primaryGreen,
                ),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildBankingInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chase Bank  (******4532)', style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'W-9 Form Uploaded',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    const selectedCategories = ['Sports', 'Fitness', 'Footwear'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Categories',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s8),
        Wrap(
          spacing: DesignTokens.s8,
          runSpacing: DesignTokens.s8,
          children: selectedCategories.map((cat) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
                vertical: DesignTokens.s6,
              ),
              decoration: DesignTokens.chipDecorationSelected(),
              child: Text(
                cat,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: DesignTokens.s12),
        _buildInfoRow('Catalog Size', '100-500 Products'),
        const SizedBox(height: DesignTokens.s6),
        _buildInfoRow('Price Range', '\$50 – \$1,200'),
        const SizedBox(height: DesignTokens.s6),
        _buildInfoRow('Default Commission', '15%'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
        ),
        Text(value, style: DesignTokens.smallRegular.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Terms & Conditions', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Please review and agree to the following before submitting',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s16),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          const SizedBox(height: DesignTokens.s12),
          _buildTermsCheckbox(
            value: _agreeTerms,
            onChanged: (v) => setState(() => _agreeTerms = v ?? false),
            text: 'I agree to ReelCommerce ',
            linkText: 'Vendor Terms of Service',
          ),
          const SizedBox(height: DesignTokens.s12),
          _buildTermsCheckbox(
            value: _agreeCommission,
            onChanged: (v) => setState(() => _agreeCommission = v ?? false),
            text: 'I agree to the ',
            linkText: 'Commission Structure',
          ),
          const SizedBox(height: DesignTokens.s12),
          _buildTermsCheckbox(
            value: _agreePayout,
            onChanged: (v) => setState(() => _agreePayout = v ?? false),
            text: 'I understand the ',
            linkText: 'Weekly Payout Schedule',
          ),
          const SizedBox(height: DesignTokens.s12),
          _buildTermsCheckbox(
            value: _agreeInventory,
            onChanged: (v) => setState(() => _agreeInventory = v ?? false),
            text: 'I agree to maintain inventory and fulfill orders',
            linkText: null,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
    required String? linkText,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? DesignTokens.primaryGreen : Colors.transparent,
                border: Border.all(
                  color: value ? DesignTokens.primaryGreen : DesignTokens.borderDefault,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.black, size: 13)
                  : null,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DesignTokens.smallRegular,
                children: [
                  TextSpan(text: text),
                  if (linkText != null)
                    TextSpan(
                      text: linkText,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.primaryGreen,
                        decoration: TextDecoration.underline,
                        decorationColor: DesignTokens.primaryGreen,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      color: DesignTokens.bgAppFoundation,
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
          onPressed: _submit,
          style: DesignTokens.primaryButtonStyle(),
          child: Text(
            'Submit Application',
            style: DesignTokens.oneLinerSemibold.copyWith(
              color: DesignTokens.buttonPrimaryText,
            ),
          ),
        ),
      ),
    );
  }
}
