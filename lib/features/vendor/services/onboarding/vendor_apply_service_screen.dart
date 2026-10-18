import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/onboarding/service_licence_uploader.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The vendor application's service step (service-banks contract v1, §1),
/// right after the business details: what kind of business this is —
/// products (as before), a hotel, a travel agency or a bank — and, for a
/// service business, its operating licence: number, issuer, expiry and a
/// photo of the certificate. Admin reviews it with the PAN and business
/// registration already given.
class VendorApplyServiceScreen extends ConsumerStatefulWidget {
  const VendorApplyServiceScreen({super.key});

  static Key categoryKey(ServiceCategory c) =>
      Key('apply-service-category-${c.name}');
  static const Key licenceNumberKey = Key('apply-service-licence-number');
  static const Key licenceIssuerKey = Key('apply-service-licence-issuer');
  static const Key expiryKey = Key('apply-service-licence-expiry');
  static const Key uploadKey = Key('apply-service-licence-upload');
  static const Key continueKey = Key('apply-service-continue');
  static const Key businessTypeWarningKey = Key(
    'apply-service-business-type-warning',
  );

  /// Banks apply as a limited liability company or a corporation (the
  /// server refuses anything else with `field: "BusinessType"`).
  static bool businessTypeAllowed(
    ServiceCategory category,
    BusinessType type,
  ) =>
      category != ServiceCategory.bank ||
      type == BusinessType.limitedLiabilityCompany ||
      type == BusinessType.corporation;

  @override
  ConsumerState<VendorApplyServiceScreen> createState() =>
      _VendorApplyServiceScreenState();
}

