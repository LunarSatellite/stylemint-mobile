import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/presentation/notifiers/customer_kyc_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/presentation/widgets/kyc_document_slot.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/notifiers/shipping_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The KYC Tier 2 form: which document, its photos and a selfie, the details
/// as they appear on the document, and an address.
///
/// One scrolling form rather than a wizard: the photos are the slow part, and
/// a buyer who can see every field at once knows what they are in for before
/// they start taking pictures.
class CustomerKycSubmitScreen extends ConsumerStatefulWidget {
  const CustomerKycSubmitScreen({super.key});

  @override
  ConsumerState<CustomerKycSubmitScreen> createState() =>
      _CustomerKycSubmitScreenState();
}

class _CustomerKycSubmitScreenState
    extends ConsumerState<CustomerKycSubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _documentNumber = TextEditingController();

  KycDocumentType? _type;
  final Map<KycDocumentKind, File> _captures = {};
  DateTime? _dateOfBirth;
  String? _addressId;
  bool _triedSubmit = false;

  @override
  void dispose() {
    _fullName.dispose();
    _documentNumber.dispose();
    super.dispose();
  }

  KycDocumentType _documentType(CustomerKycState state) =>
      _type ?? state.kyc?.documentType ?? KycDocumentType.citizenship;

  /// The camera for the selfie, the gallery allowed for the document.
  ///
  /// A selfie taken now is the point of matching it against the document;
  /// one picked from the gallery is worth nothing. A document page already
  /// exists, and people often have a good scan of it, so forcing the camera
  /// there only produces blurry photos in bad light.
  ///
  /// `imageQuality` re-encodes to JPEG and `maxWidth` keeps a page well under
  /// the 10 MB limit — and `uploadFilename` relies on that re-encode.
  Future<void> _capture(KycDocumentKind kind, ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
      preferredCameraDevice: kind.isSelfie
          ? CameraDevice.front
          : CameraDevice.rear,
    );
    if (picked == null || !mounted) return;
    ref.read(customerKycNotifierProvider.notifier).clearSubmitError();
    setState(() => _captures[kind] = File(picked.path));
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null && mounted) setState(() => _dateOfBirth = picked);
  }

  Future<void> _addAddress() async {
    await context.push<bool>(RouteNames.shippingAddEdit);
    if (!mounted) return;
    await ref.read(addressNotifierProvider.notifier).load();
  }

  Future<void> _submit(KycDocumentType type) async {
    setState(() => _triedSubmit = true);
    final formOk = _formKey.currentState?.validate() ?? false;
    final dob = _dateOfBirth;
    final addressId = _addressId;
    if (!formOk || dob == null || addressId == null) {
      SmSnackbar.error(
        context,
        dob == null
            ? 'Add your date of birth.'
            : addressId == null
            ? 'Pick the address you live at.'
            : 'Check the highlighted fields.',
      );
      return;
    }

    final notifier = ref.read(customerKycNotifierProvider.notifier);
    final ok = await notifier.submit(
      details: KycDetails(
        fullName: _fullName.text,
        dateOfBirth: dob,
        documentType: type,
        documentNumber: _documentNumber.text,
        addressId: addressId,
      ),
      // Only the photos this document type needs: a passport has no back,
      // and an old capture for another type must not travel with it.
      captures: {
        for (final kind in type.requiredKinds)
          if (_captures[kind] case final File file) kind: file,
      },
    );
    if (!mounted) return;
    if (ok) {
      ref.invalidate(emiEligibilityProvider);
      SmSnackbar.success(context, 'Sent for review.');
      context.pop();
      return;
    }
    final message = ref.read(customerKycNotifierProvider).submitError;
    if (message != null) SmSnackbar.error(context, message, seconds: 5);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerKycNotifierProvider);
    final type = _documentType(state);
    final busy = state.isBusy;
    final uploaded = state.uploadedKinds;

    String? documentFor(KycDocumentKind kind) =>
        state.kyc?.documentOf(kind)?.thumbnailUrl;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Verify your identity'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.s20),
          child: Form(
            key: _formKey,
            autovalidateMode: _triedSubmit
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Which document are you using?', style: DesignTokens.h3),
                const SizedBox(height: DesignTokens.s8),
                Wrap(
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s8,
                  children: [
                    for (final option in KycDocumentType.values)
                      ChoiceChip(
                        label: Text(option.label),
                        selected: option == type,
                        selectedColor: DesignTokens.chipsSelectedFill,
                        onSelected: busy
                            ? null
                            : (_) => setState(() => _type = option),
                      ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s20),
                Text('Photos', style: DesignTokens.h3),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Lay the document flat in good light, with all four '
                  'corners in the photo.',
                  style: DesignTokens.smallRegular,
                ),
                const SizedBox(height: DesignTokens.s12),
                for (final kind in type.requiredKinds) ...[
                  KycDocumentSlot(
                    label: kind.label,
                    helper: kind.isSelfie
                        ? 'Taken now — it is matched against your document.'
                        : null,
                    file: _captures[kind],
                    uploaded: uploaded.contains(kind),
                    uploadedThumbnailUrl: documentFor(kind),
                    disabled: busy,
                    onCamera: () => _capture(kind, ImageSource.camera),
                    onPick: kind.isSelfie
                        ? null
                        : () => _capture(kind, ImageSource.gallery),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                ],
                const SizedBox(height: DesignTokens.s12),
                Text('Your details', style: DesignTokens.h3),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Exactly as they appear on your ${type.label.toLowerCase()}.',
                  style: DesignTokens.smallRegular,
                ),
                const SizedBox(height: DesignTokens.s12),
                TextFormField(
                  controller: _fullName,
                  enabled: !busy,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Enter your full name.'
                      : null,
                ),
                const SizedBox(height: DesignTokens.s12),
                _DateOfBirthField(
                  value: _dateOfBirth,
                  enabled: !busy,
                  showErrors: _triedSubmit,
                  onTap: _pickDateOfBirth,
                ),
                const SizedBox(height: DesignTokens.s12),
                TextFormField(
                  controller: _documentNumber,
                  enabled: !busy,
                  maxLength: 40,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: '${type.label} number',
                    counterText: '',
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Enter the number on your document.'
                      : null,
                ),
                const SizedBox(height: DesignTokens.s20),
                Text('Where you live', style: DesignTokens.h3),
                const SizedBox(height: DesignTokens.s8),
                _AddressPicker(
                  selectedId: _addressId,
                  enabled: !busy,
                  showErrors: _triedSubmit,
                  onSelected: (id) => setState(() => _addressId = id),
                  onAdd: _addAddress,
                ),
                if (state.submitError case final String error) ...[
                  const SizedBox(height: DesignTokens.s16),
                  _ErrorBanner(message: error),
                ],
                const SizedBox(height: DesignTokens.s24),
                SizedBox(
                  width: double.infinity,
                  child: SmPrimaryButton(
                    label: _busyLabel(state),
                    disabled: busy,
                    onPressed: () => _submit(type),
                  ),
                ),
                const SizedBox(height: DesignTokens.s12),
                Text(
                  'A reviewer checks your document against your selfie by '
                  'hand, so it is not instant. We will notify you when it is '
                  'decided.',
                  style: DesignTokens.tiny,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _busyLabel(CustomerKycState state) => switch (state.phase) {
    KycSubmitPhase.startingSession => 'Starting…',
    KycSubmitPhase.uploading =>
      'Uploading photo ${state.uploadedCount + 1} of ${state.uploadTotal}…',
    KycSubmitPhase.submitting => 'Submitting…',
    KycSubmitPhase.idle || KycSubmitPhase.submitted => 'Submit for review',
  };
}

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({
    required this.value,
    required this.enabled,
    required this.showErrors,
    required this.onTap,
  });

  final DateTime? value;
  final bool enabled;
  final bool showErrors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = value;
    final error = date == null
        ? (showErrors ? 'Add your date of birth.' : null)
        : !isAtLeast18(date, DateTime.now())
        ? 'You must be 18 or older to use EMI.'
        : null;
    return InkWell(
      onTap: enabled ? onTap : null,
      child: InputDecorator(
        isEmpty: date == null,
        decoration: InputDecoration(
          labelText: 'Date of birth',
          errorText: error,
          enabled: enabled,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          date == null ? '' : DateFormat.yMMMd().format(date),
          style: DesignTokens.bodyText,
        ),
      ),
    );
  }
}

