import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/widgets/kyc_document_tile.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplyScreen extends ConsumerStatefulWidget {
  const VendorApplyScreen({super.key});

  @override
  ConsumerState<VendorApplyScreen> createState() => _VendorApplyScreenState();
}

class _VendorApplyScreenState extends ConsumerState<VendorApplyScreen> {
  static const int _totalSteps = 6;
  static const int _currentStep = 1;

  static const _countries = [
    'Nepal',
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'China',
    'Japan',
    'South Korea',
    'Singapore',
    'UAE',
    'Bangladesh',
    'Pakistan',
    'Sri Lanka',
    'Thailand',
    'Vietnam',
    'Indonesia',
    'Malaysia',
    'Philippines',
  ];

  static const _statesProvinces = [
    'Koshi Province',
    'Madhesh Province',
    'Bagmati Province',
    'Gandaki Province',
    'Lumbini Province',
    'Karnali Province',
    'Sudurpashchim Province',
    'Maharashtra',
    'Delhi',
    'Karnataka',
    'Tamil Nadu',
    'Telangana',
    'Gujarat',
    'Rajasthan',
    'Uttar Pradesh',
    'West Bengal',
    'Punjab',
    'Kerala',
    'Other',
  ];

  final _brandNameController = TextEditingController();
  final _legalBusinessNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _businessRegController = TextEditingController();
  final _websiteController = TextEditingController();
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();

  BusinessType? _selectedBusinessType;
  String? _selectedCountryRegion;
  String? _selectedCountry;
  String? _selectedState;

