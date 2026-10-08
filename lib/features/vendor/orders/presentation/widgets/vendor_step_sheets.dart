import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What the reject sheet hands back.
class VendorRejectInput {
  const VendorRejectInput({required this.reason, this.note});

  final VendorRejectionReason reason;
  final String? note;
}

/// What the own-courier handover sheet collected.
///
/// [courierProfileId] is never set by that sheet any more: StyleMint riders
/// are chosen on the delivery-partner sheet. It stays for the directed-offer
/// path (`offerThenHandOver`), which still takes one.
class VendorHandoverInput {
  const VendorHandoverInput({
    this.carrier,
    this.trackingNumber,
    this.note,
    this.courierProfileId,
  });

  final String? carrier;
  final String? trackingNumber;
  final String? note;
  final String? courierProfileId;
}

Future<VendorRejectInput?> showVendorRejectSheet(BuildContext context) =>
    showModalBottomSheet<VendorRejectInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLarge),
        ),
      ),
      builder: (_) => const VendorRejectSheet(),
    );

Future<VendorHandoverInput?> showVendorHandoverSheet(BuildContext context) =>
    showModalBottomSheet<VendorHandoverInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLarge),
        ),
      ),
      builder: (_) => const VendorHandoverSheet(),
    );

/// Reject: one reason code from the contract plus a note (≤ 200) that the
/// buyer sees. The note is required for "Other".
class VendorRejectSheet extends StatefulWidget {
  const VendorRejectSheet({super.key});

  static const Key submitKey = ValueKey<String>('vendor-reject-submit');
  static const Key noteFieldKey = ValueKey<String>('vendor-reject-note');
  static const noteRequiredError = 'Add a note so the buyer knows why.';

  @override
  State<VendorRejectSheet> createState() => _VendorRejectSheetState();
}

class _VendorRejectSheetState extends State<VendorRejectSheet> {
  final _note = TextEditingController();
  VendorRejectionReason? _reason;
  bool _attempted = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _noteMissing =>
      (_reason?.requiresNote ?? false) && _note.text.trim().isEmpty;

