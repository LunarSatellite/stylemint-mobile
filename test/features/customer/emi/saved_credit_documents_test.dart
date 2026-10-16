import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/saved_credit_documents.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';

/// The device store behind "Save these documents on this phone": private
/// copies only with consent, deleted on request or when consent is withdrawn.
void main() {
  late Directory root;
  late File picked;
  late FileSavedCreditDocumentStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('emi-docs-test');
    picked = File('${root.path}/picked-salary.pdf')..writeAsBytesSync([1, 2, 3]);
    store = FileSavedCreditDocumentStore(root: () async => root);
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  Future<SavedCreditDocument?> savePicked() => store.save(
    kind: CreditDocumentKind.financial,
    path: picked.path,
    name: 'salary.pdf',
    sizeBytes: 3,
  );

  test('consent is off by default, and nothing is saved without it', () async {
    expect(await store.hasConsent(), isFalse);
    expect(await savePicked(), isNull);
    expect(await store.list(), isEmpty);
    expect(Directory('${root.path}/emi-documents').listSync().whereType<File>()
        .where((f) => !f.path.endsWith('index.json')), isEmpty);
  });

  test('with consent a private copy is kept with its metadata', () async {
    await store.setConsent(true);
    final saved = await savePicked();
    expect(saved, isNotNull);
    expect(saved!.path, startsWith('${root.path}/emi-documents/'));
    expect(File(saved.path).readAsBytesSync(), [1, 2, 3]);

    // A fresh store over the same directory (the next app start) sees it.
    final again = await FileSavedCreditDocumentStore(root: () async => root).list();
    expect(again.single.name, 'salary.pdf');
    expect(again.single.kind, CreditDocumentKind.financial);
    expect(again.single.sizeBytes, 3);
  });

  test('delete removes one; withdrawing consent removes everything', () async {
    await store.setConsent(true);
    final first = (await savePicked())!;
    final second = (await savePicked())!;
    await store.delete(first.id);
    expect((await store.list()).map((d) => d.id), [second.id]);
    expect(File(first.path).existsSync(), isFalse);

    await store.setConsent(false);
    expect(await store.hasConsent(), isFalse);
    expect(await store.list(), isEmpty);
    expect(File(second.path).existsSync(), isFalse);
    expect(picked.existsSync(), isTrue, reason: 'the original is not touched');
  });
}
