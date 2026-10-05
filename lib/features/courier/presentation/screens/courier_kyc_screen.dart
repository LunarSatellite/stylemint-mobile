import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_kyc_documents.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_action_feedback.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/identity_document.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Identity checks for a delivery partner.
///
/// Takes the last four digits of a government ID **and the documents
/// themselves** — a photo of the ID (both sides where it has two) and a
/// selfie.
///
/// This screen used to collect only the four digits and a free-text
/// "verification reference", on the reasoning that the courier KYC endpoint
/// accepts nothing else and the app should not carry images of people's ID
/// papers. The first half was true and the second was wrong: Identity has had
/// an account-scoped document pipeline all along — session, upload, register,
/// admin approve/reject — the courier flow simply was not connected to it. The
/// result was a reviewer being asked to approve an identity with four digits
/// and a string someone typed, which is not a check.
///
/// So the documents go through that pipeline first, and the reference the
/// courier submits is the registered selfie's document id rather than free
/// text — it points at something a reviewer can open.
///
/// Submitting moves the profile to KycInReview and no further. Approval is an
/// admin action on a separate endpoint, so there is no "approve" path here and
/// nothing a courier can do to hurry it.
class CourierKycScreen extends ConsumerStatefulWidget {
  const CourierKycScreen({required this.courierProfileId, super.key});

  final String courierProfileId;

  @override
  ConsumerState<CourierKycScreen> createState() => _CourierKycScreenState();
}

class _CourierKycScreenState extends ConsumerState<CourierKycScreen> {
  /// The ID types a courier may present. Address proof is not asked for —
  /// a courier's service area comes from their home geohash, not a utility
  /// bill — and the selfie is captured separately rather than chosen.
  static const _idTypes = [
    IdentityDocumentType.nationalIdCard,
    IdentityDocumentType.driversLicense,
    IdentityDocumentType.passport,
  ];

  final _formKey = GlobalKey<FormState>();
  final _last4 = TextEditingController();

  IdentityDocumentType _idType = IdentityDocumentType.nationalIdCard;
  File? _idFront;
  File? _idBack;
  File? _selfie;

  /// Separate from the notifier's busy flag: uploads happen before the KYC
  /// call, so the screen is working while the notifier is still idle.
  bool _uploading = false;

  @override
  void dispose() {
    _last4.dispose();
    super.dispose();
  }

  bool get _needsBack => _idType.needsBothSides;

  /// Every page the chosen ID type requires.
  String? get _missingDocument {
    if (_idFront == null) return 'Add a photo of the front of your ${_idType.label.toLowerCase()}.';
    if (_needsBack && _idBack == null) {
      return 'Add a photo of the back of your ${_idType.label.toLowerCase()}.';
    }
    if (_selfie == null) return 'Add a selfie so we can match it to your ID.';
    return null;
  }

  /// The camera for the selfie, the gallery allowed for the ID.
  ///
  /// A selfie taken now is the whole point of a liveness check — letting one
  /// be picked from the gallery makes it worth nothing. An ID photo is a
  /// picture of a document that already exists, and people often have a good
  /// scan of it already, so forcing the camera there only produces blurry
  /// pictures in bad light.
  Future<void> _capture({
    required ImageSource source,
    required void Function(File) onPicked,
  }) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (picked == null) return;
    setState(() => onPicked(File(picked.path)));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final missing = _missingDocument;
    if (missing != null) {
      SmSnackbar.error(context, missing);
      return;
    }

    setState(() => _uploading = true);
    final CourierDocumentsSubmitted uploaded;
    try {
      uploaded = await ref.read(courierKycDocumentsProvider).submit([
        CourierDocumentCapture(
          file: _idFront!,
          type: _idType,
          side: _needsBack
              ? IdentityDocumentSide.front
              : IdentityDocumentSide.notApplicable,
        ),
        if (_needsBack && _idBack != null)
          CourierDocumentCapture(
            file: _idBack!,
            type: _idType,
            side: IdentityDocumentSide.back,
          ),
        CourierDocumentCapture(
          file: _selfie!,
          type: IdentityDocumentType.selfiePhoto,
          side: IdentityDocumentSide.notApplicable,
        ),
      ]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      // The documents are what the review is made of, so a failed upload must
      // not fall through to submitting the KYC without them.
      SmSnackbar.error(
        context,
        'Could not upload your documents. Check your connection and try '
        'again — nothing has been submitted.',
      );
      return;
    }
    if (!mounted) return;
    setState(() => _uploading = false);

    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .submitKyc(
          courierProfileId: widget.courierProfileId,
          governmentIdLast4: _last4.text.trim(),
          // Points at the registered selfie rather than being typed. The field
          // is named for a match reference and this is the only thing on hand
          // that a reviewer can actually open.
          selfieMatchRef:
              uploaded.selfie?.id ?? 'kyc-session:${uploaded.sessionId}',
        );
    if (!mounted) return;

    if (result is CourierActionOk) {
      ref.invalidate(courierProfileProvider(ref.read(courierAccountIdProvider)));
      return;
    }
    showCourierActionFeedback(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(courierActionsNotifierProvider) || _uploading;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Identity checks'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.s20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confirm who you are', style: DesignTokens.h2),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'You will be carrying other people’s parcels, so we verify '
                  'every delivery partner. A reviewer checks your ID against '
                  'your selfie by hand.',
                  style: DesignTokens.smallRegular,
                ),
                const SizedBox(height: DesignTokens.s24),

