import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/barcode_lookup_outcome.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/widgets/barcode_not_in_catalogue.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/widgets/search_input_recovery.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The product formats a shelf or a swing tag actually carries. QR codes are
/// deliberately absent: StyleMint's own QR codes belong to the Scan tab, and
/// a scanner that answered both would send buyers to two different places
/// for the same gesture.
const List<BarcodeFormat> kProductBarcodeFormats = [
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.code128,
  BarcodeFormat.code39,
  BarcodeFormat.itf14,
];

enum _ScanPhase { scanning, looking, notFound, failed, blocked }

/// Scan a product barcode and land on that product.
///
/// A code that matches nothing is the likeliest real outcome — the Mall
/// stocks a catalogue, not every GTIN in the world — so it gets a named
/// state with three ways on: scan another, search the Mall for the digits, or
/// go back and type. It is never a blank camera that quietly keeps scanning.
class BarcodeScanScreen extends ConsumerStatefulWidget {
  const BarcodeScanScreen({super.key});

  static const String title = 'Scan a barcode';
  static const String hint = 'Point at the barcode on the tag or the shelf';

  @override
  ConsumerState<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends ConsumerState<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: kProductBarcodeFormats,
    autoStart: false,
  );

  _ScanPhase _phase = _ScanPhase.scanning;
  SearchInputStatus _blocked = SearchInputStatus.unsupported;
  String _lastCode = '';
  String? _detail;

  @override
  void initState() {
    super.initState();
    // v7 refuses to start before a MobileScanner widget is in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await _controller.start();
      if (!mounted) return;
      ref
          .read(searchInputCapabilitiesProvider.notifier)
          .reportBarcode(SearchInputStatus.ready);
      setState(() => _phase = _ScanPhase.scanning);
    } on MobileScannerException catch (error) {
      _blockOn(error);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _ScanPhase.failed;
        _detail = error.toString();
      });
    }
  }

  void _blockOn(MobileScannerException error) {
    if (!mounted) return;
    final status = switch (error.errorCode) {
      // The plugin cannot tell a first refusal from a permanent one, and
      // guessing wrong strands the buyer. Offering settings always works:
      // the page it opens is also where a first-time "Allow" lives.
      MobileScannerErrorCode.permissionDenied =>
        SearchInputStatus.deniedForever,
      MobileScannerErrorCode.unsupported => SearchInputStatus.unsupported,
      _ => SearchInputStatus.unsupported,
    };
    ref.read(searchInputCapabilitiesProvider.notifier).reportBarcode(status);
    setState(() {
      _phase = _ScanPhase.blocked;
      _blocked = status;
      _detail = error.errorDetails?.message ?? error.errorCode.name;
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_phase != _ScanPhase.scanning) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (raw == null) return;

    setState(() {
      _phase = _ScanPhase.looking;
      _lastCode = raw;
    });
    await _controller.stop();
    final outcome = await ref.read(barcodeProductLookupProvider).find(raw);
    if (!mounted) return;

    switch (outcome) {
      case BarcodeMatched(:final productId):
        // Replace the scanner so Back from the product returns to search,
        // not to a camera pointed at the same code.
        context.pushReplacement(
          RouteNames.productDetail.replaceFirst(':productId', productId),
        );
      case BarcodeAmbiguous(:final code, :final results):
        context.pushReplacement(
          '${RouteNames.searchResults}?q=$code',
          extra: results,
        );
      case BarcodeUnmatched(:final code):
        setState(() {
          _phase = _ScanPhase.notFound;
          _lastCode = code;
        });
      case BarcodeLookupFailed(:final code, :final detail):
        setState(() {
          _phase = _ScanPhase.failed;
          _lastCode = code;
          _detail = detail;
        });
    }
  }

  Future<void> _scanAgain() async {
    setState(() {
      _phase = _ScanPhase.scanning;
      _detail = null;
    });
    await _start();
  }

  Future<void> _openSettings() async {
    final opened = await ref.read(appSettingsLauncherProvider)();
    if (opened || !mounted) return;
    SmSnackbar.error(
      context,
      'We could not open your device settings. Find StyleMint under '
      'Settings, then Apps, then Permissions.',
    );
  }

  /// Hands the digits back to Discover as an ordinary search, so an unmatched
  /// code still ends somewhere useful.
  void _searchTheCode() => Navigator.of(context).pop(_lastCode);

  void _leave() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DesignTokens.bgAppFoundation,
    appBar: AppBar(
      backgroundColor: DesignTokens.bgAppFoundation,
      foregroundColor: DesignTokens.textWhite,
      title: const Text(BarcodeScanScreen.title),
    ),
    body: SafeArea(
      child: switch (_phase) {
        _ScanPhase.blocked => SearchInputRecovery(
          kind: SearchInputKind.barcode,
          status: _blocked,
          detail: _detail,
          onAskAgain: () => unawaited(_scanAgain()),
          onOpenSettings: () => unawaited(_openSettings()),
          onTypeInstead: _leave,
        ),
        _ScanPhase.notFound => BarcodeNotInCatalogue(
          code: _lastCode,
          onScanAgain: () => unawaited(_scanAgain()),
          onSearchCode: _searchTheCode,
          onTypeInstead: _leave,
        ),
        _ScanPhase.failed => MallErrorState(
          key: const ValueKey('barcode-lookup-failed'),
          title: 'We could not check that code',
          body:
              'StyleMint could not reach the catalogue. Check your connection '
              'and scan it again.',
          detail: _detail,
          retryLabel: 'Scan again',
          onRetry: () => unawaited(_scanAgain()),
        ),
        _ => _buildCamera(),
      },
    ),
  );

  Widget _buildCamera() => Stack(
    fit: StackFit.expand,
    children: [
      MobileScanner(
        key: const ValueKey('barcode-scanner'),
        controller: _controller,
        onDetect: (capture) => unawaited(_onDetect(capture)),
        errorBuilder: (context, error) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _blockOn(error),
          );
          return const ColoredBox(color: DesignTokens.bgAppFoundation);
        },
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Container(
              width: 240,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: DesignTokens.primaryGreen, width: 2),
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
            ),
          ),
        ),
      ),
      PositionedDirectional(
        start: DesignTokens.s16,
        end: DesignTokens.s16,
        bottom: DesignTokens.s24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MallStatusPill(
              key: const ValueKey('barcode-scan-status'),
              label: _phase == _ScanPhase.looking
                  ? 'Looking it up'
                  : 'Ready to scan',
              tone: _phase == _ScanPhase.looking
                  ? MallStatusTone.progress
                  : MallStatusTone.info,
              icon: _phase == _ScanPhase.looking
                  ? Icons.search_rounded
                  : Icons.qr_code_scanner_rounded,
              semanticLabel: _phase == _ScanPhase.looking
                  ? 'Looking up the code you scanned'
                  : BarcodeScanScreen.hint,
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              BarcodeScanScreen.hint,
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
