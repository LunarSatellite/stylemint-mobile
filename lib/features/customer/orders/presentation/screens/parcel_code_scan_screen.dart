import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Focused parcel-label scanner used by verified receive. It returns the raw
/// QR/barcode value to the order screen; the backend remains the authority
/// that decides whether it matches the package tracking number.
class ParcelCodeScanScreen extends StatefulWidget {
  const ParcelCodeScanScreen({required this.expectedTrackingNumber, super.key});

  final String expectedTrackingNumber;

  @override
  State<ParcelCodeScanScreen> createState() => _ParcelCodeScanScreenState();
}

class _ParcelCodeScanScreenState extends State<ParcelCodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (raw == null) return;
    _handled = true;
    unawaited(_controller.stop());
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('Scan parcel label'),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Center(
          child: Container(
            width: 270,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: DesignTokens.primaryGreen, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 32,
          child: SafeArea(
            top: false,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Scan the QR or barcode on parcel ${widget.expectedTrackingNumber}.',
                  textAlign: TextAlign.center,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
