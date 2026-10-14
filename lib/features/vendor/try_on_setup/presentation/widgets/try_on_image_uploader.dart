import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Picks a garment image, checks it on the phone (format, size, alpha,
/// transparent share) and hands it to [onUpload] only when it passes. The
/// server re-checks everything; its message comes back through [onUpload]'s
/// result and is shown here.
class TryOnImageUploader extends StatefulWidget {
  const TryOnImageUploader({
    required this.onUpload,
    required this.onDelete,
    this.currentImageUrl,
    super.key,
  });

  final String? currentImageUrl;

  /// Uploads [path]; returns the server's refusal message, or null.
  final Future<String?> Function(String path, void Function(double) onProgress)
  onUpload;
  final Future<String?> Function() onDelete;

  @override
  State<TryOnImageUploader> createState() => _TryOnImageUploaderState();
}

class _TryOnImageUploaderState extends State<TryOnImageUploader> {
  List<String> _problems = const [];
  String? _serverMessage;
  double? _progress;
  bool _checking = false;

  Future<void> _pick() async {
    XFile? picked;
    try {
      // No resize options: resizing re-encodes and can drop the alpha.
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
    } on Object {
      if (mounted) {
        setState(
          () => _problems = const [
            'Photo access is needed to choose the image. Allow it in Settings.',
          ],
        );
      }
      return;
    }
    if (picked == null) return;
    setState(() {
      _checking = true;
      _problems = const [];
      _serverMessage = null;
    });
    final file = File(picked.path);
    final bytes = await file.readAsBytes();
    final problems = await checkTryOnImage(
      bytes,
      fileSize: await file.length(),
    );
    if (!mounted) return;
    setState(() {
      _checking = false;
      _problems = problems;
    });
    if (problems.isNotEmpty) return;

    setState(() => _progress = 0);
    final message = await widget.onUpload(picked.path, (p) {
      if (mounted) setState(() => _progress = p);
    });
    if (!mounted) return;
    setState(() {
      _progress = null;
      _serverMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.currentImageUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Guidance(),
        const SizedBox(height: DesignTokens.s12),
        if (url != null)
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              // A checkerboard-ish backdrop so transparency is visible.
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        if (_progress != null) ...[
          const SizedBox(height: DesignTokens.s8),
          LinearProgressIndicator(
            value: _progress,
            color: DesignTokens.primaryGreen,
          ),
        ],
        for (final p in _problems)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s4),
            child: Text(
              p,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
        if (_serverMessage case final String m)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s4),
            child: Text(
              m,
              key: const Key('try-on-image-server-error'),
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
        const SizedBox(height: DesignTokens.s8),
        Row(
          children: [
            ElevatedButton.icon(
              key: const Key('try-on-image-pick'),
              style: DesignTokens.primaryButtonStyle(),
              onPressed: _checking || _progress != null
                  ? null
                  : () => unawaited(_pick()),
              icon: const Icon(Icons.upload_rounded),
              label: Text(
                url == null ? 'Upload try-on image' : 'Replace image',
              ),
            ),
            if (url != null) ...[
              const SizedBox(width: DesignTokens.s8),
              TextButton(
                onPressed: _progress != null
                    ? null
                    : () async {
                        final m = await widget.onDelete();
                        if (mounted) setState(() => _serverMessage = m);
                      },
                child: const Text('Remove'),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Guidance extends StatelessWidget {
  const _Guidance();

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Front view of the garment only — flat-lay or ghost mannequin, no model.',
      'Background removed: export as a transparent PNG (or WebP with alpha).',
      'At least 600 px on the shortest side, up to 5 MB.',
      'Crop tight to the garment; keep it straight and centred.',
    ];
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.infoFillDark,
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final t in tips)
            Text(
              '• $t',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.infoTextLight,
              ),
            ),
        ],
      ),
    );
  }
}

/// All client-side checks on a try-on image. Empty = OK to upload.
Future<List<String>> checkTryOnImage(Uint8List bytes, {int? fileSize}) async {
  final check = TryOnImageRules.inspect(bytes, fileSize: fileSize);
  if (!check.ok || check.hasAlpha == false) return check.problems;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData();
    frame.image.dispose();
    if (data == null) return check.problems;
    final share = TryOnImageRules.transparentShare(data.buffer.asUint8List());
    final problem = TryOnImageRules.transparencyProblem(share);
    return [...check.problems, ?problem];
  } on Object {
    // Could not decode here (e.g. an unusual WebP); the server will judge.
    return check.problems;
  }
}