  void _submit() {
    final reason = _reason;
    if (reason == null) return;
    if (_noteMissing) {
      setState(() => _attempted = true);
      return;
    }
    final note = _note.text.trim();
    Navigator.of(context).pop(
      VendorRejectInput(reason: reason, note: note.isEmpty ? null : note),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Reject this order?',
      body:
          'The buyer is refunded in full and sees your reason on their '
          'tracking timeline.',
      primaryLabel: 'Reject order',
      primaryKey: VendorRejectSheet.submitKey,
      destructive: true,
      onPrimary: _reason == null ? null : _submit,
      children: [
        const _FieldLabel('Reason'),
        const SizedBox(height: DesignTokens.s4),
        for (final reason in VendorRejectionReason.values)
          _ReasonOption(
            label: reason.label,
            selected: _reason == reason,
            onTap: () => setState(() {
              _reason = reason;
              _attempted = false;
            }),
          ),
        const SizedBox(height: DesignTokens.s12),
        _SheetTextField(
          fieldKey: VendorRejectSheet.noteFieldKey,
          controller: _note,
          label: (_reason?.requiresNote ?? false)
              ? 'Note for the buyer (required)'
              : 'Note for the buyer (optional)',
          maxLength: vendorNoteMaxLength,
          maxLines: 3,
          errorText: _attempted && _noteMissing
              ? VendorRejectSheet.noteRequiredError
              : null,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}

/// Hand over to your own courier: optional carrier + tracking number (both or
/// neither) and an optional note shown on the buyer's "Picked up" step.
///
/// The fallback to the delivery-partner sheet, reached from it — StyleMint
/// riders are found and chosen there, not here.
class VendorHandoverSheet extends StatefulWidget {
  const VendorHandoverSheet({super.key});

  static const Key submitKey = ValueKey<String>('vendor-handover-submit');
  static const Key carrierFieldKey = ValueKey<String>(
    'vendor-handover-carrier',
  );
  static const Key trackingFieldKey = ValueKey<String>(
    'vendor-handover-tracking',
  );
  static const Key noteFieldKey = ValueKey<String>('vendor-handover-note');
  static const carrierMissingError =
      'Add the carrier for this tracking number.';
  static const trackingMissingError = 'Add the tracking number too.';

  @override
  State<VendorHandoverSheet> createState() => _VendorHandoverSheetState();
}

class _VendorHandoverSheetState extends State<VendorHandoverSheet> {
  final _carrier = TextEditingController();
  final _tracking = TextEditingController();
  final _note = TextEditingController();
  bool _attempted = false;

  @override
  void dispose() {
    _carrier.dispose();
    _tracking.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _c => _carrier.text.trim();
  String get _t => _tracking.text.trim();

  String? get _carrierError => _t.isNotEmpty && _c.isEmpty
      ? VendorHandoverSheet.carrierMissingError
      : null;

  String? get _trackingError => _c.isNotEmpty && _t.isEmpty
      ? VendorHandoverSheet.trackingMissingError
      : null;

  void _submit() {
    if (_carrierError != null || _trackingError != null) {
      setState(() => _attempted = true);
      return;
    }
    final note = _note.text.trim();
    Navigator.of(context).pop(
      VendorHandoverInput(
        carrier: _c.isEmpty ? null : _c,
        trackingNumber: _t.isEmpty ? null : _t,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Hand over to your own courier',
      body:
          'Add your courier’s tracking details — both the carrier and the '
          'number, or neither.',
      primaryLabel: 'Confirm handover',
      primaryKey: VendorHandoverSheet.submitKey,
      onPrimary: _submit,
      children: [
        _SheetTextField(
          fieldKey: VendorHandoverSheet.carrierFieldKey,
          controller: _carrier,
          label: 'Carrier (optional)',
          maxLength: vendorCarrierMaxLength,
          errorText: _attempted ? _carrierError : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: DesignTokens.s8),
        _SheetTextField(
          fieldKey: VendorHandoverSheet.trackingFieldKey,
          controller: _tracking,
          label: 'Tracking number (optional)',
          maxLength: vendorTrackingMaxLength,
          errorText: _attempted ? _trackingError : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: DesignTokens.s8),
        _SheetTextField(
          fieldKey: VendorHandoverSheet.noteFieldKey,
          controller: _note,
          label: 'Handover note (optional)',
          maxLength: vendorNoteMaxLength,
          maxLines: 3,
        ),
      ],
    );
  }
}

/// What the seal sheet hands back: the number on the sticker and the local
/// path of the photo. The photo is uploaded by the caller, not here, so the
/// sheet stays free of network work like every other sheet in this file.
class VendorSealInput {
  const VendorSealInput({required this.sealId, required this.photoPath});

  final String sealId;
  final String photoPath;
}

Future<VendorSealInput?> showVendorSealSheet(BuildContext context) =>
    showModalBottomSheet<VendorSealInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLarge),
        ),
      ),
      builder: (_) => const VendorSealSheet(),
    );

/// Seal the parcel: the number printed on the tamper-evident sticker, and a
/// photo of it on the closed box.
///
/// Both are required and neither can be filled in for the vendor. The seal
/// exists so a buyer can tell whether the box was opened in transit, so a
/// number the platform invented, or a photo it did not take, would prove
/// nothing. `Package.ApplySeal` guards both server-side for the same reason.
///
/// This is also not optional in a weaker sense: an unsealed parcel is refused
/// when a courier accepts it, and that refusal lands in a dead-letter queue
/// rather than in front of anyone. Sealing at packing is what keeps the
/// delivery from failing silently later.
class VendorSealSheet extends StatefulWidget {
  const VendorSealSheet({super.key});

  static const Key submitKey = ValueKey<String>('vendor-seal-submit');
  static const Key sealFieldKey = ValueKey<String>('vendor-seal-id');
  static const Key photoKey = ValueKey<String>('vendor-seal-photo');
  static const sealMissingError = 'Enter the number printed on the seal.';
  static const photoMissingError = 'Add a photo of the seal on the box.';

  /// Matches the server guard on `sealId`.
  static const int sealIdMaxLength = 64;

  @override
  State<VendorSealSheet> createState() => _VendorSealSheetState();
}

class _VendorSealSheetState extends State<VendorSealSheet> {
  final _sealId = TextEditingController();
  String? _photoPath;
  bool _attempted = false;

  @override
  void dispose() {
    _sealId.dispose();
    super.dispose();
  }

  String get _s => _sealId.text.trim();

  String? get _sealError =>
      _s.isEmpty ? VendorSealSheet.sealMissingError : null;
  String? get _photoError =>
      _photoPath == null ? VendorSealSheet.photoMissingError : null;

  Future<void> _pickPhoto(ImageSource source) async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      final denied = error.code.contains('access_denied');
      SmSnackbar.error(
        context,
        denied
            ? 'Camera or photo access was not granted.'
            : 'Could not open the image picker. Please try again.',
      );
      return;
    }
    if (picked == null) return;
    setState(() => _photoPath = picked!.path);
  }

