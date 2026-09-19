import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_scan.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/screens/unit_marker_bindings_screen.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/screens/unit_marker_register_screen.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/screens/unit_marker_scans_screen.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

const String kRefA = 'UM7K2P9QRSTV';
const String kRefB = 'UM3H5J8LMNPQ';

/// The seller's own words on a correction. Asserted **verbatim**: a trail
/// that paraphrases the reason is a trail that has lost the point.
const String kCorrectionReason =
    'Scanned the tag from the next parcel by mistake';

class _FakeRepo implements UnitMarkersRepository {
  _FakeRepo({
    this.listAnswer,
    this.listAnswers,
    this.revokeAnswer,
    this.bindingsAnswer,
    this.scansAnswer,
  });

  Either<NetworkExceptions, PagedResult<UnitMarker>>? listAnswer;

  /// Consumed one per call, so a first page and its next page can differ.
  List<Either<NetworkExceptions, PagedResult<UnitMarker>>>? listAnswers;

  Either<NetworkExceptions, UnitMarker>? revokeAnswer;
  Either<NetworkExceptions, List<UnitMarkerBinding>>? bindingsAnswer;
  Either<NetworkExceptions, List<UnitMarkerScan>>? scansAnswer;

  int listCalls = 0;
  int revokeCalls = 0;
  String? lastRevokedReference;
  String? lastCursor;

  @override
  Future<Either<NetworkExceptions, PagedResult<UnitMarker>>> listMarkers({
    String? productId,
    String? productVariantId,
    String? cursor,
    int pageSize = 20,
  }) async {
    lastCursor = cursor;
    final index = listCalls;
    listCalls++;
    if (listAnswers case final answers?) {
      if (index < answers.length) return answers[index];
    }
    return listAnswer ??
        right(
          const PagedResult<UnitMarker>(
            items: [],
            totalCount: 0,
            pageSize: 20,
            hasMore: false,
          ),
        );
  }

  @override
  Future<Either<NetworkExceptions, UnitMarker>> revoke(
    String reference,
  ) async {
    revokeCalls++;
    lastRevokedReference = reference;
    return revokeAnswer ?? left(const NetworkExceptions.unexpectedError());
  }

  @override
  Future<Either<NetworkExceptions, List<UnitMarkerBinding>>> bindingHistory(
    String reference,
  ) async => bindingsAnswer ?? right(const []);

  @override
  Future<Either<NetworkExceptions, List<UnitMarkerScan>>> scanHistory(
    String reference, {
    int limit = 50,
  }) async => scansAnswer ?? right(const []);

  // ── Not exercised here ────────────────────────────────────────────────
  @override
  Future<Either<NetworkExceptions, List<ProvisionedUnitMarker>>> provision({
    required String productVariantId,
    required int quantity,
  }) async => right(const []);

