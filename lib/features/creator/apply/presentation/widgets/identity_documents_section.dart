import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/identity_document.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_documents_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Identity-document step of the creator apply flow.
///
/// Uploads go to the Identity module account-scoped KYC pipeline, which
/// accepts JPG, PNG and PDF up to 25 MB. The picker filter and the size
/// check here mirror those server-side limits so a creator is told locally
/// rather than after a failed upload.
class IdentityDocumentsSection extends ConsumerStatefulWidget {
  const IdentityDocumentsSection({super.key});

  @override
  ConsumerState<IdentityDocumentsSection> createState() =>
      _IdentityDocumentsSectionState();
}

class _IdentityDocumentsSectionState
    extends ConsumerState<IdentityDocumentsSection> {
  static const _maxBytes = 25 * 1024 * 1024;
  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  IdentityDocumentType _type = IdentityDocumentType.nationalIdCard;

  @override
  void initState() {
    super.initState();
    // Reflect anything already attached to an open session, so returning to
    // this step does not look like a fresh start.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(creatorDocumentsNotifierProvider.notifier).load();
      }
    });
  }

  Future<void> _pick(IdentityDocumentSide side) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    final files = result?.files ?? const <PlatformFile>[];
    if (files.isEmpty) return;
    final picked = files.first;
    final path = picked.path;
    if (path == null) return;

    if (picked.size > _maxBytes) {
      _toast('That file is larger than 25 MB. Please choose a smaller one.');
      return;
    }

    final ok = await ref
        .read(creatorDocumentsNotifierProvider.notifier)
        .upload(file: File(path), type: _type, side: side);

    if (!mounted) return;
    final state = ref.read(creatorDocumentsNotifierProvider);
    _toast(ok ? 'Document uploaded.' : (state.errorMessage ?? 'Upload failed.'));
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creatorDocumentsNotifierProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Identity Verification',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Upload a government-issued document so we can verify who you '
            'are. JPG, PNG or PDF, up to 25 MB.',
            style: DesignTokens.smallDescription,
          ),
          const SizedBox(height: DesignTokens.s12),
          DropdownButtonFormField<IdentityDocumentType>(
            initialValue: _type,
            dropdownColor: DesignTokens.bgAppBodyLight,
            decoration: const InputDecoration(
              labelText: 'Document type',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            style: DesignTokens.bodyText,
            items: [
              for (final t in IdentityDocumentType.values)
                DropdownMenuItem(value: t, child: Text(t.label)),
            ],
            onChanged: state.isBusy
                ? null
                : (value) {
                    if (value != null) setState(() => _type = value);
                  },
          ),
          const SizedBox(height: DesignTokens.s12),
          if (_type.needsBothSides)
            Row(
              children: [
                Expanded(
                  child: _UploadButton(
                    label: 'Upload front',
                    busy: state.isUploading,
                    onTap: () => _pick(IdentityDocumentSide.front),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: _UploadButton(
                    label: 'Upload back',
                    busy: state.isUploading,
                    onTap: () => _pick(IdentityDocumentSide.back),
                  ),
                ),
              ],
            )
          else
            _UploadButton(
              label: 'Upload document',
              busy: state.isUploading,
              onTap: () => _pick(IdentityDocumentSide.notApplicable),
            ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              state.errorMessage!,
              style:
                  DesignTokens.smallRegular.copyWith(color: DesignTokens.colorError),
            ),
          ],
          if (state.documents.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            const Divider(
              height: 1,
              thickness: 1,
              color: DesignTokens.borderDefault,
            ),
            const SizedBox(height: DesignTokens.s8),
            ...state.documents.map((d) => _DocumentRow(document: d)),
          ],
        ],
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: busy ? null : onTap,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document});

  final IdentityDocument document;

  @override
  Widget build(BuildContext context) {
    final sideLabel = switch (document.side) {
      IdentityDocumentSide.front => ' (front)',
      IdentityDocumentSide.back => ' (back)',
      IdentityDocumentSide.notApplicable => '',
    };

    final IconData icon;
    final Color color;
    if (document.isRejected) {
      icon = Icons.error_outline;
      color = DesignTokens.colorError;
    } else if (document.isApproved) {
      icon = Icons.check_circle_outline;
      color = DesignTokens.primaryGreen;
    } else {
      icon = Icons.schedule;
      color = DesignTokens.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${document.type.label}$sideLabel',
                  style: DesignTokens.bodyText,
                ),
                Text(
                  document.status.isEmpty ? 'Pending review' : document.status,
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textMuted),
                ),
                if (document.rejectionReason != null)
                  Text(
                    document.rejectionReason!,
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.colorError),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