class _VendorApplyServiceScreenState
    extends ConsumerState<VendorApplyServiceScreen> {
  ServiceCategory _category = ServiceCategory.none;
  final _number = TextEditingController();
  final _issuer = TextEditingController();
  DateTime? _expiry;
  UploadedLicence? _licence;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(vendorApplyDraftProvider);
    if (draft != null) {
      _category = ServiceCategory.fromWire(draft.serviceCategory);
      _number.text = draft.licenceNumber ?? '';
      _issuer.text = draft.licenceIssuer ?? '';
      _expiry = draft.licenceExpiresOn;
      final ref0 = draft.licenceDocumentRef;
      if (ref0 != null) {
        _licence = (
          reference: ref0,
          fileName: draft.licenceDocumentName ?? 'Licence certificate',
        );
      }
    }
  }

  @override
  void dispose() {
    _number.dispose();
    _issuer.dispose();
    super.dispose();
  }

  void _toast(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _upload() async {
    if (_uploading) return;
    final uploader = ref.read(serviceLicenceUploaderProvider);
    final path = await uploader.pick();
    if (path == null || !mounted) return;
    setState(() => _uploading = true);
    final result = await uploader.upload(path);
    if (!mounted) return;
    setState(() => _uploading = false);
    result.fold(
      (f) => _toast(
        serviceFailureMessage(
          f,
          fallback: 'The upload failed. Please try again.',
        ),
      ),
      (licence) => setState(() => _licence = licence),
    );
  }

  Future<void> _pickExpiry() async {
    final today = serviceToday();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? today.add(const Duration(days: 365)),
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 15)),
    );
    if (picked != null) setState(() => _expiry = dateOnly(picked));
  }

  String? get _blocker {
    final draft = ref.read(vendorApplyDraftProvider);
    if (_category == ServiceCategory.bank && _number.text.trim().isEmpty) {
      return 'Enter your NRB licence number.';
    }
    if (_number.text.trim().length > 80) {
      return 'The licence number is too long.';
    }
    if (_issuer.text.trim().length > 120) {
      return 'The issuer name is too long.';
    }
    if (draft != null &&
        !VendorApplyServiceScreen.businessTypeAllowed(
          _category,
          draft.businessType,
        )) {
      return 'Banks apply as a Limited Liability Company (Pvt Ltd) or a '
          'Corporation.';
    }
    return null;
  }

  void _continue() {
    final draft = ref.read(vendorApplyDraftProvider);
    if (draft == null) {
      // Opened without the first step (a stale back stack): start over.
      context.go(RouteNames.vendorApply);
      return;
    }
    final blocker = _blocker;
    if (blocker != null) {
      _toast(blocker);
      return;
    }
    final number = _number.text.trim();
    final issuer = _issuer.text.trim();
    ref.read(vendorApplyDraftProvider.notifier).draft = draft.withService(
      serviceCategory: _category.wire,
      licenceNumber: number.isEmpty ? null : number,
      licenceIssuer: issuer.isEmpty ? null : issuer,
      licenceExpiresOn: _expiry,
      licenceDocumentRef: _licence?.reference,
      licenceDocumentName: _licence?.fileName,
    );
    context.push(RouteNames.vendorApplyStep2);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(vendorApplyDraftProvider);
    final service = _category.isService;
    final bank = _category == ServiceCategory.bank;
    final typeOk =
        draft == null ||
        VendorApplyServiceScreen.businessTypeAllowed(
          _category,
          draft.businessType,
        );
    final muted = DesignTokens.smallRegular.copyWith(
      color: DesignTokens.textMuted,
    );
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Your business'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            const Text(
              'What kind of business is it?',
              style: DesignTokens.sectionInnerTitle,
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Hotels, travel agencies and banks get bookings or enquiries '
              'instead of orders. This cannot be changed after approval.',
              style: muted,
            ),
            const SizedBox(height: DesignTokens.s12),
            for (final c in ServiceCategory.values)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: _CategoryOption(
                  key: VendorApplyServiceScreen.categoryKey(c),
                  category: c,
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                ),
              ),
            if (service) ...[
              const ServiceSectionTitle('Operating licence'),
              Text(
                bank
                    ? 'Your Nepal Rastra Bank licence. StyleMint checks it '
                          'before your bank page goes live.'
                    : 'Your tourism licence, if you have one. It helps '
                          'StyleMint approve you sooner.',
                style: muted,
              ),
              const SizedBox(height: DesignTokens.s8),
              TextField(
                key: VendorApplyServiceScreen.licenceNumberKey,
                controller: _number,
                maxLength: 80,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: bank
                      ? 'NRB licence number'
                      : 'Tourism licence number (optional)',
                ),
              ),
              TextField(
                key: VendorApplyServiceScreen.licenceIssuerKey,
                controller: _issuer,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: 'Issued by (optional)',
                  hintText: bank
                      ? 'Nepal Rastra Bank'
                      : 'Department of Tourism',
                ),
              ),
              const SizedBox(height: DesignTokens.s4),
              OutlinedButton.icon(
                key: VendorApplyServiceScreen.expiryKey,
                onPressed: _pickExpiry,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  _expiry == null
                      ? 'Expiry date (optional)'
                      : 'Expires ${serviceDateText(_expiry!)}',
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              ServiceActionButton(
                key: VendorApplyServiceScreen.uploadKey,
                label: _licence == null
                    ? 'Upload licence certificate'
                    : 'Replace certificate (${_licence!.fileName})',
                icon: _licence == null
                    ? Icons.upload_file_rounded
                    : Icons.check_circle_rounded,
                outlined: true,
                busy: _uploading,
                onPressed: _upload,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                'We review it with the PAN and business registration number '
                'you gave on the previous step.',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              if (!typeOk) ...[
                const SizedBox(height: DesignTokens.s12),
                ServiceCard(
                  key: VendorApplyServiceScreen.businessTypeWarningKey,
                  borderColor: DesignTokens.colorWarning,
                  child: Text(
                    'Banks apply as a Limited Liability Company (Pvt Ltd) or '
                    'a Corporation. Go back and change the business type to '
                    'continue.',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.colorWarning,
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: DesignTokens.s24),
            ServiceActionButton(
              key: VendorApplyServiceScreen.continueKey,
              label: 'Continue',
              onPressed: _blocker == null ? _continue : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.category,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final ServiceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle) = switch (category) {
      ServiceCategory.none => (
        Icons.shopping_bag_outlined,
        'Products',
        'Clothes, shoes, beauty and other goods, delivered to buyers.',
      ),
      ServiceCategory.hotel => (
        Icons.hotel_outlined,
        'Hotel or stay',
        'Rooms that guests book by the night.',
      ),
      ServiceCategory.travelAgency => (
        Icons.luggage_outlined,
        'Travel agency',
        'Tours, treks and packages with set departures.',
      ),
      ServiceCategory.bank => (
        Icons.account_balance_outlined,
        'Bank',
        'Accounts, loans and cards: buyers send enquiries and book branch '
            'visits.',
      ),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: ServiceCard(
        borderColor: selected ? DesignTokens.primaryGreen : null,
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? DesignTokens.primaryGreen
                  : DesignTokens.iconLight,
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DesignTokens.mediumSemibold),
                  Text(
                    subtitle,
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? DesignTokens.primaryGreen
                  : DesignTokens.iconLight,
            ),
          ],
        ),
      ),
    );
  }
}
