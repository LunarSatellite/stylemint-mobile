import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Takes one photo and returns its local path, or null when the rider backed
/// out. Overridable so widget tests need no camera.
typedef CourierPhotoPicker = Future<String?> Function();

Future<String?> takeCourierProofPhoto() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 80,
  );
  return picked?.path;
}

/// What the rider recorded at the buyer's door.
class ReturnCollectResult {
  const ReturnCollectResult({required this.photoUrls, this.note});

  final List<String> photoUrls;
  final String? note;
}

Future<ReturnCollectResult?> showCourierReturnCollectSheet(
  BuildContext context, {
  CourierPhotoPicker pickPhoto = takeCourierProofPhoto,
}) => showModalBottomSheet<ReturnCollectResult>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: DesignTokens.bgAppBody,
  builder: (_) => CourierReturnCollectSheet(pickPhoto: pickPhoto),
);

/// "Collect" on a return pickup: 1–3 photos of the item before the rider
/// takes it (return pickup contract §4). The photos are the evidence if the
/// item turns out damaged or wrong, so at least one is required.
class CourierReturnCollectSheet extends ConsumerStatefulWidget {
  const CourierReturnCollectSheet({
    this.pickPhoto = takeCourierProofPhoto,
    super.key,
  });

  final CourierPhotoPicker pickPhoto;

  static const maxPhotos = 3;
  static const addPhotoKey = ValueKey<String>('courier-collect-add-photo');
  static const collectKey = ValueKey<String>('courier-collect-confirm');
  static const needPhotoText = 'Take at least one photo of the item.';

  @override
  ConsumerState<CourierReturnCollectSheet> createState() =>
      _CourierReturnCollectSheetState();
}

class _CourierReturnCollectSheetState
    extends ConsumerState<CourierReturnCollectSheet> {
  final List<String> _urls = [];
  final List<String> _paths = [];
  final TextEditingController _note = TextEditingController();
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_uploading || _urls.length >= CourierReturnCollectSheet.maxPhotos) {
      return;
    }
    final path = await widget.pickPhoto();
    if (path == null || !mounted) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    final result = await ref
        .read(courierJobActionsNotifierProvider.notifier)
        .uploadPhoto(path);
    if (!mounted) return;
    setState(() {
      _uploading = false;
      result.fold(
        (failure) => _error =
            "Couldn't upload the photo. ${NetworkExceptions.getMessage(failure)}",
        (url) {
          _urls.add(url);
          _paths.add(path);
        },
      );
    });
  }

  void _collect() {
    if (_urls.isEmpty) {
      setState(() => _error = CourierReturnCollectSheet.needPhotoText);
      return;
    }
    final note = _note.text.trim();
    Navigator.of(context).pop(
      ReturnCollectResult(
        photoUrls: List.unmodifiable(_urls),
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final full = _urls.length >= CourierReturnCollectSheet.maxPhotos;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s20,
          DesignTokens.s16,
          DesignTokens.s20,
          DesignTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Collect the return', style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Take 1 to 3 photos of the item before you take it. Then the '
              'buyer scans your code.',
              style: DesignTokens.smallRegular,
            ),
            const SizedBox(height: DesignTokens.s16),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                for (var i = 0; i < _paths.length; i++)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.s8),
                    child: SizedBox.square(
                      dimension: 72,
                      child: Image.file(
                        File(_paths[i]),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: DesignTokens.bgAppBodyLight,
                          child: Center(
                            child: Text(
                              'Photo ${i + 1}',
                              style: DesignTokens.tiny,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (_paths.isNotEmpty) const SizedBox(height: DesignTokens.s12),
            OutlinedButton.icon(
              key: CourierReturnCollectSheet.addPhotoKey,
              onPressed: _uploading || full ? null : _addPhoto,
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined),
              label: Text(
                full
                    ? '3 photos added'
                    : _urls.isEmpty
                    ? 'Take a photo'
                    : 'Add another photo',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextField(
              controller: _note,
              maxLines: 2,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Anything the seller should know',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                _error!,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.colorError,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s12),
            FilledButton.icon(
              key: CourierReturnCollectSheet.collectKey,
              onPressed: _urls.isEmpty || _uploading ? null : _collect,
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Collect and show my code'),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Can't collect": the buyer was not there, the address was wrong, or the
/// buyer refused. Returns the code to report, or null.
Future<DeliveryExceptionCode?> showCourierCantCollectSheet(
  BuildContext context,
) => showModalBottomSheet<DeliveryExceptionCode>(
  context: context,
  backgroundColor: DesignTokens.bgAppBody,
  builder: (sheetContext) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Text("Why can't you collect it?", style: DesignTokens.h3),
        ),
        for (final code in DeliveryExceptionCode.cantCollect)
          ListTile(
            key: ValueKey<String>('courier-cant-collect-${code.wire}'),
            title: Text(code.label),
            subtitle: code == DeliveryExceptionCode.handoverRefused
                ? const Text('The return is cancelled')
                : const Text('The seller can send a rider again'),
            onTap: () => Navigator.of(sheetContext).pop(code),
          ),
      ],
    ),
  ),
);
