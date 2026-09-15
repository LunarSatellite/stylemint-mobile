import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/data/qr_login_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/presentation/qr_login_approval.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Scans a Style Mint web QR, then asks the signed-in user to approve or reject
/// the cross-device login (see [approveQrLogin]).
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    // v7: when a controller is supplied, the host must start it.
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;

    final token = QrLoginRemoteDataSource.parseToken(raw);
    if (token == null) return; // not a Style Mint QR — keep scanning.

    setState(() => _handling = true);
    await _controller.stop();
    if (!mounted) return;

    final outcome = await approveQrLogin(context, ref, token);
    if (!mounted) return;
    switch (outcome) {
      case QrLoginOutcome.approved:
      case QrLoginOutcome.rejected:
        context.popOrHome();
      case QrLoginOutcome.dismissed:
      case QrLoginOutcome.failed:
        await _resume();
    }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.textWhite),
        title: const Text(
          'Scan to log in',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Simple reticle + hint.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: DesignTokens.primaryGreen, width: 3),
                borderRadius: BorderRadius.circular(DesignTokens.s24),
              ),
            ),
          ),
          Positioned(
            left: DesignTokens.s24,
            right: DesignTokens.s24,
            bottom: DesignTokens.s32,
            child: Text(
              'Point your camera at the QR code on the Style Mint web login '
              'page.',
              textAlign: TextAlign.center,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textWhite,
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
