import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplyStep3Screen extends StatefulWidget {
  const VendorApplyStep3Screen({super.key});

  @override
  State<VendorApplyStep3Screen> createState() => _VendorApplyStep3ScreenState();
}

enum _DocStatus { success, failed }

class _DocFile {
  _DocFile({required this.name, required this.size, this.status = _DocStatus.success});
  final String name;
  final String size;
  final _DocStatus status;

  _DocFile copyWith({_DocStatus? status}) =>
      _DocFile(name: name, size: size, status: status ?? this.status);
}

class _VendorApplyStep3ScreenState extends State<VendorApplyStep3Screen> {
  static const int _totalSteps = 6;
  static const int _currentStep = 3;

  final _licenseFiles = <_DocFile>[];
  final _taxFiles = <_DocFile>[];
  final _addressFiles = <_DocFile>[];
  final _incorporationFiles = <_DocFile>[];

  bool _pickingLicense = false;
  bool _pickingTax = false;
  bool _pickingAddress = false;
  bool _pickingIncorporation = false;

  Future<void> _pickFile({
    required List<_DocFile> files,
    required void Function(bool) setLoading,
  }) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    setLoading(true);
    setState(() {});

    try {
      final bytes = await File(picked.path).length();
      final sizeMB = bytes / (1024 * 1024);
      final sizeStr = sizeMB < 1
          ? '${(bytes / 1024).toStringAsFixed(0)} KB'
          : '${sizeMB.toStringAsFixed(1)} MB';

      if (!mounted) return;
      setState(() => files.add(_DocFile(name: picked.name, size: sizeStr)));
    } catch (_) {
      if (!mounted) return;
      setState(() => files.add(_DocFile(
            name: picked.name,
            size: '—',
            status: _DocStatus.failed,
          )));
    } finally {
      if (mounted) {
        setLoading(false);
        setState(() {});
      }
    }
  }

  void _retryFile(List<_DocFile> files, int index) {
    setState(() {
      files[index] = files[index].copyWith(status: _DocStatus.success);
    });
  }

  void _removeFile(List<_DocFile> files, int index) {
    setState(() => files.removeAt(index));
  }

  void _showInfoDialog({required String title, required String body}) {
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
              Text(title, style: DesignTokens.oneLinerSemibold),
              const SizedBox(height: DesignTokens.s12),
              Text(body, style: DesignTokens.mediumRegular),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DesignTokens.colorError,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _proceed() {
    context.push(RouteNames.vendorApplyStep4);
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
          onPressed: () => Navigator.of(context).pop(),
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
      padding: const EdgeInsets.all(DesignTokens.s20),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Documents', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Please upload the following documents for verification',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s16),

          // Tips box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: const Color(0xFF052F4A),
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.infoTextLight,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                ...[
                  'Accepted Formats: PDF, JPG & PNG',
                  'Max File Size: 10 mb per file',
                  'Document must be clear and readable',
                  'All text must be in English or translated',
                ].map(
                  (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.s4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.infoTextLight,
                            )),
                        Expanded(
                          child: Text(tip,
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.infoTextLight,
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: DesignTokens.s24),

          _buildDocumentSlot(
            label: 'Business License Document',
            files: _licenseFiles,
            isLoading: _pickingLicense,
            onUpload: () => _pickFile(
              files: _licenseFiles,
              setLoading: (v) => _pickingLicense = v,
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          _buildDocumentSlot(
            label: 'Tax Certificate (EIN Confirmation)',
            files: _taxFiles,
            isLoading: _pickingTax,
            onUpload: () => _pickFile(
              files: _taxFiles,
              setLoading: (v) => _pickingTax = v,
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          _buildDocumentSlot(
            label: 'Proof of Business Address',
            showInfo: true,
            onInfo: () => _showInfoDialog(
              title: 'Proof of Business Address',
              body:
                  'You need to upload proof that the business address you entered is valid. This can be a utility bill, lease agreement, or bank statement dated within the last 3 months, clearly showing the address.',
            ),
            files: _addressFiles,
            isLoading: _pickingAddress,
            onUpload: () => _pickFile(
              files: _addressFiles,
              setLoading: (v) => _pickingAddress = v,
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          _buildDocumentSlot(
            label: 'Certificate of Incorporation (Optional)',
            showInfo: true,
            onInfo: () => _showInfoDialog(
              title: 'Certificate of Incorporation',
              body:
                  'Upload your official certificate of incorporation issued by the relevant government authority. This document confirms your business is legally registered.',
            ),
            files: _incorporationFiles,
            isLoading: _pickingIncorporation,
            onUpload: () => _pickFile(
              files: _incorporationFiles,
              setLoading: (v) => _pickingIncorporation = v,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSlot({
    required String label,
    required List<_DocFile> files,
    required VoidCallback onUpload,
    bool isLoading = false,
    bool showInfo = false,
    VoidCallback? onInfo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ),
            if (showInfo)
              GestureDetector(
                onTap: onInfo,
                child: const Icon(
                  Icons.info_outline,
                  color: DesignTokens.textMuted,
                  size: 18,
                ),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),

        // Uploaded file tiles
        ...files.asMap().entries.map((entry) {
          final index = entry.key;
          final doc = entry.value;
          final isFailed = doc.status == _DocStatus.failed;

          return Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s8),
            child: Container(
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
                  Icon(
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
                          doc.name,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.mediumSemibold,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFailed ? 'Upload Failed!' : doc.size,
                          style: DesignTokens.smallRegular.copyWith(
                            color: isFailed
                                ? DesignTokens.colorError
                                : DesignTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isFailed)
                    GestureDetector(
                      onTap: () => _retryFile(files, index),
                      child: const Padding(
                        padding: EdgeInsets.only(right: DesignTokens.s8),
                        child: Icon(
                          Icons.refresh,
                          color: DesignTokens.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => _removeFile(files, index),
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
            ),
          );
        }),

        // Show upload button only when no successful file uploaded yet
        if (files.every((f) => f.status == _DocStatus.failed) || files.isEmpty)
          GestureDetector(
            onTap: isLoading ? null : onUpload,
            child: Container(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                border: Border.all(color: DesignTokens.borderDefault),
              ),
              child: isLoading
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
      ],
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
              onPressed: () => Navigator.of(context).pop(),
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
