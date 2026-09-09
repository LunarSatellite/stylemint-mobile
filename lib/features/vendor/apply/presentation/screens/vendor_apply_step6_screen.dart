import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplyStep6Screen extends ConsumerStatefulWidget {
  const VendorApplyStep6Screen({super.key});

  @override
  ConsumerState<VendorApplyStep6Screen> createState() =>
      _VendorApplyStep6ScreenState();
}

class _VendorApplyStep6ScreenState
    extends ConsumerState<VendorApplyStep6Screen> {
  static const int _totalSteps = 6;
  static const int _currentStep = 6;

  bool _agreeTerms = false;
  bool _agreeCommission = false;
  bool _agreePayout = false;
  bool _agreeInventory = false;
  bool _isSubmitting = false;

  void _submit() {
    if (!_agreeTerms ||
        !_agreeCommission ||
        !_agreePayout ||
        !_agreeInventory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to all terms before submitting.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final draft = ref.read(vendorApplyDraftProvider);
    if (draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete Step 1 before submitting.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    unawaited(
      ref
          .read(vendorApplyNotifierProvider.notifier)
          .submit(draft.toForm(), draft.accountId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(vendorApplyDraftProvider);

    ref.listen(vendorApplyNotifierProvider, (_, next) {
      if (!_isSubmitting) return;
      next.whenOrNull(
        loadSuccess: (application) {
          setState(() => _isSubmitting = false);
          final submittedAt = application.submittedAt;
          context.go(
            Uri(
              path: RouteNames.vendorApplySubmitted,
              queryParameters: {
                'applicationId': application.id,
                if (submittedAt != null)
                  'submittedAt': DateFormat('MMM d, y').format(submittedAt),
              },
            ).toString(),
          );
        },
        loadFailure: (failure) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Submission failed: ${NetworkExceptions.getMessage(failure)}',
              ),
              backgroundColor: DesignTokens.colorError,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: Text(
          'Vendor Application',
          style: DesignTokens.oneLinerSemibold,
        ),
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.textWhite),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.vendorApplyStep5),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: DesignTokens.s16),
                    _buildSection(
                      title: 'Business Information',
                      stepRoute: RouteNames.vendorApply,
                      child: _buildBusinessInfo(draft),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _buildSection(
                      title: 'Contact Information',
                      stepRoute: RouteNames.vendorApplyStep2,
                      child: _buildContactInfo(draft),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _buildSection(
                      title: 'Documents Uploaded',
                      stepRoute: RouteNames.vendorApplyStep3,
                      child: _buildDocumentsInfo(draft),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _buildSection(
                      title: 'Banking & Tax Details',
                      stepRoute: RouteNames.vendorApplyStep4,
                      child: _buildBankingInfo(draft),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _buildSection(
                      title: 'Product Information',
                      stepRoute: RouteNames.vendorApplyStep5,
                      child: _buildProductInfo(draft),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    _buildTermsSection(),
                    const SizedBox(height: DesignTokens.s24),
                    _buildSubmitButton(),
                    const SizedBox(height: DesignTokens.s16),
                  ],
                ),
              ),
            ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s24,
      ),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Application',
            style: DesignTokens.sectionInnerTitle,
          ),
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
                onTap: () => context.push(stepRoute),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s12,
                    vertical: DesignTokens.s6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.buttonRadius,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit',
                        style: DesignTokens.smallRegular
                            .copyWith(fontWeight: FontWeight.w600)
                            .copyWith(color: DesignTokens.primaryGreen),
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

  Widget _placeholder(String text) => Text(
        text,
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      );

  Widget _buildBusinessInfo(VendorApplyDraft? draft) {
    if (draft == null) return _placeholder('Not filled — tap Edit');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(draft.brandName, style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s4),
        Text(
          '${draft.businessType.label}  •  Tax ID: ${draft.taxId}',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          '${draft.city}, ${draft.state}, ${draft.country}',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(VendorApplyDraft? draft) {
    if (draft == null || draft.contactFullName.isEmpty) {
      return _placeholder('Not filled — tap Edit');
    }
    final nameLine = draft.contactPosition.isEmpty
        ? draft.contactFullName
        : '${draft.contactFullName}, ${draft.contactPosition}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nameLine, style: DesignTokens.mediumSemibold),
        if (draft.contactEmail.isNotEmpty || draft.contactPhone.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            [
              if (draft.contactEmail.isNotEmpty) draft.contactEmail,
              if (draft.contactPhone.isNotEmpty) draft.contactPhone,
            ].join('  •  '),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
        if (draft.supportEmail.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Support: ${draft.supportEmail}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentsInfo(VendorApplyDraft? draft) {
    final docs = draft?.uploadedDocCategories ?? const [];
    if (docs.isEmpty) return _placeholder('No documents uploaded');
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

  Widget _buildBankingInfo(VendorApplyDraft? draft) {
    if (draft == null || draft.bankName.isEmpty) {
      return _placeholder('Not filled — tap Edit');
    }
    final bankLine = draft.accountType != null
        ? '${draft.bankName}  (${draft.accountType})'
        : draft.bankName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(bankLine, style: DesignTokens.mediumSemibold),
        if (draft.w9FileName != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            'W-9: ${draft.w9FileName}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductInfo(VendorApplyDraft? draft) {
    final categories = draft?.productCategories ?? const [];
    final hasData = categories.isNotEmpty ||
        draft?.catalogSize != null ||
        draft?.commissionMinRate != null;

    if (!hasData) return _placeholder('Not filled — tap Edit');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.isNotEmpty) ...[
          Text(
            'Categories',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: categories.map((cat) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                  vertical: DesignTokens.s6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F3F46),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.chipRadius,
                  ),
                ),
                child: Text(
                  cat,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: DesignTokens.s12),
        ],
        if (draft?.catalogSize != null)
          _buildInfoRow('Catalog Size', draft!.catalogSize!),
        if (draft?.minPrice != null && draft?.maxPrice != null) ...[
          const SizedBox(height: DesignTokens.s6),
          _buildInfoRow(
            'Price Range',
            '${draft!.minPrice} – ${draft.maxPrice}',
          ),
        ],
        if (draft?.commissionMinRate != null) ...[
          const SizedBox(height: DesignTokens.s6),
          _buildInfoRow(
            'Commission Range',
            '${draft!.commissionMinRate}% – ${draft.commissionMaxRate ?? '?'}%',
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
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
                color:
                    value ? DesignTokens.primaryGreen : Colors.transparent,
                border: Border.all(
                  color: value
                      ? DesignTokens.primaryGreen
                      : DesignTokens.borderDefault,
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
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: DesignTokens.primaryButtonStyle(),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DesignTokens.buttonPrimaryText,
                ),
              )
            : Text(
                'Submit Application',
                style: DesignTokens.oneLinerSemibold.copyWith(
                  color: DesignTokens.buttonPrimaryText,
                ),
              ),
      ),
    );
  }
}
