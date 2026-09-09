import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplyStep2Screen extends ConsumerStatefulWidget {
  const VendorApplyStep2Screen({super.key});

  @override
  ConsumerState<VendorApplyStep2Screen> createState() =>
      _VendorApplyStep2ScreenState();
}

class _VendorApplyStep2ScreenState
    extends ConsumerState<VendorApplyStep2Screen> {
  static const int _totalSteps = 6;
  static const int _currentStep = 2;

  static const _businessHourOptions = [
    'Monday - Friday (9:00 AM to 6:00 PM EST)',
    'Saturday (10:00 AM to 4:00 PM EST)',
    'Sunday - Closed',
  ];

  final _supportEmailController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _returnPolicyController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _positionController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _selectedHours = <String>{};

  @override
  void initState() {
    super.initState();
    // Re-entering this step pushes a brand-new screen instance, so without
    // this the fields silently reset to empty even though the draft already
    // has the values from the last time this step was filled in.
    final draft = ref.read(vendorApplyDraftProvider);
    if (draft != null) {
      _supportEmailController.text = draft.supportEmail;
      _supportPhoneController.text = draft.supportPhone;
      _returnPolicyController.text = draft.returnPolicyUrl ?? '';
      _fullNameController.text = draft.contactFullName;
      _positionController.text = draft.contactPosition;
      _emailController.text = draft.contactEmail;
      _phoneController.text = draft.contactPhone;
      _selectedHours.addAll(draft.businessHours);
    }
  }

  @override
  void dispose() {
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _returnPolicyController.dispose();
    _fullNameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Shared by both Previous and Proceed — losing whatever's been typed here
  // just because the user stepped back to fix something on an earlier step
  // is exactly the bug this method exists to prevent.
  void _saveDraft() {
    final current = ref.read(vendorApplyDraftProvider);
    if (current != null) {
      final policy = _returnPolicyController.text.trim();
      ref.read(vendorApplyDraftProvider.notifier).draft = current.copyWith(
        supportEmail: _supportEmailController.text.trim(),
        supportPhone: _supportPhoneController.text.trim(),
        returnPolicyUrl: policy.isEmpty ? null : policy,
        contactFullName: _fullNameController.text.trim(),
        contactPosition: _positionController.text.trim(),
        contactEmail: _emailController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        businessHours: _selectedHours.toList(growable: false),
      );
    }
  }

  void _proceed() {
    _saveDraft();
    unawaited(context.push(RouteNames.vendorApplyStep3));
  }

  void _goPrevious() {
    _saveDraft();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.vendorApply);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: _goPrevious,
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
          Text('Contact Information', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'We collect this information to verify your identity and ensure'
            ' the security of your account.',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s32),

          TextField(
            controller: _supportEmailController,
            keyboardType: TextInputType.emailAddress,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Support Email Address',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _supportPhoneController,
            keyboardType: TextInputType.phone,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Support Phone',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _returnPolicyController,
            keyboardType: TextInputType.url,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Return/Refund Policy URL',
            ),
          ),

          const SizedBox(height: DesignTokens.s20),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          const SizedBox(height: DesignTokens.s20),

          Text('Primary Contact Person', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s16),

          TextField(
            controller: _fullNameController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(hintText: 'Full Name'),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _positionController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Position/Title',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Email Address',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Phone Number',
            ),
          ),

          const SizedBox(height: DesignTokens.s20),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          const SizedBox(height: DesignTokens.s20),

          Text(
            'Business Hours (Customer Support)',
            style: DesignTokens.mediumSemibold,
          ),
          const SizedBox(height: DesignTokens.s12),

          ..._businessHourOptions.map((option) {
            final isSelected = _selectedHours.contains(option);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _selectedHours.remove(option);
                } else {
                  _selectedHours.add(option);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s12),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DesignTokens.primaryGreen
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected
                              ? DesignTokens.primaryGreen
                              : DesignTokens.borderDefault,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: DesignTokens.buttonPrimaryText,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Text(
                        option,
                        style: DesignTokens.mediumRegular.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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
              onPressed: _goPrevious,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F3F46),
                foregroundColor: DesignTokens.textWhite,
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.s16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
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
