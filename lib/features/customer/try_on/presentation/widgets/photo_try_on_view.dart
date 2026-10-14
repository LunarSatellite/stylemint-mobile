import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/overlay_geometry.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/ar/pose_engine.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/widgets/garment_overlay.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// PHOTO mode: pick or take a full-body photo, detect the pose once, place
/// the garment, then let the buyer nudge (drag), scale (pinch) and tilt
/// (twist) it before saving or sharing.
class PhotoTryOnView extends StatefulWidget {
  const PhotoTryOnView({required this.product, this.onStarted, super.key});

  final TryOnProduct product;
  final VoidCallback? onStarted;

  @override
  State<PhotoTryOnView> createState() => _PhotoTryOnViewState();
}

class _PhotoTryOnViewState extends State<PhotoTryOnView> {
  final _boundaryKey = GlobalKey();
  File? _photo;
  Size? _photoSize;
  OverlayPlacement? _placement;
  bool _detecting = false;
  String? _hint;
  bool _started = false;

  // Gesture adjustments, in view pixels / multipliers.
  Offset _offset = Offset.zero;
  double _scale = 1;
  double _tilt = 0;
  double _scaleAtStart = 1;
  double _tiltAtStart = 0;

  Future<void> _pick(ImageSource source) async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
    } on Object {
      if (mounted) {
        SmSnackbar.error(
          context,
          source == ImageSource.camera
              ? 'Camera access is needed to take a photo. Allow it in Settings.'
              : 'Photo access is needed to pick a photo. Allow it in Settings.',
        );
      }
      return;
    }
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      _photo = file;
      _placement = null;
      _detecting = true;
      _hint = null;
      _offset = Offset.zero;
      _scale = 1;
      _tilt = 0;
    });
    await _detect(file);
  }

  Future<void> _detect(File file) async {
    final engine = PoseEngine(stream: false);
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      final body = await engine.detect(InputImage.fromFile(file), size);
      final result = body == null
          ? const OverlayResult.missing(PoseProblem.notFound)
          : OverlayGeometry.compute(
              garment: widget.product.garmentType,
              body: body,
              overlayAspect: widget.product.overlayAspect,
            );
      if (!mounted) return;
      setState(() {
        _photoSize = size;
        _placement = result.placement ?? _fallbackPlacement(size);
        _hint = result.isPlaced
            ? null
            : '$poseNotFoundHint We placed it in the middle — drag and '
                  'pinch to fit.';
      });
      if (!_started) {
        _started = true;
        widget.onStarted?.call();
      }
    } on Object {
      if (mounted) {
        setState(() => _hint = 'We could not read that photo. Try another.');
      }
    } finally {
      await engine.close();
      if (mounted) setState(() => _detecting = false);
    }
  }

  /// No pose: centre the garment so the buyer can still position it by hand.
  OverlayPlacement _fallbackPlacement(Size size) {
    final w = size.width * 0.5;
    return OverlayPlacement(
      center: Pt(size.width / 2, size.height / 2),
      width: w,
      height: w * widget.product.overlayAspect,
    );
  }

  Future<void> _share() async {
    final ok = await shareSnapshot(
      _boundaryKey,
      text: 'Trying on ${widget.product.name} on StyleMint',
    );
    if (!ok && mounted) {
      SmSnackbar.error(context, 'Could not save the picture.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    if (photo == null) {
      return _PickPrompt(onPick: _pick);
    }
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final view = constraints.biggest;
              final size = _photoSize;
              final placement = _placement;
              ViewPlacement? vp;
              if (size != null && placement != null) {
                final base = mapPlacementToView(
                  placement: placement,
                  imageWidth: size.width,
                  imageHeight: size.height,
                  viewWidth: view.width,
                  viewHeight: view.height,
                  fit: ViewFit.contain,
                );
                final w = base.width * _scale;
                final h = base.height * _scale;
                vp = ViewPlacement(
                  left: base.centerX + _offset.dx - w / 2,
                  top: base.centerY + _offset.dy - h / 2,
                  width: w,
                  height: h,
                  rotation: base.rotation + _tilt,
                );
              }
              return GestureDetector(
                onScaleStart: (_) {
                  _scaleAtStart = _scale;
                  _tiltAtStart = _tilt;
                },
                onScaleUpdate: (d) => setState(() {
                  // focalPointDelta is per update, so it accumulates.
                  _offset += d.focalPointDelta;
                  _scale = (_scaleAtStart * d.scale).clamp(0.3, 3.0);
                  _tilt = _tiltAtStart + d.rotation;
                }),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(photo, fit: BoxFit.contain),
                        if (vp != null)
                          GarmentOverlay(
                            placement: vp,
                            imageUrl: widget.product.overlayImageUrl,
                          ),
                        if (_detecting)
                          const Center(
                            child: CircularProgressIndicator(
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_hint case final String hint)
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s8),
            child: TryOnHint(message: hint),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s8,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Choose another photo',
                onPressed: () => unawaited(_pick(ImageSource.gallery)),
                icon: const Icon(
                  Icons.photo_library_outlined,
                  color: DesignTokens.textWhite,
                ),
              ),
              IconButton(
                tooltip: 'Take a photo',
                onPressed: () => unawaited(_pick(ImageSource.camera)),
                icon: const Icon(
                  Icons.photo_camera_outlined,
                  color: DesignTokens.textWhite,
                ),
              ),
              IconButton(
                tooltip: 'Reset position',
                onPressed: () => setState(() {
                  _offset = Offset.zero;
                  _scale = 1;
                  _tilt = 0;
                }),
                icon: const Icon(
                  Icons.center_focus_strong_outlined,
                  color: DesignTokens.textWhite,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _placement == null
                    ? null
                    : () => unawaited(_share()),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Save / share'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickPrompt extends StatelessWidget {
  const _PickPrompt({required this.onPick});

  final Future<void> Function(ImageSource) onPick;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.accessibility_new_rounded,
              size: DesignTokens.iconXLarge,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              'Use a well-lit, front-facing photo where your shoulders and '
              'hips are visible.',
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            Wrap(
              spacing: DesignTokens.s12,
              runSpacing: DesignTokens.s8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: DesignTokens.primaryButtonStyle(),
                  onPressed: () => unawaited(onPick(ImageSource.gallery)),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose a photo'),
                ),
                OutlinedButton.icon(
                  onPressed: () => unawaited(onPick(ImageSource.camera)),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take a photo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
