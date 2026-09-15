import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/entities/code_stats.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/repositories/vendor_codes_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/widgets/vendor_code_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/shared/providers.dart';

class _MockVendorCodesRepository extends Mock
    implements VendorCodesRepository {}

const _url = 'https://stylemint.voyageritnepal.com/c/ABCD2345';

const _active = StyleMintCodeInfo(
  code: 'ABCD2345',
  kind: CodeKind.productTag,
  status: CodeStatus.active,
  url: _url,
  productId: 'p-1',
  storeId: 's-1',
);

const _revoked = StyleMintCodeInfo(
  code: 'ABCD2345',
  kind: CodeKind.productTag,
  status: CodeStatus.revoked,
  url: _url,
  productId: 'p-1',
  storeId: 's-1',
);

const _stats = CodeStats(
  code: 'ABCD2345',
  totalScans: 12,
  scansLast7Days: 5,
  scansLast30Days: 9,
  uniqueScanners: 7,
);

void main() {
  late _MockVendorCodesRepository repository;

  setUp(() {
    repository = _MockVendorCodesRepository();
    when(
      () => repository.getStats(any()),
    ).thenAnswer((_) async => right(_stats));
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    VendorCodeTarget target = (productId: 'p-1', storeId: 's-1'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorCodesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: VendorCodeSheet(
              target: target,
              subject: const VendorCodeSubject(
                title: 'Linen shirt',
                storeName: 'Mint Thamel',
                storeCity: 'Kathmandu',
                price: 'Rs 2,499.00',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void stubProductTag(Either<NetworkExceptions, StyleMintCodeInfo> result) {
    when(
      () => repository.createProductTag(
        productId: any(named: 'productId'),
        storeId: any(named: 'storeId'),
      ),
    ).thenAnswer((_) async => result);
  }

  testWidgets('shows the branded QR, code, link, scans and actions', (
    tester,
  ) async {
    stubProductTag(right(_active));

    await pumpSheet(tester);

    expect(find.byKey(const ValueKey('vendor-code-qr')), findsOneWidget);
    expect(find.text('ABCD 2345'), findsOneWidget);
    expect(find.text(_url), findsOneWidget);
    expect(find.text('In Mint Thamel'), findsOneWidget);
    expect(find.text('12 scans', findRichText: true), findsOneWidget);
    expect(find.text('7 people', findRichText: true), findsOneWidget);
    for (final label in [
      'Share link',
      'Print or share shelf card',
      'Write to NFC tag',
      VendorCodeSheet.revokeLabel,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    verify(
      () => repository.createProductTag(productId: 'p-1', storeId: 's-1'),
    ).called(1);
    verify(() => repository.getStats('ABCD2345')).called(1);
  });

  testWidgets('revoking asks first; cancelling keeps the code', (
    tester,
  ) async {
    stubProductTag(right(_active));
    await pumpSheet(tester);

    await tester.tap(find.text(VendorCodeSheet.revokeLabel));
    await tester.pumpAndSettle();

    expect(find.text(VendorCodeSheet.revokeTitle), findsOneWidget);
    expect(find.text(VendorCodeSheet.revokeBody), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.revoke(any()));
    expect(find.byKey(const ValueKey('vendor-code-qr')), findsOneWidget);
  });

  testWidgets('confirming revokes, then a new code can be made', (
    tester,
  ) async {
    stubProductTag(right(_active));
    when(
      () => repository.revoke('ABCD2345'),
    ).thenAnswer((_) async => right(_revoked));
    await pumpSheet(tester);

    await tester.tap(find.text(VendorCodeSheet.revokeLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-revoke-code')));
    await tester.pumpAndSettle();

    verify(() => repository.revoke('ABCD2345')).called(1);
    expect(find.text(VendorCodeSheet.revokedTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('vendor-code-qr')), findsNothing);
    expect(find.text('Write to NFC tag'), findsNothing);

    await tester.tap(find.text('Make a new code'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('vendor-code-qr')), findsOneWidget);
    verify(
      () => repository.createProductTag(productId: 'p-1', storeId: 's-1'),
    ).called(2);
  });

  testWidgets('a failed revoke keeps the active code', (tester) async {
    stubProductTag(right(_active));
    when(
      () => repository.revoke(any()),
    ).thenAnswer(
      (_) async => left(const NetworkExceptions.serverUnavailable()),
    );
    await pumpSheet(tester);

    await tester.tap(find.text(VendorCodeSheet.revokeLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-revoke-code')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('vendor-code-qr')), findsOneWidget);
    expect(find.text(VendorCodeSheet.revokedTitle), findsNothing);
  });

  testWidgets('a store target gets the store code', (tester) async {
    when(() => repository.createStoreCode('s-1')).thenAnswer(
      (_) async => right(
        const StyleMintCodeInfo(
          code: '7K9M2PQR',
          kind: CodeKind.store,
          status: CodeStatus.active,
          url: 'https://stylemint.voyageritnepal.com/c/7K9M2PQR',
          storeId: 's-1',
        ),
      ),
    );

    await pumpSheet(tester, target: (productId: null, storeId: 's-1'));

    expect(find.text('Store code'), findsOneWidget);
    expect(find.text('7K9M 2PQR'), findsOneWidget);
    verifyNever(
      () => repository.createProductTag(
        productId: any(named: 'productId'),
        storeId: any(named: 'storeId'),
      ),
    );
  });

  testWidgets('a load failure offers a retry', (tester) async {
    stubProductTag(left(const NetworkExceptions.noInternetConnection()));

    await pumpSheet(tester);

    expect(find.text('No internet connection.'), findsOneWidget);
    expect(find.byKey(const ValueKey('vendor-code-qr')), findsNothing);

    stubProductTag(right(_active));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('vendor-code-qr')), findsOneWidget);
  });
}