/// The buyer's saved addresses as a pick list, with a way to add one.
/// Reuses the shipping-address feature; KYC never keeps its own copy.
class _AddressPicker extends ConsumerWidget {
  const _AddressPicker({
    required this.selectedId,
    required this.enabled,
    required this.showErrors,
    required this.onSelected,
    required this.onAdd,
  });

  final String? selectedId;
  final bool enabled;
  final bool showErrors;
  final ValueChanged<String> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressNotifierProvider);
    final addButton = Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: enabled ? onAdd : null,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add an address'),
      ),
    );

    return state.when(
      initial: () => const LinearProgressIndicator(),
      loadInProgress: () => const LinearProgressIndicator(),
      loadFailure: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your saved addresses could not be loaded.',
            style: DesignTokens.smallRegular,
          ),
          TextButton(
            onPressed: () => ref.read(addressNotifierProvider.notifier).load(),
            child: const Text('Try again'),
          ),
        ],
      ),
      loadSuccess: (addresses) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (addresses.isEmpty)
            Text(
              'You have no saved address yet. Add the one you live at.',
              style: DesignTokens.smallRegular,
            ),
          for (final address in addresses)
            _AddressTile(
              address: address,
              selected: address.id == selectedId,
              enabled: enabled,
              onTap: () => onSelected(address.id),
            ),
          if (showErrors && selectedId == null)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s4),
              child: Text(
                'Pick the address you live at.',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.colorError,
                ),
              ),
            ),
          addButton,
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ShippingAddress address;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s8),
    child: Material(
      color: DesignTokens.bgAppBody,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        side: BorderSide(
          color: selected
              ? DesignTokens.primaryGreen
              : DesignTokens.borderDefault,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? DesignTokens.primaryGreen
                    : DesignTokens.iconLight,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label.trim().isEmpty
                          ? address.receiverName
                          : address.label,
                      style: DesignTokens.mediumSemibold,
                    ),
                    Text(
                      address.summaryLine,
                      style: DesignTokens.tiny,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.colorError.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      border: Border.all(color: DesignTokens.colorError),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded, color: DesignTokens.colorError),
        const SizedBox(width: DesignTokens.s8),
        Expanded(child: Text(message, style: DesignTokens.smallRegular)),
      ],
    ),
  );
}