                Text('Which ID are you using?', style: DesignTokens.h3),
                const SizedBox(height: DesignTokens.s8),
                DropdownButtonFormField<IdentityDocumentType>(
                  initialValue: _idType,
                  decoration: const InputDecoration(labelText: 'ID type'),
                  items: _idTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _idType = value;
                            // A passport has no back. Keeping a previously
                            // captured one would upload a page the reviewer
                            // did not ask for and cannot place.
                            if (!value.needsBothSides) _idBack = null;
                          });
                        },
                ),
                const SizedBox(height: DesignTokens.s16),

                _DocumentSlot(
                  label: 'Front of your ${_idType.label.toLowerCase()}',
                  file: _idFront,
                  disabled: busy,
                  onPick: () => _capture(
                    source: ImageSource.gallery,
                    onPicked: (f) => _idFront = f,
                  ),
                  onCamera: () => _capture(
                    source: ImageSource.camera,
                    onPicked: (f) => _idFront = f,
                  ),
                ),
                if (_needsBack) ...[
                  const SizedBox(height: DesignTokens.s12),
                  _DocumentSlot(
                    label: 'Back of your ${_idType.label.toLowerCase()}',
                    file: _idBack,
                    disabled: busy,
                    onPick: () => _capture(
                      source: ImageSource.gallery,
                      onPicked: (f) => _idBack = f,
                    ),
                    onCamera: () => _capture(
                      source: ImageSource.camera,
                      onPicked: (f) => _idBack = f,
                    ),
                  ),
                ],
                const SizedBox(height: DesignTokens.s12),
                _DocumentSlot(
                  label: 'Selfie',
                  helper: 'Taken now — it is matched against your ID.',
                  file: _selfie,
                  disabled: busy,
                  // Camera only; see _capture.
                  onCamera: () => _capture(
                    source: ImageSource.camera,
                    onPicked: (f) => _selfie = f,
                  ),
                ),
                const SizedBox(height: DesignTokens.s24),

                TextFormField(
                  controller: _last4,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Last 4 digits of your government ID',
                    counterText: '',
                  ),
                  // Mirrors the server rule (exactly 4 digits) so a courier is
                  // told here rather than by a 422 after a round trip.
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length != 4) return 'Enter exactly 4 digits.';
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.s24),

                SizedBox(
                  width: double.infinity,
                  child: SmPrimaryButton(
                    label: _uploading
                        ? 'Uploading documents…'
                        : 'Submit for review',
                    disabled: busy,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: DesignTokens.s12),
                Text(
                  'A reviewer checks this by hand, so it is not instant. You '
                  'do not need to come back — this screen updates itself.',
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
}

/// One document to provide: its name, whether it has been picked, and how.
///
/// Shows the chosen file as a thumbnail rather than a tick, so a courier can
/// see they attached the right page the right way up before submitting — a
/// sideways or half-cropped ID is the most common reason a review comes back.
class _DocumentSlot extends StatelessWidget {
  const _DocumentSlot({
    required this.label,
    required this.file,
    required this.disabled,
    required this.onCamera,
    this.onPick,
    this.helper,
  });

  final String label;
  final String? helper;
  final File? file;
  final bool disabled;
  final VoidCallback onCamera;

  /// Null for the selfie, which may only come from the camera.
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: file == null
              ? DesignTokens.borderDefault
              : DesignTokens.primaryGreen,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: file == null
                  ? const ColoredBox(
                      color: DesignTokens.bgAppBodyLight,
                      child: Icon(
                        Icons.badge_outlined,
                        color: DesignTokens.iconLight,
                      ),
                    )
                  : Image.file(file!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: DesignTokens.mediumSemibold),
                if (helper != null)
                  Text(helper!, style: DesignTokens.tiny)
                else if (file == null)
                  Text('Not added yet', style: DesignTokens.tiny),
              ],
            ),
          ),
          if (onPick != null)
            IconButton(
              tooltip: 'Choose a file',
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: disabled ? null : onPick,
            ),
          IconButton(
            tooltip: 'Take a photo',
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: disabled ? null : onCamera,
          ),
        ],
      ),
    );
  }
}
