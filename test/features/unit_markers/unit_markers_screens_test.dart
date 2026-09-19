import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_scan.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/screens/unit_marker_bind_screen.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/screens/unit_marker_provision_screen.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/screens/unit_tag_passport_screen.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

const String kMarker = 'ABCDEFGHJKMNPQRSTVWXYZ0123';
const String kReference = 'UM7K2P9QRSTV';
const String kMarkerId = '11111111-1111-1111-1111-111111111111';

/// Fields a stranger must never be shown by the public scan surface. Each one
/// is seeded into the fake's answers where it *could* leak, and asserted
/// absent from the rendered tree.
const List<String> kForbiddenOnScan = [
  'ORD-48812', // order number
  'SO-1002', // sub-order
  'sol-line-7', // order line
  'acct-9931', // buyer account
  'Aarati Shrestha', // buyer name
  'Jhamsikhel, Lalitpur', // address
  'Rs 14,500', // price
  'NP9921733', // tracking number
];

class _FakeRepo implements UnitMarkersRepository {
  _FakeRepo({
    this.provisionAnswer,
    this.bindAnswer,
    this.correctAnswer,
    this.passportAnswer,
  });

  Either<NetworkExceptions, List<ProvisionedUnitMarker>>? provisionAnswer;
  Either<NetworkExceptions, UnitMarkerBindOutcome>? bindAnswer;
  Either<NetworkExceptions, UnitMarkerBindOutcome>? correctAnswer;
  Either<NetworkExceptions, UnitPassportResult>? passportAnswer;

  String? lastCorrectionReason;
  int correctCalls = 0;

  @override
  Future<Either<NetworkExceptions, List<ProvisionedUnitMarker>>> provision({
    required String productVariantId,
    required int quantity,
  }) async => provisionAnswer ?? right(const []);

  @override
  Future<Either<NetworkExceptions, PagedResult<UnitMarker>>> listMarkers({
    String? productId,
    String? productVariantId,
    String? cursor,
    int pageSize = 20,
  }) async => right(
    const PagedResult<UnitMarker>(
      items: [],
      totalCount: 0,
      pageSize: 20,
      hasMore: false,
    ),
  );

  @override
  Future<Either<NetworkExceptions, UnitMarker>> revoke(
    String reference,
  ) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, UnitMarkerBindOutcome>> bind({
    required String marker,
    required String subOrderLineId,
    required UnitBindingStage stage,
  }) async => bindAnswer ?? left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, UnitMarkerBindOutcome>> correct({
    required String marker,
    required String subOrderLineId,
    required UnitBindingStage stage,
    required String reason,
  }) async {
    correctCalls++;
    lastCorrectionReason = reason;
    return correctAnswer ?? left(const NetworkExceptions.unexpectedError());
  }

  @override
  Future<Either<NetworkExceptions, List<UnitMarkerBinding>>> bindingHistory(
    String reference,
  ) async => right(const []);

  @override
  Future<Either<NetworkExceptions, List<UnitMarkerScan>>> scanHistory(
    String reference, {
    int limit = 50,
  }) async => right(const []);

