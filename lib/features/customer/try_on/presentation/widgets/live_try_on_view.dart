import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/app_settings_launcher.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/overlay_geometry.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/ar/pose_engine.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/widgets/garment_overlay.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum _CameraStatus { starting, ready, denied, unavailable }

/// LIVE mode: the front camera with the garment placed every frame from
/// on-device pose landmarks.
///
/// Frames are processed one at a time — while ML Kit is busy, new frames are
/// dropped rather than queued, so the overlay never lags behind the preview.
class LiveTryOnView extends StatefulWidget {
  const LiveTryOnView({
    required this.product,
    this.onStarted,
    this.cameraFactory,
    super.key,
  });

  final TryOnProduct product;

  /// Called once, when the first frame with a body is placed — the moment a
  /// try-on session really started.
  final VoidCallback? onStarted;

  /// Test seam: lists cameras. Defaults to [availableCameras].
  final Future<List<CameraDescription>> Function()? cameraFactory;

  @override
  State<LiveTryOnView> createState() => _LiveTryOnViewState();
}

class _LiveTryOnViewState extends State<LiveTryOnView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  PoseEngine? _engine;
  final _smoother = PlacementSmoother();
  final _boundaryKey = GlobalKey();

  _CameraStatus _status = _CameraStatus.starting;
  bool _busy = false;
  bool _started = false;
  int _frame = 0;

  OverlayPlacement? _placement;
  Size? _uprightSize;
  bool _lowLight = false;
  bool _poseMissing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stop());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera must be released in the background and re-acquired after,
    // or Android hands it to nobody and the preview stays black.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_stop());
    } else if (state == AppLifecycleState.resumed &&
        _controller == null &&
        _status != _CameraStatus.denied) {
      unawaited(_start());
    }
  }

  Future<void> _start() async {
    setState(() => _status = _CameraStatus.starting);
    try {
      final cameras = await (widget.cameraFactory ?? availableCameras)();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _status = _CameraStatus.unavailable);
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: streamFormatGroup,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = camera;
      _controller = controller;
      _engine = PoseEngine(stream: true);
      _smoother.reset();
      await controller.startImageStream(_onFrame);
      if (mounted) setState(() => _status = _CameraStatus.ready);
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = e.code.startsWith('CameraAccess');
      setState(
        () =>
            _status = denied ? _CameraStatus.denied : _CameraStatus.unavailable,
      );
    } on Object {
      if (mounted) setState(() => _status = _CameraStatus.unavailable);
    }
  }

  Future<void> _stop() async {
    final controller = _controller;
    final engine = _engine;
    _controller = null;
    _engine = null;
    try {
      if (controller?.value.isStreamingImages ?? false) {
        await controller!.stopImageStream();
      }
    } on Object {
      // Already stopped.
    }
    await controller?.dispose();
    await engine?.close();
  }

  Future<void> _onFrame(CameraImage image) async {
    final controller = _controller;
    final camera = _camera;
    final engine = _engine;
    if (_busy || controller == null || camera == null || engine == null) {
      return;
    }
    _busy = true;
    try {
      final frame = frameFromCameraImage(
        image,
        camera,
        controller.value.deviceOrientation,
      );
      if (frame == null) return;
      // Luma every ~15 frames is plenty; it changes slowly.
      final lowLight = _frame++ % 15 == 0
          ? meanLuma(frame.luma) < lowLightThreshold
          : _lowLight;
      final body = await engine.detect(frame.input, frame.uprightSize);
      final result = body == null
          ? const OverlayResult.missing(PoseProblem.notFound)
          : OverlayGeometry.compute(
              garment: widget.product.garmentType,
              body: body,
              overlayAspect: widget.product.overlayAspect,
            );
      final placed = _smoother.add(result.placement);
      if (!mounted) return;
      if (placed != null && !_started) {
        _started = true;
        widget.onStarted?.call();
      }
      setState(() {
        _uprightSize = frame.uprightSize;
        _placement = placed;
        _poseMissing = placed == null;
        _lowLight = lowLight;
      });
    } on Object {
      // A dropped frame is invisible; the next one will do.
    } finally {
      _busy = false;
    }
  }

  Future<void> _capture() async {
    final ok = await shareSnapshot(
      _boundaryKey,
      text: 'Trying on ${widget.product.name} on StyleMint',
    );
    if (!ok && mounted) {
      SmSnackbar.error(context, 'Could not capture the picture.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_status) {
      _CameraStatus.starting => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      ),
      _CameraStatus.denied => _CameraProblem(
        icon: Icons.no_photography_outlined,
        message:
            'StyleMint needs the camera to show the garment on you. Allow '
            'camera access in Settings, or use a photo instead.',
        actionLabel: 'Open Settings',
        onAction: () => unawaited(openSystemAppSettings()),
      ),
      _CameraStatus.unavailable => _CameraProblem(
        icon: Icons.videocam_off_outlined,
        message:
            'The camera could not be started. Try again, or use a photo '
            'instead.',
        actionLabel: 'Try again',
        onAction: () => unawaited(_start()),
      ),
      _CameraStatus.ready => _buildPreview(),
    };
  }

  Widget _buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    // previewSize is landscape (sensor) — upright it is the other way round.
    final preview = controller.value.previewSize ?? const Size(640, 480);
    final upright = Size(preview.height, preview.width);
    final mirror = _camera?.lensDirection == CameraLensDirection.front;

    String? hint;
    IconData? hintIcon;
    if (_lowLight) {
      hint = lowLightHint;
      hintIcon = Icons.light_mode_outlined;
    } else if (_poseMissing) {
      hint = poseNotFoundHint;
      hintIcon = Icons.accessibility_new_rounded;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: upright.width,
                height: upright.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(controller),
                    if (_placement case final OverlayPlacement p)
                      GarmentOverlay(
                        imageUrl: widget.product.overlayImageUrl,
                        placement: mapPlacementToView(
                          placement: p,
                          imageWidth: _uprightSize?.width ?? upright.width,
                          imageHeight: _uprightSize?.height ?? upright.height,
                          viewWidth: upright.width,
                          viewHeight: upright.height,
                          mirror: mirror,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hint != null)
          Positioned(
            left: DesignTokens.s16,
            right: DesignTokens.s16,
            top: DesignTokens.s16,
            child: Center(
              child: TryOnHint(message: hint, icon: hintIcon),
            ),
          ),
        Positioned(
          bottom: DesignTokens.s16,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton(
              heroTag: 'try-on-capture',
              backgroundColor: DesignTokens.primaryGreen,
              tooltip: 'Capture and share',
              onPressed: _placement == null ? null : _capture,
              child: const Icon(Icons.camera_alt_rounded, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraProblem extends StatelessWidget {
  const _CameraProblem({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: DesignTokens.textMuted,
              size: DesignTokens.iconXLarge,
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
