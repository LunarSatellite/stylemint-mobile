import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/widgets/kyc_document_tile.dart';
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
  static const _categories = [
    'Electronics',
    'Fashion',
    'Beauty',
    'Home & Living',
    'Sports',
    'Food & Grocery',
    'Health',
    'Automotive',
    'Books',
    'Toys',
    'Services',
    'Digital Goods',
  ];

  final _businessNameController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _ownerFullNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();

  BusinessType _selectedBusinessType = BusinessType.individual;
  final _selectedCategories = <String>{};
  bool _isSubmitting = false;
  bool _hasCheckedStatus = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkStatus);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _taxIdController.dispose();
    _ownerFullNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _checkStatus() {
    if (_hasCheckedStatus) return;
    _hasCheckedStatus = true;
    ref.read(vendorApplyNotifierProvider.notifier).checkStatus();
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

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final businessName = _businessNameController.text.trim();
    final taxId = _taxIdController.text.trim();
    final ownerFullName = _ownerFullNameController.text.trim();
    final ownerPhone = _ownerPhoneController.text.trim();
    final ownerEmail = _ownerEmailController.text.trim();
    final description = _descriptionController.text.trim();
    final website = _websiteController.text.trim();

    if (businessName.isEmpty) {
      _showError('Please enter your business name.');
      return;
    }
    if (taxId.isEmpty) {
      _showError('Please enter your tax ID / PAN.');
      return;
    }
    if (ownerFullName.isEmpty) {
      _showError('Please enter the owner\'s full name.');
      return;
    }
    if (ownerPhone.isEmpty) {
      _showError('Please enter the owner\'s phone number.');
      return;
    }
    if (ownerEmail.isEmpty) {
      _showError('Please enter the owner\'s email.');
      return;
    }
    if (description.isEmpty) {
      _showError('Please enter a business description.');
      return;
    }

    final form = VendorApplicationForm(
      businessName: businessName,
      businessType: _selectedBusinessType,
      taxId: taxId,
      ownerFullName: ownerFullName,
      ownerPhone: ownerPhone,
      ownerEmail: ownerEmail,
      description: description,
      website: website.isNotEmpty ? website : null,
      categories: _selectedCategories.toList(growable: false),
    );

    setState(() => _isSubmitting = true);
    await ref.read(vendorApplyNotifierProvider.notifier).submit(form);
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _uploadKycDoc(KYCDocumentType type) async {
    // Placeholder — real implementation would use image_picker / file_picker
    _showError('File picker integration pending.');
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorApplyNotifierProvider);

    ref.listen(vendorApplyNotifierProvider, (prev, next) {
      next.whenOrNull(
        loadSuccess: (app) {
          if (app.status == VendorApplicationStatus.approved) {
            context.go(RouteNames.vendorDash);
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
      ),
      body: SafeArea(
        child: state.when(
          initial: () => _buildForm(),
          loadInProgress: _loader,
          loadSuccess: _buildStatusOrForm,
          loadFailure: (failure) => SmErrorView(
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
      case VendorApplicationStatus.pending:
      case VendorApplicationStatus.underReview:
      case VendorApplicationStatus.kycRequired:
        return _ApplicationStatusCard(application: application);
      case VendorApplicationStatus.rejected:
        return _buildForm();
      case VendorApplicationStatus.approved:
        Future.microtask(() {
          if (context.mounted) context.go(RouteNames.vendorDash);
        });
        return _loader();
    }
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set up your store', style: DesignTokens.titleLarge),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Fill in your business details to start selling on Style Mint.',
            style: DesignTokens.bodyText,
          ),
          const SizedBox(height: DesignTokens.s24),

          // --- Business Name ---
          TextField(
            controller: _businessNameController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Business Name',
              hintText: 'Enter your registered business name',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // --- Business Type ---
          Text('Business Type', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s8),
          ...BusinessType.values.map((type) {
            final isSelected = _selectedBusinessType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedBusinessType = type),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: DesignTokens.s8),
                padding: const EdgeInsets.all(DesignTokens.s12),
                decoration: DesignTokens.cardDecoration(
                  borderColor: isSelected ? DesignTokens.primaryGreen : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isSelected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Text(type.label, style: DesignTokens.oneLinerRegular),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: DesignTokens.s16),

          // --- Tax ID ---
          TextField(
            controller: _taxIdController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Tax ID / PAN',
              hintText: 'Enter your tax identification number',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // --- Owner Full Name ---
          TextField(
            controller: _ownerFullNameController,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Owner Full Name',
              hintText: 'Enter the business owner\'s full name',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // --- Owner Phone ---
          TextField(
            controller: _ownerPhoneController,
            keyboardType: TextInputType.phone,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Owner Phone',
              hintText: '+977 98XXXXXXXX',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // --- Owner Email ---
          TextField(
            controller: _ownerEmailController,
            keyboardType: TextInputType.emailAddress,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Owner Email',
              hintText: 'owner@business.com',
            ),
          ),
          const SizedBox(height: DesignTokens.s24),

          // --- Description ---
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 500,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Business Description',
              hintText: 'Tell customers about your business...',
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // --- Website ---
          TextField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            style: DesignTokens.oneLinerRegular.copyWith(
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              labelText: 'Website (optional)',
              hintText: 'https://...',
            ),
          ),
          const SizedBox(height: DesignTokens.s24),

          // --- Categories ---
          Text('Product Categories', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Select categories for the products you sell.',
            style: DesignTokens.smallRegular,
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
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s8,
                  ),
                  decoration: isSelected
                      ? DesignTokens.chipDecorationSelected()
                      : DesignTokens.chipDecorationDefault(),
                  child: Text(
                    category,
                    style: (isSelected
                            ? DesignTokens.mediumSemibold
                            : DesignTokens.mediumRegular)
                        .copyWith(
                      color: isSelected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.chipsDefaultText,
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: DesignTokens.s24),

          // --- KYC Documents ---
          Text('KYC Documents', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Upload the required documents to verify your business.',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s12),

          KycDocumentTile(
            document: null,
            onUpload: () => _uploadKycDoc(KYCDocumentType.pan),
          ),
          const SizedBox(height: DesignTokens.s8),
          KycDocumentTile(
            document: null,
            onUpload: () => _uploadKycDoc(KYCDocumentType.citizenship),
          ),
          const SizedBox(height: DesignTokens.s8),
          KycDocumentTile(
            document: null,
            onUpload: () => _uploadKycDoc(KYCDocumentType.businessReg),
          ),
          const SizedBox(height: DesignTokens.s8),
          KycDocumentTile(
            document: null,
            onUpload: () => _uploadKycDoc(KYCDocumentType.taxDoc),
          ),

          const SizedBox(height: DesignTokens.s28),

          // --- Submit ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: DesignTokens.primaryButtonStyle(),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
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
          ),
          const SizedBox(height: DesignTokens.s16),
        ],
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
    final isKyc = application.status == VendorApplicationStatus.kycRequired;
    final statusColor = isPending
        ? DesignTokens.secondaryYellow
        : isKyc
            ? DesignTokens.colorInfo
            : DesignTokens.colorInfo;

    final statusIcon = isPending
        ? Icons.hourglass_top
        : isKyc
            ? Icons.folder_outlined
            : Icons.rate_review_outlined;

    final statusMessage = isPending
        ? 'Your application has been received and is awaiting review. We\'ll notify you once there\'s an update.'
        : isKyc
            ? 'Additional KYC documents are required. Please upload the missing documents below.'
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
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 32,
                  ),
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

          // --- KYC Section (shown when kycRequired or pending/underReview) ---
          if (application.status == VendorApplicationStatus.kycRequired ||
              application.status == VendorApplicationStatus.pending) ...[
            const SizedBox(height: DesignTokens.s24),
            Text('Your Documents', style: DesignTokens.sectionInnerTitle),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Upload or update your KYC documents.',
              style: DesignTokens.smallRegular,
            ),
            const SizedBox(height: DesignTokens.s12),
            KycDocumentTile(
              document: null,
              onUpload: () {}, // TODO: integrate file picker
            ),
            const SizedBox(height: DesignTokens.s8),
            KycDocumentTile(
              document: null,
              onUpload: () {},
            ),
            const SizedBox(height: DesignTokens.s8),
            KycDocumentTile(
              document: null,
              onUpload: () {},
            ),
            const SizedBox(height: DesignTokens.s8),
            KycDocumentTile(
              document: null,
              onUpload: () {},
            ),
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  notifier.checkStatus();
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

          // --- "Go to Dashboard" button when approved ---
          if (application.status == VendorApplicationStatus.approved) ...[
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(RouteNames.vendorDash),
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

          // --- Reapply button when rejected ---
          if (application.status == VendorApplicationStatus.rejected) ...[
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(vendorApplyNotifierProvider.notifier).checkStatus();
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
