import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stylemint_mobile_frontend/features/codes/domain/style_mint_code_format.dart';

/// What goes on one printed shelf card.
class ShelfCardData {
  const ShelfCardData({
    required this.title,
    required this.url,
    required this.code,
    required this.storeName,
    this.storeCity,
    this.price,
  });

  /// The product's name, or the store's for a store card.
  final String title;

  /// The StyleMint link the QR opens.
  final String url;
  final String code;
  final String storeName;
  final String? storeCity;

  /// Already formatted, e.g. `Rs 1,200.00`.
  final String? price;
}

/// Printable StyleMint shelf cards: A6, one QR each.
abstract final class ShelfCardPdf {
  static const String tagline =
      'Scan or tap to watch reels and shop on StyleMint';

  /// Four A6 cards fit an A4 sheet, two across and two down.
  static const int cardsPerSheet = 4;

  static const PdfColor _mint = PdfColor.fromInt(0xFF1E9E55);

  /// One card on an A6 page.
  static Future<Uint8List> single(
    ShelfCardData card, {
    required Uint8List markPng,
  }) {
    final doc = pw.Document(
      title: 'StyleMint shelf card',
      creator: 'StyleMint',
    );
    final mark = pw.MemoryImage(markPng);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        margin: pw.EdgeInsets.zero,
        build: (_) => _card(card, mark),
      ),
    );
    return doc.save();
  }

  /// Every card, [cardsPerSheet] to an A4 sheet, with faint cut lines.
  static Future<Uint8List> sheets(
    List<ShelfCardData> cards, {
    required Uint8List markPng,
  }) {
    final doc = pw.Document(
      title: 'StyleMint shelf cards',
      creator: 'StyleMint',
    );
    final mark = pw.MemoryImage(markPng);
    for (var start = 0; start < cards.length; start += cardsPerSheet) {
      final sheet = cards.sublist(
        start,
        math.min(start + cardsPerSheet, cards.length),
      );
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Column(
            children: [
              for (var row = 0; row < 2; row++)
                pw.Row(
                  children: [
                    for (var column = 0; column < 2; column++)
                      _slot(sheet, row * 2 + column, mark),
                  ],
                ),
            ],
          ),
        ),
      );
    }
    return doc.save();
  }

  /// The built-in PDF font covers Latin-1 only. Common typographic marks are
  /// swapped for plain ones and anything else prints as `?`, rather than
  /// breaking the file.
  static String latin1Safe(String value) {
    const swaps = {
      '‘': "'",
      '’': "'",
      '“': '"',
      '”': '"',
      '–': '-',
      '—': '-',
      '…': '...',
      '₨': 'Rs',
    };
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(swaps[char] ?? (rune < 256 ? char : '?'));
    }
    return buffer.toString();
  }

  static pw.Widget _slot(
    List<ShelfCardData> sheet,
    int index,
    pw.ImageProvider mark,
  ) => pw.SizedBox(
    width: PdfPageFormat.a6.width,
    height: PdfPageFormat.a6.height,
    child: index < sheet.length
        ? _card(sheet[index], mark, cutLines: true)
        : pw.SizedBox(),
  );

  static pw.Widget _card(
    ShelfCardData card,
    pw.ImageProvider mark, {
    bool cutLines = false,
  }) {
    const mm = PdfPageFormat.mm;
    final price = card.price;
    final city = card.storeCity;
    final storeLine = city == null || city.isEmpty
        ? 'In ${card.storeName}'
        : 'In ${card.storeName}, $city';
    final host = Uri.tryParse(card.url);
    final shortLink = host == null ? card.url : '${host.host}${host.path}';

    return pw.Container(
      width: PdfPageFormat.a6.width,
      height: PdfPageFormat.a6.height,
      padding: const pw.EdgeInsets.all(8 * mm),
      decoration: cutLines
          ? pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            )
          : null,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.Image(mark, width: 8 * mm, height: 8 * mm),
              pw.SizedBox(width: 2 * mm),
              pw.Text(
                'StyleMint',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _mint,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4 * mm),
          pw.Text(
            latin1Safe(card.title),
            maxLines: 2,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          if (price != null) ...[
            pw.SizedBox(height: 1.5 * mm),
            pw.Text(
              latin1Safe(price),
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
            ),
          ],
          pw.SizedBox(height: 1.5 * mm),
          pw.Text(
            latin1Safe(storeLine),
            maxLines: 1,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.Spacer(),
          pw.Center(child: _qr(card.url, mark, 58 * mm)),
          pw.SizedBox(height: 3 * mm),
          pw.Text(
            tagline,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 1.5 * mm),
          pw.Text(
            latin1Safe(
              'Code ${StyleMintCodeFormat.display(card.code)}  |  $shortLink',
            ),
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// A high error correction QR with the StyleMint mark on a white square
  /// in the middle, 22% of the code's width.
  static pw.Widget _qr(String url, pw.ImageProvider mark, double size) {
    final markBox = size * 0.22;
    return pw.SizedBox(
      width: size,
      height: size,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(
              errorCorrectLevel: pw.BarcodeQRCorrectionLevel.high,
            ),
            data: url,
            width: size,
            height: size,
            drawText: false,
          ),
          pw.Container(
            width: markBox,
            height: markBox,
            padding: pw.EdgeInsets.all(markBox * 0.08),
            color: PdfColors.white,
            child: pw.Image(mark),
          ),
        ],
      ),
    );
  }
}
