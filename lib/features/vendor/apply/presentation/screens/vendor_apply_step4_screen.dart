import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplyStep4Screen extends ConsumerStatefulWidget {
  const VendorApplyStep4Screen({super.key});

  @override
  ConsumerState<VendorApplyStep4Screen> createState() =>
      _VendorApplyStep4ScreenState();
}

class _VendorApplyStep4ScreenState
    extends ConsumerState<VendorApplyStep4Screen> {
  static const int _totalSteps = 6;
  static const int _currentStep = 4;

  static const _accountTypes = ['Checking', 'Savings'];

  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _routingController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountController = TextEditingController();

  String? _selectedAccountType;
  String? _w9FileName;
  String? _w9FileSize;
  bool _uploadingW9 = false;
  bool _taxCertified = false;

  @override
  void dispose() {
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _routingController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    super.dispose();
  }

  void _showPickerSheet() {
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
                child: Text('Account Type', style: DesignTokens.oneLinerSemibold),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _accountTypes.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: DesignTokens.borderDefault, height: 1),
                itemBuilder: (_, i) => ListTile(
                  title: Text(_accountTypes[i], style: DesignTokens.oneLinerRegular),
                  onTap: () {
                    setState(() => _selectedAccountType = _accountTypes[i]);
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

  Future<void> _pickW9() async {
    if (_uploadingW9) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploadingW9 = true);
    try {
      final bytes = await File(picked.path).length();
      final sizeMB = bytes / (1024 * 1024);
      final sizeStr = sizeMB < 1
          ? '${(bytes / 1024).toStringAsFixed(0)} KB'
          : '${sizeMB.toStringAsFixed(1)} MB';
      if (!mounted) return;
      setState(() {
        _w9FileName = picked.name;
        _w9FileSize = sizeStr;
      });
    } finally {
      if (mounted) setState(() => _uploadingW9 = false);
    }
  }

  void _showInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: DesignTokens.bgAppBody,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('W-9 Form', style: DesignTokens.oneLinerSemibold),
              const SizedBox(height: DesignTokens.s12),
              Text(
                'A W-9 form is required for US businesses to certify your taxpayer identification number. Download the form from the IRS website, fill it out, and upload the completed document.',
                style: DesignTokens.mediumRegular,
              ),
              const SizedBox(height: DesignTokens.s20),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Okay, Got it',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceed() {
    final current = ref.read(vendorApplyDraftProvider);
    if (current != null) {
      ref.read(vendorApplyDraftProvider.notifier).draft = current.copyWith(
        accountHolder: _accountHolderController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountType: _selectedAccountType,
        routingNumber: _routingController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        w9FileName: _w9FileName,
        taxCertified: _taxCertified,
      );
    }
    unawaited(context.push(RouteNames.vendorApplyStep5));
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
                  : context.go(RouteNames.vendorApplyStep3),
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
          Text('Bank Account Information', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s4),
          Text('For receiving payouts', style: DesignTokens.smallRegular),
          const SizedBox(height: DesignTokens.s16),

          // Security notice
          Container(
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/vendordashboard/lock.png', width: 28, height: 28),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Text(
                    'You\'re banking information is safe and encrypted',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _accountHolderController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Account Holder Name',
            ),
          ),
          const SizedBox(height: DesignTokens.s12),

          TextField(
            controller: _bankNameController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(hintText: 'Bank Name'),
          ),
          const SizedBox(height: DesignTokens.s12),

          // Account Type dropdown
          GestureDetector(
            onTap: _showPickerSheet,
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
                      _selectedAccountType ?? 'Account Type',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        color: _selectedAccountType != null
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
          const SizedBox(height: DesignTokens.s12),

          TextField(
            controller: _routingController,
            keyboardType: TextInputType.number,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(hintText: 'Routing Number'),
          ),
          const SizedBox(height: DesignTokens.s12),

          TextField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            obscureText: true,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(hintText: 'Account Number'),
          ),
          const SizedBox(height: DesignTokens.s12),

          TextField(
            controller: _confirmAccountController,
            keyboardType: TextInputType.number,
            obscureText: true,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Confirm Account Number',
            ),
          ),

          const SizedBox(height: DesignTokens.s24),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          const SizedBox(height: DesignTokens.s20),

          Text('Tax Information', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),

          // W-9 label + info
          Row(
            children: [
              Expanded(
                child: Text(
                  'W-9 Form (US Businesses)',
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _showInfoDialog,
                child: const Icon(
                  Icons.info_outline,
                  color: DesignTokens.textMuted,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),

          // W-9 file tile or upload button
          if (_w9FileName != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
                vertical: DesignTokens.s12,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                border: Border.all(color: DesignTokens.borderDefault),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    color: DesignTokens.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _w9FileName!,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.mediumSemibold,
                        ),
                        Text(
                          _w9FileSize ?? '',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _w9FileName = null;
                      _w9FileSize = null;
                    }),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: DesignTokens.borderDefault),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: DesignTokens.textMuted,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _uploadingW9 ? null : _pickW9,
              child: Container(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBody,
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  border: Border.all(color: DesignTokens.borderDefault),
                ),
                child: _uploadingW9
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.upload_outlined,
                            color: Color(0xFFD4D4D8),
                            size: 20,
                          ),
                          const SizedBox(width: DesignTokens.s8),
                          Text(
                            'Upload Document',
                            style: DesignTokens.oneLinerSemibold.copyWith(
                              color: const Color(0xFFD4D4D8),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

          const SizedBox(height: DesignTokens.s16),

          // Tax certification checkbox
          GestureDetector(
            onTap: () => setState(() => _taxCertified = !_taxCertified),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _taxCertified
                        ? DesignTokens.primaryGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _taxCertified
                          ? DesignTokens.primaryGreen
                          : DesignTokens.borderDefault,
                      width: 1.5,
                    ),
                  ),
                  child: _taxCertified
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
                    'I certify that the tax information provided is accurate and complete',
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                ),
              ],
            ),
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
                  : context.go(RouteNames.vendorApplyStep3),
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
