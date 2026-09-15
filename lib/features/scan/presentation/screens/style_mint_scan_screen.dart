import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/code_links.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/presentation/qr_login_approval.dart';
import 'package:stylemint_mobile_frontend/features/scan/domain/style_mint_code.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The customer bar's Scan action: one camera for every StyleMint QR code
/// (see [StyleMintCode]). A link opens in place of the scanner; a web login
/// asks for approval; a drop party code joins the party. Codes that aren't
/// StyleMint's get a short note and open nothing — never another app or site.
class StyleMintScanScreen extends ConsumerStatefulWidget {
  const StyleMintScanScreen({super.key});

  static const String title = 'Scan';
  static const String hint = 'Point at a StyleMint QR code';
  static const String kinds =
      'Shelf and profile codes, products, reels, creators, drop parties and '
      'web login';
  static const String notStyleMint = "That isn't a StyleMint code";

  @override
  ConsumerState<StyleMintScanScreen> createState() =>
      _StyleMintScanScreenState();
}

class _StyleMintScanScreenState extends ConsumerState<StyleMintScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handling = false;
  bool _showNotStyleMint = false;
  Timer? _noteTimer;

  @override
  void initState() {
    super.initState();
    // v7: when a controller is supplied, the host must start it.
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    _noteTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);
    if (raw == null) return;

    final code = StyleMintCode.parse(raw);
    if (code == null) {
      _noteNotStyleMint();
      return;
    }

    setState(() {
      _handling = true;
      _showNotStyleMint = false;
    });
    await _controller.stop();
    if (!mounted) return;
    final left = await _open(code);
    if (!left) await _resume();
  }

  /// Acts on [code]; true once the scanner has been left.
  Future<bool> _open(StyleMintCode code) async {
    switch (code) {
      case StyleMintLinkCode(:final route):
        final router = GoRouter.of(context);
        final match = router.configuration.findMatch(Uri.parse(route));
        if (match.isEmpty || match.isError) {
          _noteNotStyleMint();
          return false;
        }
        unawaited(router.pushReplacement(route));
        return true;

      case StyleMintShortCode(:final code):
        // Scanned with StyleMint's own camera, so it counts as a QR scan
        // whatever the link says.
        unawaited(
          GoRouter.of(
            context,
          ).pushReplacement(StyleMintCodeLinks.route(code, CodeScanVia.qr)),
        );
        return true;

      case QrLoginCode(:final token):
        if (!await ensureAuth(context, ref, reason: AuthReason.general)) {
          return false;
        }
        if (!mounted) return true;
        final outcome = await approveQrLogin(context, ref, token);
        if (!mounted) return true;
        switch (outcome) {
          case QrLoginOutcome.approved:
          case QrLoginOutcome.rejected:
            context.popOrHome();
            return true;
          case QrLoginOutcome.dismissed:
          case QrLoginOutcome.failed:
            return false;
        }

      case DropPartyInviteCode(:final joinCode):
        if (!await ensureAuth(context, ref, reason: AuthReason.general)) {
          return false;
        }
        if (!mounted) return true;
        final joined = await ref
            .read(dropPartiesNotifierProvider.notifier)
            .scanQr(joinCode);
        if (!mounted) return true;
        return joined.fold(
          (_) {
            SmSnackbar.error(context, 'No drop party found for $joinCode.');
            return false;
          },
          (party) {
            context.pushReplacement(
              RouteNames.dropParty.replaceFirst(':dropPartyId', party.id),
            );
            return true;
          },
        );
    }
  }

  void _noteNotStyleMint() {
    _noteTimer?.cancel();
    if (!_showNotStyleMint) setState(() => _showNotStyleMint = true);
    _noteTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showNotStyleMint = false);
    });
  }

  Future<void> _resume() async {
    if (!mounted) return;
    setState(() => _handling = false);
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          StyleMintScanScreen.title,
          style: DesignTokens.sectionInnerTitle,
        ),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              if (state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }
              final on = state.torchState == TorchState.on;
              return IconButton(
                tooltip: on ? 'Turn off flashlight' : 'Turn on flashlight',
                icon: Icon(
                  on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: on
                      ? DesignTokens.primaryGreen
                      : DesignTokens.textWhite,
                ),
                onPressed: () => unawaited(_controller.toggleTorch()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(
              error: error,
              onRetry: () => unawaited(_controller.start()),
            ),
          ),
          const IgnorePointer(child: _Reticle()),
          Positioned(
            left: DesignTokens.s24,
            right: DesignTokens.s24,
            bottom: DesignTokens.s32,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showNotStyleMint
                        ? const _Note(text: StyleMintScanScreen.notStyleMint)
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  Text(
                    StyleMintScanScreen.hint,
                    textAlign: TextAlign.center,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    StyleMintScanScreen.kinds,
                    textAlign: TextAlign.center,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_handling)
            const ColoredBox(
              color: Colors.black54,
              child: SmPageLoader(),
            ),
        ],
      ),
    );
  }
}

/// Four mint corner brackets marking where to hold the code.
class _Reticle extends StatelessWidget {
  const _Reticle();

  static const double size = 248;

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _CornersPainter()),
    ),
  );
}

class _CornersPainter extends CustomPainter {
  const _CornersPainter();

  static const double _arm = 36;
  static const double _radius = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const corner = Radius.circular(_radius);
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, _arm)
      ..lineTo(0, _radius)
      ..arcToPoint(const Offset(_radius, 0), radius: corner)
      ..lineTo(_arm, 0)
      ..moveTo(w - _arm, 0)
      ..lineTo(w - _radius, 0)
      ..arcToPoint(Offset(w, _radius), radius: corner)
      ..lineTo(w, _arm)
      ..moveTo(w, h - _arm)
      ..lineTo(w, h - _radius)
      ..arcToPoint(Offset(w - _radius, h), radius: corner)
      ..lineTo(w - _arm, h)
      ..moveTo(_arm, h)
      ..lineTo(_radius, h)
      ..arcToPoint(Offset(0, h - _radius), radius: corner)
      ..lineTo(0, h - _arm);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s8,
      ),
      child: Text(
        text,
        style: DesignTokens.mediumSemibold.copyWith(
          color: DesignTokens.textWhite,
        ),
      ),
    ),
  );
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 48,
                color: DesignTokens.iconLight,
              ),
              const SizedBox(height: DesignTokens.s16),
              Text(
                denied ? 'Camera access is off' : "The camera couldn't start",
                textAlign: TextAlign.center,
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                denied
                    ? 'Turn on camera access for StyleMint in your phone '
                          'Settings, then try again.'
                    : 'Close other apps using the camera, then try again.',
                textAlign: TextAlign.center,
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s24),
              ElevatedButton(
                onPressed: onRetry,
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