  bool _hasCheckedStatus = false;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(_checkStatus));
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    _legalBusinessNameController.dispose();
    _taxIdController.dispose();
    _businessRegController.dispose();
    _websiteController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    if (_hasCheckedStatus) return;
    _hasCheckedStatus = true;

    // Prefer session state; fall back to token storage as ground truth
    var accountId = ref.read(sessionControllerProvider).maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );
    accountId ??= await ref.read(tokenStorageProvider).accountId;

    if (!mounted) return;
    if (accountId != null && accountId.isNotEmpty) {
      setState(() => _accountId = accountId);
      await ref.read(vendorApplyNotifierProvider.notifier).checkStatus(accountId);
    }
  }

  void _submit() {
    final brandName = _brandNameController.text.trim();
    final legalBusinessName = _legalBusinessNameController.text.trim();
    final taxId = _taxIdController.text.trim();
    final businessReg = _businessRegController.text.trim();
    final streetAddress = _streetAddressController.text.trim();
    final city = _cityController.text.trim();
    final zipCode = _zipCodeController.text.trim();

    if (brandName.isEmpty) {
      return _showError('Brand name is required');
    }
    if (legalBusinessName.isEmpty) {
      return _showError('Legal business name is required');
    }
    if (_selectedBusinessType == null) {
      return _showError('Business type is required');
    }
    if (taxId.isEmpty) return _showError('Tax ID is required');
    if (businessReg.isEmpty) {
      return _showError('Business registration number is required');
    }
    if (_selectedCountryRegion == null) {
      return _showError('Country/Region is required');
    }
    if (streetAddress.isEmpty) {
      return _showError('Street address is required');
    }
    if (city.isEmpty) return _showError('City is required');
    if (_selectedCountry == null) {
      return _showError('Country is required');
    }
    if (zipCode.isEmpty) return _showError('Zip code is required');
    if (_selectedState == null) return _showError('State is required');

    final websiteText = _websiteController.text.trim();
    ref.read(vendorApplyDraftProvider.notifier).draft = VendorApplyDraft(
      accountId: _accountId ?? '',
      brandName: brandName,
      legalBusinessName: legalBusinessName,
      businessType: _selectedBusinessType!,
      taxId: taxId,
      businessRegistrationNumber: businessReg,
      website: websiteText.isEmpty ? null : websiteText,
      countryRegion: _selectedCountryRegion!,
      streetAddress: streetAddress,
      city: city,
      country: _selectedCountry!,
      zipCode: zipCode,
      state: _selectedState!,
    );

    context.push(RouteNames.vendorApplyStep2);
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

  void _showPickerSheet({
    required String title,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
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
                  child: Text(title, style: DesignTokens.oneLinerSemibold),
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: DesignTokens.borderDefault,
                    height: 1,
                  ),
                  itemBuilder: (_, i) => ListTile(
                    title: Text(items[i], style: DesignTokens.oneLinerRegular),
                    onTap: () {
                      onSelected(items[i]);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
            ],
          ),
        );
      },
    ).ignore();
  }

  void _showBusinessTypeSheet() {
    _showPickerSheet(
      title: 'Business Type',
      items: BusinessType.values.map((e) => e.label).toList(growable: false),
      onSelected: (label) {
        setState(() {
          _selectedBusinessType = BusinessType.values.firstWhere(
            (e) => e.label == label,
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorApplyNotifierProvider);

    ref.listen(vendorApplyNotifierProvider, (prev, next) {
      next.whenOrNull(
        loadSuccess: (app) {
          if (app.status == VendorApplicationStatus.approved) {
            context.pushReplacement(RouteNames.vendorApplyApproved);
          }
        },
      );
    });

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
              : context.go(RouteNames.userTypeSelection),
        ),
      ),
      body: SafeArea(
        child: state.when(
          initial: () => _buildFormBody(),
          loadInProgress: _loader,
          loadSuccess: _buildStatusOrForm,
          loadFailure: (failure) => failure.isNotFound
              ? _buildFormBody()
              : SmErrorView(
                  message: 'Could not load application status.',
                  onRetry: () {
                    _hasCheckedStatus = false;
                    _checkStatus();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildStatusOrForm(VendorApplication application) {
    switch (application.status) {
      case VendorApplicationStatus.draft:
        // Draft = wizard was started but never submitted; let them continue.
        return _buildFormBody();
      case VendorApplicationStatus.pending:
        return _ApplicationStatusCard(application: application);
      case VendorApplicationStatus.underReview:
        Future.microtask(() {
          if (context.mounted) {
            context.pushReplacement(RouteNames.vendorApplyUnderReview);
          }
        });
        return _loader();
      case VendorApplicationStatus.rejected:
        Future.microtask(() {
          if (context.mounted) {
            context.pushReplacement(
              RouteNames.vendorApplyRejected,
              extra: application.rejectionReason,
            );
          }
        });
        return _loader();
      case VendorApplicationStatus.approved:
        Future.microtask(() {
          if (context.mounted) {
            context.pushReplacement(RouteNames.vendorApplyApproved);
          }
        });
        return _loader();
    }
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  Widget _buildFormBody() {
    return Column(
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
        _buildProceedButton(),
      ],
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
          Text('Business Information', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'We collect this information to verify your identity and ensure the security of your account.',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s32),

          TextField(
            controller: _brandNameController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Brand Name',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _legalBusinessNameController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Legal Business Name',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          _buildDropdown(
            hint: 'Business Type',
            value: _selectedBusinessType?.label,
            onTap: _showBusinessTypeSheet,
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _taxIdController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(hintText: 'Tax ID / EIN'),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _businessRegController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Business Registration Number',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Website URL (optional)',
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          _buildDropdown(
            hint: 'Country/Region',
            value: _selectedCountryRegion,
            onTap: () => _showPickerSheet(
              title: 'Country/Region',
              items: _countries,
              onSelected: (v) => setState(() => _selectedCountryRegion = v),
            ),
          ),

          const SizedBox(height: DesignTokens.s32),
          Text('Business Address', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s16),

          TextField(
            controller: _streetAddressController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(hintText: 'Street Address'),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _cityController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(hintText: 'City'),
          ),
          const SizedBox(height: DesignTokens.s20),

          _buildDropdown(
            hint: 'Country',
            value: _selectedCountry,
            onTap: () => _showPickerSheet(
              title: 'Country',
              items: _countries,
              onSelected: (v) => setState(() => _selectedCountry = v),
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          TextField(
            controller: _zipCodeController,
            keyboardType: TextInputType.number,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(hintText: 'Zip Code'),
          ),
          const SizedBox(height: DesignTokens.s20),

          _buildDropdown(
            hint: 'State',
            value: _selectedState,
            onTap: () => _showPickerSheet(
              title: 'State',
              items: _statesProvinces,
              onSelected: (v) => setState(() => _selectedState = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                value ?? hint,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: value != null
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
    );
  }

  Widget _buildProceedButton() {
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
        child: ElevatedButton(
          onPressed: _submit,
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
    );
  }
}

class _ApplicationStatusCard extends ConsumerWidget {
  const _ApplicationStatusCard({required this.application});

  final VendorApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(vendorApplyNotifierProvider.notifier);

    final isPending = application.status == VendorApplicationStatus.pending;
    final statusColor = isPending
        ? DesignTokens.secondaryYellow
        : DesignTokens.colorInfo;

    final statusIcon = isPending
        ? Icons.hourglass_top
        : Icons.rate_review_outlined;

    final statusMessage = isPending
        ? 'Your application has been received and is awaiting review. We\'ll notify you once there\'s an update.'
        : 'Your application is being reviewed by our team. This usually takes 1-2 business days.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s24),
            decoration: DesignTokens.cardDecoration(
              borderColor: statusColor.withOpacity(0.4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 32),
                ),
                const SizedBox(height: DesignTokens.s16),
                Text(
                  application.status.label,
                  style: DesignTokens.titleMedium.copyWith(color: statusColor),
                ),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: DesignTokens.bodyText,
                ),
                if (application.rejectionReason != null) ...[
                  const SizedBox(height: DesignTokens.s16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.s12),
                    decoration: BoxDecoration(
                      color: DesignTokens.colorError.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                    ),
                    child: Text(
                      application.rejectionReason!,
                      style: DesignTokens.mediumRegular.copyWith(
                        color: DesignTokens.colorError,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (application.status == VendorApplicationStatus.pending) ...[
            const SizedBox(height: DesignTokens.s24),
            Text('Your Documents', style: DesignTokens.sectionInnerTitle),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Upload or update your KYC documents.',
              style: DesignTokens.smallRegular,
            ),
            const SizedBox(height: DesignTokens.s12),
            const _KycUploadTile(type: KYCDocumentType.pan),
            const SizedBox(height: DesignTokens.s8),
            const _KycUploadTile(type: KYCDocumentType.citizenship),
            const SizedBox(height: DesignTokens.s8),
            const _KycUploadTile(type: KYCDocumentType.businessReg),
            const SizedBox(height: DesignTokens.s8),
            const _KycUploadTile(type: KYCDocumentType.taxDoc),
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  var id = ref.read(sessionControllerProvider).maybeWhen(
                    authenticated: (v) => v,
                    orElse: () => null,
                  );
                  id ??= await ref.read(tokenStorageProvider).accountId;
                  if (id != null && id.isNotEmpty) {
                    unawaited(notifier.checkStatus(id, force: true));
                  }
                },
                style: DesignTokens.primaryButtonStyle(),
                child: Text(
                  'Refresh Status',
                  style: DesignTokens.oneLinerSemibold.copyWith(
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ],

          if (application.status == VendorApplicationStatus.approved) ...[
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pushReplacement(RouteNames.vendorDash),
                style: DesignTokens.primaryButtonStyle(),
                child: Text(
                  'Go to Vendor Dashboard',
                  style: DesignTokens.oneLinerSemibold.copyWith(
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ],

          if (application.status == VendorApplicationStatus.rejected) ...[
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  var id = ref.read(sessionControllerProvider).maybeWhen(
                    authenticated: (v) => v,
                    orElse: () => null,
                  );
                  id ??= await ref.read(tokenStorageProvider).accountId;
                  if (id != null && id.isNotEmpty) {
                    unawaited(notifier.checkStatus(id, force: true));
                  }
                },
                style: DesignTokens.primaryButtonStyle(),
                child: Text(
                  'Reapply',
                  style: DesignTokens.oneLinerSemibold.copyWith(
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: DesignTokens.s16),
        ],
      ),
    );
  }
}

class _KycUploadTile extends ConsumerStatefulWidget {
  const _KycUploadTile({required this.type});

  final KYCDocumentType type;

  @override
  ConsumerState<_KycUploadTile> createState() => _KycUploadTileState();
}

class _KycUploadTileState extends ConsumerState<_KycUploadTile> {
  KYCDocument? _doc;
  bool _uploading = false;

  Future<void> _pick() async {
    if (_uploading) return;

    final picked = 
    await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    var accountId = ref.read(sessionControllerProvider).maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );
    accountId ??= await ref.read(tokenStorageProvider).accountId;
    if (accountId == null || accountId.isEmpty) return;
    setState(() => _uploading = true);
    final result = await ref
        .read(vendorRepositoryProvider)
        .uploadKYCDocument(picked.path, widget.type, accountId: accountId);
    if (!mounted) return;
    setState(() => _uploading = false);
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed. Please try again.'),
          backgroundColor: DesignTokens.colorError,
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (doc) => setState(() => _doc = doc),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KycDocumentTile(
      document: _doc,
      type: widget.type,
      isUploading: _uploading,
      onUpload: _pick,
      onRetry: _pick,
    );
  }
}
