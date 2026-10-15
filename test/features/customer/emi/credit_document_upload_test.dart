import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/checkout_emi_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/datasources/credit_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';

void main() {
  group('the document type comes from the bytes, not the picked name', () {
    // The owner's "could not upload": a photo whose name had no usable
    // extension went up as application/octet-stream and was refused.
    test('a JPEG named without an extension is sent as image/jpeg', () async {
      final dir = await Directory.systemTemp.createTemp('credit-doc');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/1000000033')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0]);
      expect(await creditDocumentMediaType(file), ('image/jpeg', 'jpg'));
    });

    test('PDF, PNG and HEIC are recognised; anything else is not', () {
      expect(sniffCreditDocument('%PDF-1.7'.codeUnits), (
        'application/pdf',
        'pdf',
      ));
      expect(sniffCreditDocument(const [0x89, 0x50, 0x4E, 0x47, 13, 10]), (
        'image/png',
        'png',
      ));
      expect(
        sniffCreditDocument([0, 0, 0, 24, ...'ftypheic'.codeUnits]),
        ('image/heic', 'heic'),
      );
      expect(sniffCreditDocument('hello'.codeUnits), isNull);
    });
  });

  test('a refused upload shows the server reason, not a generic line', () {
    expect(
      creditFailureMessage(
        const EmiFailure(
          EmiFailureKind.rejected,
          code: 'credit_document.invalid',
          message: 'The file must be a PDF, JPEG, PNG or HEIC.',
        ),
      ),
      'The file must be a PDF, JPEG, PNG or HEIC.',
    );
  });

  testWidgets('the picker offers camera, photo library and a file', (
    tester,
  ) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              captured = ref;
              return Scaffold(
                body: TextButton(
                  onPressed: () =>
                      captured.read(creditDocumentPickerProvider)(context),
                  child: const Text('pick'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from photos'), findsOneWidget);
    expect(find.text('Choose a file (PDF)'), findsOneWidget);
  });
}