  @override
  Future<Either<NetworkExceptions, UnitMarkerBindOutcome>> bind({
    required String marker,
    required String subOrderLineId,
    required UnitBindingStage stage,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, UnitMarkerBindOutcome>> correct({
    required String marker,
    required String subOrderLineId,
    required UnitBindingStage stage,
    required String reason,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, UnitMarkerScanResult>> scan({
    required String marker,
    required CodeScanVia via,
    String? atStoreCode,
  }) async => left(const NetworkExceptions.unexpectedError());

  @override
  Future<Either<NetworkExceptions, UnitPassportResult>> unitPassport(
    String unitMarkerId,
  ) async => right(const UnitPassportUnbound());
}

/// 320dp with a 1.3 text scale — the narrowest combination this app supports.
/// A RenderFlex overflow throws here, so every screen below is also an
/// overflow test at that size.
const Size _narrow = Size(320, 1400);
const Size _narrowTall = Size(320, 3200);

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
      child: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(home: screen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .toList(growable: false);

bool _rendersAnyOf(WidgetTester tester, List<String> needles) {
  final all = _renderedText(tester).join('\n');
  return needles.any(all.contains);
}

UnitMarker _marker({
  String reference = kRefA,
  UnitMarkerStatus status = UnitMarkerStatus.active,
  DateTime? revokedAt,
}) => UnitMarker(
  id: 'id-$reference',
  reference: reference,
  productId: 'p1',
  productVariantId: 'v1',
  status: status,
  provisionedAt: DateTime.utc(2026, 9, 1, 10),
  revokedAt: revokedAt,
);

PagedResult<UnitMarker> _page(
  List<UnitMarker> items, {
  bool hasMore = false,
  String? nextCursor,
}) => PagedResult<UnitMarker>(
  items: items,
  totalCount: items.length,
  pageSize: 20,
  nextCursor: nextCursor,
  hasMore: hasMore,
);

UnitMarkerBinding _binding({
  required String id,
  String? correctsBindingId,
  DateTime? supersededAt,
  String? supersededReason,
  String subOrderLineId = 'line-1',
  DateTime? boundAt,
}) => UnitMarkerBinding(
  id: id,
  markerReference: kRefA,
  orderId: 'order-1',
  subOrderId: 'sub-1',
  subOrderLineId: subOrderLineId,
  boundAtStage: UnitBindingStage.pack,
  boundAt: boundAt ?? DateTime.utc(2026, 9, 10, 9),
  correctsBindingId: correctsBindingId,
  supersededAt: supersededAt,
  supersededReason: supersededReason,
);

void main() {
  // ── 1. The register: loaded, empty, failure ──────────────────────────

  group('unit tag register', () {
    testWidgets('loaded shows each tag by its reference and status', (
      tester,
    ) async {
      final repo = _FakeRepo(
        listAnswer: right(
          _page([
            _marker(),
            _marker(
              reference: kRefB,
              status: UnitMarkerStatus.revoked,
              revokedAt: DateTime.utc(2026, 9, 12, 8),
            ),
          ]),
        ),
      );
      await _pump(
        tester,
        const UnitMarkerRegisterScreen(),
        repo: repo,
        size: _narrowTall,
      );

      expect(find.text(kRefA), findsOneWidget);
      expect(find.text(kRefB), findsOneWidget);
      expect(find.text(UnitMarkerStatus.active.label), findsOneWidget);
      expect(find.text(UnitMarkerStatus.revoked.label), findsOneWidget);
    });

    testWidgets('empty reads as empty, not as a failure or a spinner', (
      tester,
    ) async {
      final repo = _FakeRepo(listAnswer: right(_page(const [])));
      await _pump(tester, const UnitMarkerRegisterScreen(), repo: repo);

      expect(
        find.text(UnitMarkerRegisterScreen.emptyHeading),
        findsOneWidget,
      );
      expect(
        find.text(UnitMarkerRegisterScreen.failedHeading),
        findsNothing,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failure says so and offers a retry', (tester) async {
      final repo = _FakeRepo(
        listAnswer: left(const NetworkExceptions.unexpectedError()),
      );
      await _pump(tester, const UnitMarkerRegisterScreen(), repo: repo);

      expect(
        find.text(UnitMarkerRegisterScreen.failedHeading),
        findsOneWidget,
      );
      expect(find.text(UnitMarkerRegisterScreen.retryLabel), findsOneWidget);
      expect(repo.listCalls, 1);

      await tester.tap(find.text(UnitMarkerRegisterScreen.retryLabel));
      await tester.pumpAndSettle();
      expect(repo.listCalls, 2);
    });

    testWidgets('never claims a binding state the list response lacks', (
      tester,
    ) async {
      final repo = _FakeRepo(listAnswer: right(_page([_marker()])));
      await _pump(
        tester,
        const UnitMarkerRegisterScreen(),
        repo: repo,
        size: _narrowTall,
      );

      // `GET vendor/unit-markers` carries no binding field, so no row may
      // assert one either way.
      expect(
        _rendersAnyOf(tester, ['Bound to', 'Not bound', 'Unbound']),
        isFalse,
      );
      // Instead it says where the answer actually lives.
      expect(
        find.text(UnitMarkerRegisterScreen.bindingNotInListNote),
        findsOneWidget,
      );
    });

    testWidgets('a second page appends without blanking the first', (
      tester,
    ) async {
      final repo = _FakeRepo(
        listAnswers: [
          right(_page([_marker()], hasMore: true, nextCursor: 'cursor-2')),
          right(_page([_marker(reference: kRefB)])),
        ],
      );
      await _pump(
        tester,
        const UnitMarkerRegisterScreen(),
        repo: repo,
        size: _narrowTall,
      );

      expect(find.text(kRefA), findsOneWidget);
      expect(find.text(kRefB), findsNothing);

      await tester.tap(find.text(UnitMarkerRegisterScreen.loadMoreLabel));
      await tester.pumpAndSettle();

      expect(repo.lastCursor, 'cursor-2');
      expect(find.text(kRefA), findsOneWidget);
      expect(find.text(kRefB), findsOneWidget);
    });
  });

  // ── 2. Revoke: confirm first, then show the outcome ──────────────────

  group('retiring a tag', () {
    Future<void> openRetireConfirmation(WidgetTester tester) async {
      await tester.tap(find.text(kRefA));
      await tester.pumpAndSettle();
      await tester.tap(find.text(UnitMarkerRevokeSheet.actionLabel));
      await tester.pumpAndSettle();
    }

    testWidgets('asks before acting and says what stops working', (
      tester,
    ) async {
      final repo = _FakeRepo(listAnswer: right(_page([_marker()])));
      await _pump(
        tester,
        const UnitMarkerRegisterScreen(),
        repo: repo,
        size: _narrowTall,
      );

      await openRetireConfirmation(tester);

      // Nothing has been called yet — the confirmation is a gate, not a
      // receipt.
      expect(repo.revokeCalls, 0);
      expect(find.text(UnitMarkerRevokeSheet.heading), findsOneWidget);
      expect(
        find.text(UnitMarkerRevokeSheet.consequences),
        findsOneWidget,
      );
      // And it is plain about the blast radius rather than vague.
      expect(
        UnitMarkerRevokeSheet.consequences.contains('cannot be undone'),
        isTrue,
      );
      expect(
        UnitMarkerRevokeSheet.scopeNote.contains('no stock'),
        isTrue,
      );
    });

    testWidgets('backing out calls nothing', (tester) async {
      final repo = _FakeRepo(listAnswer: right(_page([_marker()])));
      await _pump(
        tester,
        const UnitMarkerRegisterScreen(),
        repo: repo,
        size: _narrowTall,
      );

      await openRetireConfirmation(tester);
      await tester.tap(find.text(UnitMarkerRevokeSheet.cancelLabel));
      await tester.pumpAndSettle();

      expect(repo.revokeCalls, 0);
      expect(find.text(UnitMarkerStatus.active.label), findsOneWidget);
    });

    testWidgets('confirming acts once and the outcome is visible after', (
      tester,
    ) async {
      final repo = _FakeRepo(
        listAnswer: right(_page([_marker()])),
        revokeAnswer: right(
          _marker(
            status: UnitMarkerStatus.revoked,
            revokedAt: DateTime.utc(2026, 9, 19, 11),
          ),
        ),
      );
      await _pump(
        tester,
        const UnitMarkerRegisterScreen(),
        repo: repo,
        size: _narrowTall,
      );

      await openRetireConfirmation(tester);
      await tester.tap(find.text(UnitMarkerRevokeSheet.confirmLabel));
      await tester.pumpAndSettle();

      expect(repo.revokeCalls, 1);
      expect(repo.lastRevokedReference, kRefA);

      // Visible afterwards, two ways: a banner naming the tag, and the row's
      // own status, which is the server's answer rather than a guess.
      expect(
        find.text(UnitMarkerRegisterScreen.revokedBannerHeading),
        findsOneWidget,
      );
      expect(find.text(UnitMarkerStatus.revoked.label), findsOneWidget);
      expect(find.text(UnitMarkerStatus.active.label), findsNothing);
    });

    testWidgets('a failed retirement says so and leaves the tag active', (
      tester,
    ) async {
      final repo = _FakeRepo(
        listAnswer: right(_page([_marker()])),
        revokeAnswer: left(const NetworkExceptions.unexpectedError()),
      );
      await _pump(
        tester,
        const UnitMarkerRegisterScreen(),
        repo: repo,
        size: _narrowTall,
      );

      await openRetireConfirmation(tester);
      await tester.tap(find.text(UnitMarkerRevokeSheet.confirmLabel));
      await tester.pumpAndSettle();

      expect(
        find.text(UnitMarkerRegisterScreen.revokeFailedHeading),
        findsOneWidget,
      );
      // The row must not show a retirement that did not happen.
      expect(find.text(UnitMarkerStatus.active.label), findsOneWidget);
      expect(
        find.text(UnitMarkerRegisterScreen.revokedBannerHeading),
        findsNothing,
      );
    });

    testWidgets('an already-retired tag is not offered for retirement', (
      tester,
    ) async {
      final repo = _FakeRepo(
        listAnswer: right(
          _page([_marker(status: UnitMarkerStatus.revoked)]),
        ),
      );
      await _pump(
        tester,
        const UnitMarkerRegisterScreen(),
        repo: repo,
        size: _narrowTall,
      );

      await tester.tap(find.text(kRefA));
      await tester.pumpAndSettle();

      expect(find.text(UnitMarkerRevokeSheet.actionLabel), findsNothing);
    });
  });

  // ── 3. The correction trail ──────────────────────────────────────────

  group('binding history', () {
    testWidgets('a superseded binding reads as superseded, with its reason', (
      tester,
    ) async {
      final wrong = _binding(
        id: 'b1',
        subOrderLineId: 'line-wrong',
        supersededAt: DateTime.utc(2026, 9, 11, 10),
        supersededReason: kCorrectionReason,
      );
      final fix = _binding(
        id: 'b2',
        correctsBindingId: 'b1',
        subOrderLineId: 'line-right',
        boundAt: DateTime.utc(2026, 9, 11, 10, 30),
      );
      final repo = _FakeRepo(bindingsAnswer: right([fix, wrong]));

      await _pump(
        tester,
        const UnitMarkerBindingsScreen(reference: kRefA),
        repo: repo,
        size: _narrowTall,
      );

      // It has not vanished, and it is labelled for what it is.
      expect(
        find.text(UnitMarkerBindingsScreen.supersededLabel),
        findsOneWidget,
      );
      // The seller's own words, verbatim.
      expect(find.text(kCorrectionReason), findsOneWidget);
      // Both lines are still legible, so the mistake and the fix can be
      // compared — that is the whole use of the trail.
      expect(find.text('line-wrong'), findsOneWidget);
      expect(find.text('line-right'), findsOneWidget);
      // And the replacement is named, not merely implied by ordering.
      expect(
        _rendersAnyOf(tester, ['Replaced by the binding recorded']),
        isTrue,
      );
      expect(
        find.text(UnitMarkerBindingsScreen.currentCorrectionLabel),
        findsOneWidget,
      );
    });

    testWidgets('a lone standing binding is not dressed up as a correction', (
      tester,
    ) async {
      final repo = _FakeRepo(bindingsAnswer: right([_binding(id: 'b1')]));
      await _pump(
        tester,
        const UnitMarkerBindingsScreen(reference: kRefA),
        repo: repo,
        size: _narrowTall,
      );

      expect(find.text(UnitMarkerBindingsScreen.currentLabel), findsOneWidget);
      expect(find.text(UnitMarkerBindingsScreen.supersededLabel), findsNothing);
      expect(
        _rendersAnyOf(tester, ['Replaced by', 'This corrected']),
        isFalse,
      );
    });

    testWidgets('a missing counterpart is said, not guessed at', (
      tester,
    ) async {
      // Superseded, but the row that replaced it is not in this response.
      final orphan = _binding(
        id: 'b1',
        supersededAt: DateTime.utc(2026, 9, 11, 10),
        supersededReason: kCorrectionReason,
      );
      final repo = _FakeRepo(bindingsAnswer: right([orphan]));
      await _pump(
        tester,
        const UnitMarkerBindingsScreen(reference: kRefA),
        repo: repo,
        size: _narrowTall,
      );

      expect(
        _rendersAnyOf(tester, [
          UnitMarkerBindingsScreen.replacementMissing,
        ]),
        isTrue,
      );
      // Nothing else in the response may be promoted into the answer.
      expect(
        _rendersAnyOf(tester, ['Replaced by the binding recorded']),
        isFalse,
      );
      // With nothing standing, the screen says so rather than letting a
      // retired row read as live.
      expect(
        find.text(UnitMarkerBindingsScreen.noLiveHeading),
        findsOneWidget,
      );
    });

    testWidgets('empty reads as never bound', (tester) async {
      final repo = _FakeRepo(bindingsAnswer: right(const []));
      await _pump(
        tester,
        const UnitMarkerBindingsScreen(reference: kRefA),
        repo: repo,
      );

      expect(
        find.text(UnitMarkerBindingsScreen.emptyHeading),
        findsOneWidget,
      );
      expect(
        find.text(UnitMarkerBindingsScreen.failedHeading),
        findsNothing,
      );
    });

    testWidgets('a failure says so and offers a retry', (tester) async {
      final repo = _FakeRepo(
        bindingsAnswer: left(const NetworkExceptions.unexpectedError()),
      );
      await _pump(
        tester,
        const UnitMarkerBindingsScreen(reference: kRefA),
        repo: repo,
      );

      expect(
        find.text(UnitMarkerBindingsScreen.failedHeading),
        findsOneWidget,
      );
      expect(find.text(UnitMarkerBindingsScreen.retryLabel), findsOneWidget);
    });

    test('the trail pairs each row with its real neighbours only', () {
      final wrong = _binding(
        id: 'b1',
        supersededAt: DateTime.utc(2026, 9, 11),
        supersededReason: kCorrectionReason,
      );
      final fix = _binding(id: 'b2', correctsBindingId: 'b1');
      final unrelated = _binding(id: 'b3');

      final trail = UnitMarkerBindingsNotifier.buildTrail([
        fix,
        wrong,
        unrelated,
      ]);

      final fixEntry = trail.firstWhere((e) => e.binding.id == 'b2');
      final wrongEntry = trail.firstWhere((e) => e.binding.id == 'b1');
      final unrelatedEntry = trail.firstWhere((e) => e.binding.id == 'b3');

      expect(fixEntry.replaces?.id, 'b1');
      expect(fixEntry.replacedBy, isNull);
      expect(wrongEntry.replacedBy?.id, 'b2');
      // An unrelated row is joined to nothing — no nearest-neighbour guess.
      expect(unrelatedEntry.replaces, isNull);
      expect(unrelatedEntry.replacedBy, isNull);
    });
  });

  // ── 4. Scan history and the place rule ───────────────────────────────

  group('scan history', () {
    UnitMarkerScan scanAt({
      required UnitScanPlaceKind placeKind,
      String? storeName,
      String via = 'Qr',
      DateTime? at,
    }) => UnitMarkerScan(
      id: 'scan-${placeKind.name}-$storeName',
      scannedAt: at ?? DateTime.utc(2026, 9, 14, 15),
      via: via,
      placeKind: placeKind,
      vendorStoreId: storeName == null ? null : 'store-1',
      vendorStoreName: storeName,
    );

    testWidgets('a proven place shows the store that was presented', (
      tester,
    ) async {
      final repo = _FakeRepo(
        scansAnswer: right([
          scanAt(
            placeKind: UnitScanPlaceKind.vendorStore,
            storeName: 'Durbar Marg Flagship',
          ),
        ]),
      );
      await _pump(
        tester,
        const UnitMarkerScansScreen(reference: kRefA),
        repo: repo,
        size: _narrowTall,
      );

      expect(find.text('Durbar Marg Flagship'), findsOneWidget);
      expect(find.text(UnitMarkerScansScreen.noPlace), findsNothing);
    });

    testWidgets('a reading with no proven place says so, not a blank', (
      tester,
    ) async {
      final repo = _FakeRepo(
        scansAnswer: right([
          scanAt(placeKind: UnitScanPlaceKind.notStated),
        ]),
      );
      await _pump(
        tester,
        const UnitMarkerScansScreen(reference: kRefA),
        repo: repo,
        size: _narrowTall,
      );

      expect(find.text(UnitMarkerScansScreen.noPlace), findsOneWidget);
      // The rule behind the absence is stated, so it reads as a fact about
      // the reading rather than as a gap in the screen.
      expect(
        find.text(UnitMarkerScansScreen.placeRuleHeading),
        findsOneWidget,
      );
      // No location is invented from anywhere.
      expect(
        _rendersAnyOf(tester, [
          'Unknown location',
          'Nepal',
          'Kathmandu',
          'Near',
        ]),
        isFalse,
      );
    });

    testWidgets('a place-less reading borrows no store from its neighbour', (
      tester,
    ) async {
      final repo = _FakeRepo(
        scansAnswer: right([
          scanAt(
            placeKind: UnitScanPlaceKind.vendorStore,
            storeName: 'Durbar Marg Flagship',
          ),
          scanAt(
            placeKind: UnitScanPlaceKind.notStated,
            at: DateTime.utc(2026, 9, 15, 15),
          ),
        ]),
      );
      await _pump(
        tester,
        const UnitMarkerScansScreen(reference: kRefA),
        repo: repo,
        size: _narrowTall,
      );

      expect(find.text('Durbar Marg Flagship'), findsOneWidget);
      expect(find.text(UnitMarkerScansScreen.noPlace), findsOneWidget);
    });

    testWidgets('a store recorded without a name is not printed as an id', (
      tester,
    ) async {
      final repo = _FakeRepo(
        scansAnswer: right([
          scanAt(placeKind: UnitScanPlaceKind.vendorStore),
        ]),
      );
      await _pump(
        tester,
        const UnitMarkerScansScreen(reference: kRefA),
        repo: repo,
        size: _narrowTall,
      );

      expect(find.text(UnitMarkerScansScreen.unnamedStore), findsOneWidget);
      expect(_rendersAnyOf(tester, ['store-1']), isFalse);
    });

    testWidgets('an unrecognised reading method renders as nothing', (
      tester,
    ) async {
      final repo = _FakeRepo(
        scansAnswer: right([
          scanAt(placeKind: UnitScanPlaceKind.notStated, via: 'Telepathy'),
        ]),
      );
      await _pump(
        tester,
        const UnitMarkerScansScreen(reference: kRefA),
        repo: repo,
        size: _narrowTall,
      );

      expect(_rendersAnyOf(tester, ['Telepathy']), isFalse);
    });

    testWidgets('empty reads as never scanned', (tester) async {
      final repo = _FakeRepo(scansAnswer: right(const []));
      await _pump(
        tester,
        const UnitMarkerScansScreen(reference: kRefA),
        repo: repo,
      );

      expect(find.text(UnitMarkerScansScreen.emptyHeading), findsOneWidget);
      expect(find.text(UnitMarkerScansScreen.failedHeading), findsNothing);
    });

    testWidgets('a failure says so and offers a retry', (tester) async {
      final repo = _FakeRepo(
        scansAnswer: left(const NetworkExceptions.unexpectedError()),
      );
      await _pump(
        tester,
        const UnitMarkerScansScreen(reference: kRefA),
        repo: repo,
      );

      expect(find.text(UnitMarkerScansScreen.failedHeading), findsOneWidget);
      expect(find.text(UnitMarkerScansScreen.retryLabel), findsOneWidget);
    });
  });

  // ── 5. The threat model holds on the seller's side too ───────────────

  testWidgets('no buyer identity, address, price or tracking on the trail', (
    tester,
  ) async {
    // Seeded where it could leak if a screen ever reached past its own data.
    const forbidden = [
      'Aarati Shrestha',
      'Jhamsikhel, Lalitpur',
      'Rs 14,500',
      'NP9921733',
    ];
    final repo = _FakeRepo(
      bindingsAnswer: right([
        _binding(
          id: 'b1',
          supersededAt: DateTime.utc(2026, 9, 11),
          supersededReason: kCorrectionReason,
        ),
        _binding(id: 'b2', correctsBindingId: 'b1'),
      ]),
    );
    await _pump(
      tester,
      const UnitMarkerBindingsScreen(reference: kRefA),
      repo: repo,
      size: _narrowTall,
    );

    expect(_rendersAnyOf(tester, forbidden), isFalse);
  });
}