  void _submit() {
    if (_sealError != null || _photoError != null) {
      setState(() => _attempted = true);
      return;
    }
    Navigator.of(context).pop(
      VendorSealInput(sealId: _s, photoPath: _photoPath!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Seal the parcel',
      body:
          'Stick the seal on the closed box, then enter its number and take a '
          'photo. The buyer checks both on arrival, so neither can be skipped.',
      primaryLabel: 'Seal and mark packed',
      primaryKey: VendorSealSheet.submitKey,
      onPrimary: _submit,
      children: [
        _SheetTextField(
          fieldKey: VendorSealSheet.sealFieldKey,
          controller: _sealId,
          label: 'Seal number',
          maxLength: VendorSealSheet.sealIdMaxLength,
          errorText: _attempted ? _sealError : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (_photoPath != null)
          ClipRRect(
            key: VendorSealSheet.photoKey,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            child: Image.file(
              File(_photoPath!),
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        if (_photoPath != null) const SizedBox(height: DesignTokens.s8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: Text(_photoPath == null ? 'Take photo' : 'Retake'),
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Choose'),
              ),
            ),
          ],
        ),
        if (_attempted && _photoError != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            _photoError!,
            style: DesignTokens.tiny.copyWith(color: DesignTokens.colorError),
          ),
        ],
      ],
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.primaryKey,
    required this.onPrimary,
    required this.children,
    this.destructive = false,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final Key primaryKey;
  final VoidCallback? onPrimary;
  final List<Widget> children;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final background = destructive
        ? DesignTokens.colorError
        : DesignTokens.primaryGreen;
    final foreground = destructive
        ? DesignTokens.textDark
        : DesignTokens.buttonPrimaryText;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s20,
          DesignTokens.s12,
          DesignTokens.s20,
          DesignTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            Semantics(
              header: true,
              child: Text(title, style: DesignTokens.displaySection),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(body, style: DesignTokens.smallDescription),
            const SizedBox(height: DesignTokens.s16),
            ...children,
            const SizedBox(height: DesignTokens.s16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.textLight,
                      minimumSize: const Size.fromHeight(52),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: FilledButton(
                    key: primaryKey,
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(
                      backgroundColor: background,
                      foregroundColor: foreground,
                      disabledBackgroundColor: DesignTokens.bgAppBodyLight,
                      disabledForegroundColor: DesignTokens.textMuted,
                      minimumSize: const Size.fromHeight(52),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(primaryLabel, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: DesignTokens.eyebrow,
  );
}

/// Single-choice row with a 48dp touch target.
class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textMuted,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Text(
                  label,
                  style: selected
                      ? DesignTokens.mediumSemibold
                      : DesignTokens.mediumRegular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.maxLength,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final int maxLength;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      key: fieldKey,
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: 1,
      onChanged: onChanged,
      style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
        errorText: errorText,
        errorMaxLines: 2,
        filled: true,
        fillColor: DesignTokens.inputFieldFill,
        counterStyle: DesignTokens.tiny,
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(DesignTokens.primaryGreen),
        errorBorder: border(DesignTokens.colorError),
        focusedErrorBorder: border(DesignTokens.colorError),
      ),
    );
  }
}