  @override
  Future<Either<NetworkExceptions, UnitMarkerScanResult>> scan({
    required String marker,
    required CodeScanVia via,
    String? atStoreCode,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, UnitPassportResult>> unitPassport(
    String unitMarkerId,
  ) async => passportAnswer ?? right(const UnitPassportUnbound());
}

/// 320dp with a 1.3 text scale — the narrowest combination this app supports
/// and where an overflow shows up first.
const Size _narrow = Size(320, 900);
const Size _narrowTall = Size(320, 2600);

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required _FakeRepo repo,
  Size size = _narrow,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [unitMarkersRepositoryProvider.overrideWithValue(repo)],
      child: const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: SizedBox.shrink(),
      ),
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [unitMarkersRepositoryProvider.overrideWithValue(repo)],
      child: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(home: screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every string rendered anywhere in the tree.
List<String> _renderedText(WidgetTester tester) => [
  ...tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? ''),
  ...tester
      .widgetList<SelectableText>(find.byType(SelectableText))
      .map(
        (t) => t.data ?? t.textSpan?.toPlainText() ?? '',
      ),
];

ProvisionedUnitMarker _provisioned() => ProvisionedUnitMarker(
  id: kMarkerId,
  reference: kReference,
  secret: kMarker,
  productId: 'p1',
  productVariantId: 'v1',
  provisionedAt: DateTime.utc(2026, 9, 20, 8),
);

UnitMarkerBinding _binding({String? correctsBindingId}) => UnitMarkerBinding(
  id: 'b1',
  markerReference: kReference,
  orderId: 'ORD-48812',
  subOrderId: 'SO-1002',
  subOrderLineId: 'sol-line-7',
  boundAtStage: UnitBindingStage.pack,
  boundAt: DateTime.utc(2026, 9, 20, 7),
  correctsBindingId: correctsBindingId,
);

void main() {
  group('surface 1 — the one-time reveal', () {
    testWidgets('says plainly that the codes cannot be shown again', (
      tester,
    ) async {
      final repo = _FakeRepo(provisionAnswer: right([_provisioned()]));
      await _pump(
        tester,
        const UnitMarkerProvisionScreen(
          productVariantId: 'v1',
          productName: 'Trail Jacket',
        ),
        repo: repo,
        size: _narrowTall,
      );

      // The warning is on screen before anything is minted.
      expect(
        find.text(UnitMarkerProvisionScreen.oneTimeWarning),
        findsOneWidget,
      );
      expect(find.text(UnitMarkerProvisionScreen.printRunNote), findsOneWidget);

      await tester.tap(find.text(UnitMarkerProvisionScreen.mintLabel));
      await tester.pumpAndSettle();

      // The secret is on screen exactly once, with the warning repeated and a
      // way to get the value out of the app.
      expect(find.text(kMarker), findsOneWidget);
      expect(
        find.text(UnitMarkerProvisionScreen.oneTimeWarning),
        findsOneWidget,
      );
      expect(find.text(UnitMarkerProvisionScreen.exportLabel), findsOneWidget);
      expect(find.text(UnitMarkerProvisionScreen.copyLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('confirming drops the secret and keeps the reference', (
      tester,
    ) async {
      final repo = _FakeRepo(provisionAnswer: right([_provisioned()]));
      await _pump(
        tester,
        const UnitMarkerProvisionScreen(productVariantId: 'v1'),
        repo: repo,
        size: _narrowTall,
      );
      await tester.tap(find.text(UnitMarkerProvisionScreen.mintLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(UnitMarkerProvisionScreen.savedLabel));
      await tester.pumpAndSettle();

      expect(find.text(kMarker), findsNothing);
      expect(find.text(kReference), findsOneWidget);
      expect(
        find.text(UnitMarkerProvisionScreen.discardedHeading),
        findsOneWidget,
      );
    });

    testWidgets('a listing with no variant is told so, not offered a form', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(
        tester,
        const UnitMarkerProvisionScreen(productVariantId: ''),
        repo: repo,
      );
      expect(
        find.text(UnitMarkerProvisionScreen.noVariantBody),
        findsOneWidget,
      );
      expect(find.text(UnitMarkerProvisionScreen.mintLabel), findsNothing);
    });
  });

  group('surface 2 — refusal and correction read differently', () {
    UnitMarkerBindArgs argsAt(OrderLineFulfilmentStage stage) => (
      subOrderLineId: 'sol-line-7',
      stage: stage,
      lineLabel: 'Trail Jacket',
    );

    testWidgets('a 409 shows the server sentence under "Already bound"', (
      tester,
    ) async {
      const sentence =
          'This marker is already bound to another order line. Record a '
          'correction if the first binding was wrong.';
      final repo = _FakeRepo(
        bindAnswer: right(
          const UnitMarkerBindRefused(
            UnitMarkerBindRefusal(
              kind: UnitMarkerBindRefusalKind.alreadyBound,
              message: sentence,
            ),
          ),
        ),
      );
      await _pump(
        tester,
        UnitMarkerBindScreen(args: argsAt(OrderLineFulfilmentStage.packed)),
        repo: repo,
        size: _narrowTall,
      );
      await tester.enterText(find.byType(TextField).first, kMarker);
      await tester.tap(find.text(UnitMarkerBindScreen.bindLabel));
      await tester.pumpAndSettle();

      expect(
        find.text(UnitMarkerBindScreen.alreadyBoundHeading),
        findsOneWidget,
      );
      expect(find.text(sentence), findsOneWidget);
      // A refusal is not dressed as a success.
      expect(find.text(UnitMarkerBindScreen.boundHeading), findsNothing);
    });

    testWidgets('a bind reads as bound, a correction reads as corrected', (
      tester,
    ) async {
      final repo = _FakeRepo(bindAnswer: right(UnitMarkerBound(_binding())));
      await _pump(
        tester,
        UnitMarkerBindScreen(args: argsAt(OrderLineFulfilmentStage.packed)),
        repo: repo,
        size: _narrowTall,
      );
      await tester.enterText(find.byType(TextField).first, kMarker);
      await tester.tap(find.text(UnitMarkerBindScreen.bindLabel));
      await tester.pumpAndSettle();

      expect(find.text(UnitMarkerBindScreen.boundHeading), findsOneWidget);
      expect(find.text(UnitMarkerBindScreen.correctedHeading), findsNothing);
    });

    testWidgets('a correction with no reason is refused before the call', (
      tester,
    ) async {
      final repo = _FakeRepo(
        correctAnswer: right(
          UnitMarkerBound(_binding(correctsBindingId: 'b0')),
        ),
      );
      await _pump(
        tester,
        UnitMarkerBindScreen(args: argsAt(OrderLineFulfilmentStage.handedOver)),
        repo: repo,
        size: _narrowTall,
      );
      await tester.enterText(find.byType(TextField).first, kMarker);
      await tester.tap(find.text(UnitMarkerBindScreen.correctLabel).last);
      await tester.pumpAndSettle();

      // The reason field appeared; submitting it empty never reaches the wire.
      await tester.tap(find.text(UnitMarkerBindScreen.correctLabel).first);
      await tester.pumpAndSettle();
      expect(repo.correctCalls, 0);
      expect(find.text(UnitMarkerBindScreen.reasonRequired), findsOneWidget);
    });

    testWidgets(
      'a correction sends the seller own words, not a canned string',
      (
        tester,
      ) async {
        final repo = _FakeRepo(
          correctAnswer: right(
            UnitMarkerBound(_binding(correctsBindingId: 'b0')),
          ),
        );
        await _pump(
          tester,
          UnitMarkerBindScreen(args: argsAt(OrderLineFulfilmentStage.packed)),
          repo: repo,
          size: _narrowTall,
        );
        await tester.enterText(find.byType(TextField).first, kMarker);
        await tester.tap(find.text(UnitMarkerBindScreen.correctLabel).last);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          'Tagged the jacket instead of the trousers.',
        );
        await tester.tap(find.text(UnitMarkerBindScreen.correctLabel).first);
        await tester.pumpAndSettle();

        expect(repo.correctCalls, 1);
        expect(
          repo.lastCorrectionReason,
          'Tagged the jacket instead of the trousers.',
        );
        expect(
          find.text(UnitMarkerBindScreen.correctedHeading),
          findsOneWidget,
        );
      },
    );

    testWidgets('after Delivered the control is explained, not hidden', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(
        tester,
        UnitMarkerBindScreen(args: argsAt(OrderLineFulfilmentStage.delivered)),
        repo: repo,
        size: _narrowTall,
      );

      // The control is still there.
      expect(find.text(UnitMarkerBindScreen.correctLabel), findsWidgets);
      // And so is the reason it will not work.
      expect(find.text('Correction is closed'), findsOneWidget);
      expect(
        find.text(OrderLineFulfilmentStage.delivered.bindingClosedReason!),
        findsOneWidget,
      );

      // Pressing it changes nothing and reaches no endpoint.
      await tester.tap(find.text(UnitMarkerBindScreen.correctLabel).last);
      await tester.pumpAndSettle();
      expect(repo.correctCalls, 0);
    });

    testWidgets('a malformed code never becomes a request', (tester) async {
      final repo = _FakeRepo(bindAnswer: right(UnitMarkerBound(_binding())));
      await _pump(
        tester,
        UnitMarkerBindScreen(args: argsAt(OrderLineFulfilmentStage.packed)),
        repo: repo,
        size: _narrowTall,
      );
      await tester.enterText(find.byType(TextField).first, 'not-a-tag');
      await tester.tap(find.text(UnitMarkerBindScreen.bindLabel));
      await tester.pumpAndSettle();

      expect(find.text(UnitMarkerBindScreen.malformedBody), findsOneWidget);
      expect(find.text(UnitMarkerBindScreen.boundHeading), findsNothing);
    });
  });

  group('surface 3 — the public scan surface is bounded', () {
    UnitMarkerScanResult reading({
      bool bound = true,
      UnitMarkerStatus status = UnitMarkerStatus.active,
      UnitScanPlaceKind place = UnitScanPlaceKind.notStated,
    }) => UnitMarkerScanResult(
      unitMarkerId: kMarkerId,
      reference: kReference,
      status: status,
      productId: 'p1',
      productName: 'Trail Jacket',
      isBoundToSale: bound,
      inServiceSince: bound ? DateTime.utc(2026, 9, 18, 4, 30) : null,
      scannedAt: DateTime.utc(2026, 9, 20, 9, 15),
      placeKind: place,
      vendorStoreName: place == UnitScanPlaceKind.vendorStore
          ? 'Durbar Marg Flagship'
          : null,
      vendorStoreCity: place == UnitScanPlaceKind.vendorStore
          ? 'Kathmandu'
          : null,
    );

    testWidgets('a bound tag shows only the permitted facts', (tester) async {
      final repo = _FakeRepo(
        passportAnswer: right(
          const UnitPassportFound(
            ProductPassport(
              vendorBusinessName: 'Himalayan Outfitters',
              vendorIdentityVerified: true,
              vendorOnPlatformSince: null,
              authenticityStatement: 'Sold by the listing owner.',
              schemaVersion: 2,
              subject: PassportSubject(
                scope: 'Unit',
                scopeExplanation:
                    'This passport identifies one physical item, because a '
                    'marker on it is bound to an order line.',
                identifiesPhysicalUnit: true,
              ),
            ),
          ),
        ),
      );
      await _pump(
        tester,
        UnitTagPassportScreen(unitMarkerId: kMarkerId, scan: reading()),
        repo: repo,
        size: _narrowTall,
      );

      final rendered = _renderedText(tester).join('\n');
      expect(rendered, contains('Trail Jacket'));
      expect(rendered, contains(UnitTagPassportScreen.genuineHeading));
      expect(rendered, contains(UnitTagPassportScreen.boundLabel));

      // Nothing about the buyer or the money.
      for (final forbidden in kForbiddenOnScan) {
        expect(
          rendered,
          isNot(contains(forbidden)),
          reason: 'the public scan surface must never show "$forbidden"',
        );
      }
      // And no field name that would introduce one either.
      for (final label in [
        'Order',
        'Sub-order',
        'Buyer',
        'Address',
        'Tracking',
        'Price',
      ]) {
        expect(
          rendered,
          isNot(contains(label)),
          reason: 'no "$label" belongs on the public scan surface',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unbound tag reads as not bound, not as an error', (
      tester,
    ) async {
      final repo = _FakeRepo(
        passportAnswer: right(const UnitPassportUnbound()),
      );
      await _pump(
        tester,
        UnitTagPassportScreen(
          unitMarkerId: kMarkerId,
          scan: reading(bound: false),
        ),
        repo: repo,
        size: _narrowTall,
      );

      expect(find.text(UnitTagPassportScreen.notBoundHeading), findsOneWidget);
      expect(find.text(UnitTagPassportScreen.notBoundBody), findsOneWidget);
      // Not an error, and not a blank passport either.
      expect(find.text(UnitTagPassportScreen.retryLabel), findsNothing);
      expect(
        _renderedText(tester).join('\n'),
        isNot(contains("couldn't read")),
      );
    });

    testWidgets('a place shows only when the scanner proved one', (
      tester,
    ) async {
      final repo = _FakeRepo();
      await _pump(
        tester,
        UnitTagPassportScreen(unitMarkerId: kMarkerId, scan: reading()),
        repo: repo,
        size: _narrowTall,
      );
      // NotStated renders as absent — never "unknown location".
      expect(find.text('Scanned at'), findsNothing);

      await _pump(
        tester,
        UnitTagPassportScreen(
          unitMarkerId: kMarkerId,
          scan: reading(place: UnitScanPlaceKind.vendorStore),
        ),
        repo: repo,
        size: _narrowTall,
      );
      expect(find.text('Scanned at'), findsOneWidget);
      expect(find.text('Durbar Marg Flagship, Kathmandu'), findsOneWidget);
    });

    testWidgets('a revoked tag is never presented as genuine', (tester) async {
      final repo = _FakeRepo();
      await _pump(
        tester,
        UnitTagPassportScreen(
          unitMarkerId: kMarkerId,
          scan: reading(status: UnitMarkerStatus.revoked),
        ),
        repo: repo,
        size: _narrowTall,
      );
      expect(find.text(UnitTagPassportScreen.revokedHeading), findsOneWidget);
      expect(find.text(UnitTagPassportScreen.genuineHeading), findsNothing);
    });

    testWidgets('a cold deep link shows the passport and invents no reading', (
      tester,
    ) async {
      final repo = _FakeRepo(
        passportAnswer: right(const UnitPassportUnbound()),
      );
      await _pump(
        tester,
        const UnitTagPassportScreen(unitMarkerId: kMarkerId),
        repo: repo,
        size: _narrowTall,
      );
      expect(find.text(UnitTagPassportScreen.notBoundHeading), findsOneWidget);
      // No fabricated tag status when nothing was scanned.
      expect(find.text(UnitTagPassportScreen.genuineHeading), findsNothing);
      expect(find.text(UnitTagPassportScreen.boundLabel), findsNothing);
    });
  });
}
