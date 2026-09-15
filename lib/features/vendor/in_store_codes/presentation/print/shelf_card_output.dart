import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum _ShelfCardOutput { printCards, sharePdf }

/// Asks whether to print or share, builds the PDF with the StyleMint mark,
/// then opens the system print dialog or share sheet.
Future<void> showShelfCardOutputSheet(
  BuildContext context, {
  required String documentName,
  required String fileName,
  required PdfPageFormat format,
  required Future<Uint8List> Function(Uint8List markPng) build,
}) async {
  final choice = await showModalBottomSheet<_ShelfCardOutput>(
    context: context,
    backgroundColor: DesignTokens.bgAppBodyLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignTokens.s16),
          ListTile(
            leading: const Icon(
              Icons.print_outlined,
              color: DesignTokens.iconWhite,
            ),
            title: const Text('Print', style: DesignTokens.mediumSemibold),
            subtitle: const Text(
              'Opens your phone’s print options',
              style: DesignTokens.smallRegular,
            ),
            onTap: () =>
                Navigator.pop(sheetContext, _ShelfCardOutput.printCards),
          ),
          ListTile(
            leading: const Icon(
              Icons.picture_as_pdf_outlined,
              color: DesignTokens.iconWhite,
            ),
            title: const Text('Share PDF', style: DesignTokens.mediumSemibold),
            subtitle: const Text(
              'Send it to a print shop or save it',
              style: DesignTokens.smallRegular,
            ),
            onTap: () => Navigator.pop(sheetContext, _ShelfCardOutput.sharePdf),
          ),
          const SizedBox(height: DesignTokens.s16),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;

  try {
    final mark = await rootBundle.load(smBrandMarkAsset);
    final bytes = await build(mark.buffer.asUint8List());
    switch (choice) {
      case _ShelfCardOutput.printCards:
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: documentName,
          format: format,
        );
      case _ShelfCardOutput.sharePdf:
        await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  } on Object catch (_) {
    if (context.mounted) {
      SmSnackbar.error(
        context,
        "Couldn't make the shelf card. Please try again.",
      );
    }
  }
}
