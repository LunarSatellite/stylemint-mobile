import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/data/qr_login_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/data/qr_scan_info.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Scans a Style Mint web QR, then asks the signed-in user to approve or reject
/// the cross-device login. Backend: /v1/auth/qr/{token}/{scan|approve|reject}.
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

    final ds = ref.read(qrLoginDataSourceProvider);
    try {
      final info = await ds.scan(token);
      if (!mounted) return;
      final approved = await _confirm(info);
      if (approved == null) {
        await _resume();
        return;
      }
      if (approved) {
        await ds.approve(token);
        if (mounted) {
          SmSnackbar.success(context, 'Logged in on ${info.appLabel}.');
          context.pop();
        }
      } else {
        await ds.reject(token);
        if (mounted) context.pop();
      }
    } catch (_) {
      if (mounted) {
        SmSnackbar.error(context, "Couldn't complete the login. Try again.");
        await _resume();
      }
    }
  }

  Future<void> _resume() async {
    if (!mounted) return;
    setState(() => _handling = false);
    await _controller.start();
  }

  Future<bool?> _confirm(QrScanInfo info) => showModalBottomSheet<bool>(
        context: context,
        backgroundColor: DesignTokens.bgAppBody,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(DesignTokens.s24)),
        ),
        builder: (_) => _ConfirmSheet(info: info),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.textWhite),
        title: const Text('Scan to log in', style: DesignTokens.sectionInnerTitle),
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
              'Point your camera at the QR code on the Style Mint web login page.',
              textAlign: TextAlign.center,
              style: DesignTokens.mediumRegular
                  .copyWith(color: DesignTokens.textWhite),
            ),
          ),
          if (_handling)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                    color: DesignTokens.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.info});

  final QrScanInfo info;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.computer_rounded,
                color: DesignTokens.primaryGreen, size: 40),
            const SizedBox(height: DesignTokens.s16),
            Text('Log in to ${info.appLabel}?',
                style: DesignTokens.sectionInnerTitle),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'A web browser is requesting to sign in to your account.',
              style: DesignTokens.mediumRegular
                  .copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s16),
            if (info.creatorUserAgent != null)
              _row(Icons.public, info.creatorUserAgent!),
            if (info.creatorIp != null) _row(Icons.location_on_outlined, info.creatorIp!),
            const SizedBox(height: DesignTokens.s24),
            SmPrimaryButton(
              label: 'Approve',
              height: DesignTokens.buttonHeight,
              borderRadius: DesignTokens.buttonRadius,
              color: DesignTokens.primaryGreen,
              labelColor: DesignTokens.buttonPrimaryText,
              onPressed: () async => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
              ),
              child: Text('Reject',
                  style: DesignTokens.mediumSemibold
                      .copyWith(color: DesignTokens.colorError)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.s8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: DesignTokens.iconLight),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Text(text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textLight)),
            ),
          ],
        ),
      );
}
