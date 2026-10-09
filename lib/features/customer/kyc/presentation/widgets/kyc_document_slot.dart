import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One photo the form asks for: its name, a thumbnail once it is there, and
/// how to provide it.
///
/// A thumbnail rather than a tick, so the buyer can see they attached the
/// right page the right way up — a sideways or half-cropped ID is the most
/// common reason a review comes back. Same shape as the courier KYC slot.
class KycDocumentSlot extends StatelessWidget {
  const KycDocumentSlot({
    required this.label,
    required this.disabled,
    required this.onCamera,
    this.file,
    this.uploadedThumbnailUrl,
    this.uploaded = false,
    this.onPick,
    this.helper,
    super.key,
  });

  final String label;
  final String? helper;

  /// The photo captured on this device, not yet sent.
  final File? file;

  /// Already on the server in the open session.
  final bool uploaded;
  final String? uploadedThumbnailUrl;
  final bool disabled;
  final VoidCallback onCamera;

  /// Null for the selfie, which may only come from the camera.
  final VoidCallback? onPick;

  bool get _hasPhoto => file != null || uploaded;

  @override
  Widget build(BuildContext context) {
    final thumbnail = file != null
        ? Image.file(file!, fit: BoxFit.cover)
        : uploadedThumbnailUrl != null
        ? Image.network(
            uploadedThumbnailUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _Placeholder(
              icon: Icons.check_circle_outline_rounded,
            ),
          )
        : _Placeholder(
            icon: uploaded
                ? Icons.check_circle_outline_rounded
                : Icons.badge_outlined,
          );
    final status = file != null
        ? 'Ready to send'
        : uploaded
        ? 'Uploaded — retake to replace it'
        : 'Not added yet';

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: _hasPhoto
              ? DesignTokens.primaryGreen
              : DesignTokens.borderDefault,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: SizedBox(width: 56, height: 56, child: thumbnail),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: DesignTokens.mediumSemibold),
                Text(helper ?? status, style: DesignTokens.tiny),
                if (helper != null) Text(status, style: DesignTokens.tiny),
              ],
            ),
          ),
          if (onPick != null)
            IconButton(
              tooltip: 'Choose a photo',
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

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: DesignTokens.bgAppBodyLight,
    child: Icon(icon, color: DesignTokens.iconLight),
  );
}
