import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/custody_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/custody_chain.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/custody_proof_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/kathmandu_time.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_timeline.dart';

/// A fake that answers with whatever the test hands it, including "nothing".
class _FakeCustodyDataSource implements CustodyDataSource {
  _FakeCustodyDataSource(this._proof);

  final CustodyProof? _proof;
  int calls = 0;

  @override
  Future<CustodyProof?> fetch(String trackingNumber) async {
    calls++;
    return _proof;
  }

  /// These tests are about the card, not the hand-over. Nothing here asks for
  /// an export, and answering "none" keeps it that way.
  @override
  Future<CustodyProofExport?> export(
    String trackingNumber, {
    required bool bearer,
  }) async => null;
}

/// Deliberately *not* evenly spaced, deliberately not derived from each other,
/// and one entry carries no timestamp at all. If any rendered time could be
/// computed from a neighbour, these fixtures would expose it.
final _sealed = DateTime.utc(2026, 9, 14, 3, 20);
final _pickedUp = DateTime.utc(2026, 9, 14, 11, 5);
final _handedOff = DateTime.utc(2026, 9, 17, 2, 40);
final _delivered = DateTime.utc(2026, 9, 18, 9, 15);

List<CustodyEntry> _entries() => [
  CustodyEntry(
    id: 'e0',
    sequence: 0,
    eventKind: CustodyEventKind.sealApplied,
    occurredUtc: _sealed,
  ),
  CustodyEntry(
    id: 'e1',
    sequence: 1,
    eventKind: CustodyEventKind.pickedUp,
    occurredUtc: _pickedUp,
  ),
  CustodyEntry(
    id: 'e2',
    sequence: 2,
    eventKind: CustodyEventKind.handedOff,
    occurredUtc: _handedOff,
    notes: 'Bag transferred at the Balaju sorting point.',
  ),
  CustodyEntry(
    id: 'e3',
    sequence: 3,
    eventKind: CustodyEventKind.deliveryConfirmed,
    occurredUtc: _delivered,
    receivedByDelegateName: 'Sarita Maharjan',
  ),
];

CustodyProof _proof(
  CustodyVerificationState state, {
  List<CustodyEntry>? entries,
}) => CustodyProof(
  entries: entries ?? _entries(),
  verification: switch (state) {
    CustodyVerificationState.verified => const CustodyVerification.verified(),
    CustodyVerificationState.failed => const CustodyVerification.failed(),
    CustodyVerificationState.couldNotVerify =>
      const CustodyVerification.couldNotVerify(),
  },
);

Future<void> _pumpView(WidgetTester tester, CustodyProof proof) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: CustodyProofView(proof: proof)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpCard(
  WidgetTester tester,
  _FakeCustodyDataSource source,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [custodyDataSourceProvider.overrideWithValue(source)],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CustodyProofCard(trackingNumber: 'SM-D-42'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((s) => s.isNotEmpty)
    .toList();

void main() {
  group('the entries', () {
    testWidgets('render from the fixture in the order the API returned them', (
      tester,
    ) async {
      await _pumpView(tester, _proof(CustodyVerificationState.verified));

      final steps = tester
          .widget<MallTimeline>(find.byType(MallTimeline))
          .steps;
      expect(steps.map((s) => s.title), [
        'Sealed by the seller',
        'Picked up',
        'Passed to the next courier',
        'Delivered',
      ]);
    });

    testWidgets('are not re-sorted client-side', (tester) async {
      // The server owns the chain's order; re-sorting a hash-chained log here
      // would invent a sequence the signatures do not cover.
      final shuffled = _entries().reversed.toList();
      await _pumpView(
        tester,
        _proof(CustodyVerificationState.verified, entries: shuffled),
      );

      final steps = tester
          .widget<MallTimeline>(find.byType(MallTimeline))
          .steps;
      expect(steps.first.title, 'Delivered');
      expect(steps.last.title, 'Sealed by the seller');
    });

    testWidgets('show each entry its own timestamp and never a derived one', (
      tester,
    ) async {
      await _pumpView(tester, _proof(CustodyVerificationState.verified));

      final steps = tester
          .widget<MallTimeline>(find.byType(MallTimeline))
          .steps;
      // Each row's time is its own entry's `occurredUtc`, formatted. Nothing
      // is interpolated between them, and the gaps stay uneven because the
      // real gaps were uneven.
      expect(steps[0].timestamp, formatNptDateTime(_sealed));
      expect(steps[1].timestamp, formatNptDateTime(_pickedUp));
      expect(steps[2].timestamp, formatNptDateTime(_handedOff));
      expect(steps[3].timestamp, formatNptDateTime(_delivered));
      expect(steps.length, 4, reason: 'no handover may be interpolated');
    });

    testWidgets('show no time at all for an entry that carries none', (
      tester,
    ) async {
      await _pumpView(
        tester,
        _proof(
          CustodyVerificationState.verified,
          entries: const [
            CustodyEntry(
              id: 'e0',
              sequence: 0,
              eventKind: CustodyEventKind.pickedUp,
              occurredUtc: null,
            ),
          ],
        ),
      );

      final steps = tester
          .widget<MallTimeline>(find.byType(MallTimeline))
          .steps;
      expect(steps.single.timestamp, isNull);
    });

    testWidgets('name the delegate when someone else took the parcel', (
      tester,
    ) async {
      await _pumpView(tester, _proof(CustodyVerificationState.verified));

      expect(
        find.text('Taken by Sarita Maharjan on your behalf'),
        findsOneWidget,
      );
    });

    testWidgets('say nothing about a delegate on an ordinary handover', (
      tester,
    ) async {
      await _pumpView(tester, _proof(CustodyVerificationState.verified));

      final steps = tester
          .widget<MallTimeline>(find.byType(MallTimeline))
          .steps;
      expect(steps[1].detail, isNull);
      expect(steps[2].detail, 'Bag transferred at the Balaju sorting point.');
    });
  });

  group('the three verification states', () {
    testWidgets('verified says the signatures check out', (tester) async {
      await _pumpView(tester, _proof(CustodyVerificationState.verified));
      expect(find.text('Signatures check out'), findsOneWidget);
      expect(find.textContaining('All of them hold.'), findsOneWidget);
    });

    testWidgets(
      'failed speaks about the record, not about who handled the parcel',
      (tester) async {
        await _pumpView(tester, _proof(CustodyVerificationState.failed));

        expect(find.text('Signatures do not check out'), findsOneWidget);
        expect(
          find.textContaining('cannot be shown to be intact'),
          findsOneWidget,
        );
        final text = _renderedText(tester).join(' ').toLowerCase();
        for (final accusation in [
          'tamper',
          'stolen',
          'theft',
          'fraud',
          'courier is',
          'someone',
          'blame',
          'fault',
        ]) {
          expect(
            text.contains(accusation),
            isFalse,
            reason: 'a failed check must not accuse anyone: "$accusation"',
          );
        }
      },
    );

    testWidgets('could-not-verify never reads as a pass', (tester) async {
      await _pumpView(tester, _proof(CustodyVerificationState.couldNotVerify));

      expect(find.text('Not checked yet'), findsOneWidget);
      final text = _renderedText(tester).join(' ');
      expect(text.contains('Signatures check out'), isFalse);
      expect(
        find.textContaining('not the same as a check that failed'),
        findsOneWidget,
      );
    });

    test('all three differ in wording, glyph and tone', () {
      final copies = CustodyVerificationState.values
          .map(custodyVerdictCopy)
          .toList();

      expect(copies.map((c) => c.pillLabel).toSet(), hasLength(3));
      expect(copies.map((c) => c.body).toSet(), hasLength(3));
      expect(copies.map((c) => c.semanticSummary).toSet(), hasLength(3));
      // The glyph is the non-colour carrier: three different shapes means the
      // states stay apart in greyscale and for a colour-blind reader.
      expect(copies.map((c) => c.glyph).toSet(), hasLength(3));
      expect(copies.map((c) => c.tone).toSet(), hasLength(3));
    });

    testWidgets('each state renders a pill with its own glyph', (tester) async {
      final seen = <IconData>{};
      final labels = <String>{};
      for (final state in CustodyVerificationState.values) {
        await _pumpView(tester, _proof(state));
        final pill = tester.widget<MallStatusPill>(
          find.byType(MallStatusPill),
        );
        expect(
          pill.icon,
          isNotNull,
          reason: 'state must not rest on colour alone',
        );
        seen.add(pill.icon!);
        labels.add(pill.label);
      }
      expect(seen, hasLength(3));
      expect(labels, hasLength(3));
    });
  });

  group('nothing to show', () {
    testWidgets('an empty custody call renders nothing', (tester) async {
      final source = _FakeCustodyDataSource(
        const CustodyProof(
          entries: [],
          verification: CustodyVerification.verified(),
        ),
      );
      await _pumpCard(tester, source);

      expect(source.calls, 1);
      expect(find.byType(MallTimeline), findsNothing);
      expect(find.text('Chain of custody'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unavailable endpoint renders nothing, not an error', (
      tester,
    ) async {
      await _pumpCard(tester, _FakeCustodyDataSource(null));

      expect(find.byType(MallTimeline), findsNothing);
      expect(find.text('Chain of custody'), findsNothing);
      expect(find.byType(MallStatusPill), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a parcel that does have a log renders the card', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        _FakeCustodyDataSource(_proof(CustodyVerificationState.verified)),
      );

      expect(find.text('Chain of custody'), findsOneWidget);
      expect(find.byType(MallTimeline), findsOneWidget);
    });
  });

  group('no score', () {
    testWidgets('no trust figure, grade or ratio appears in any state', (
      tester,
    ) async {
      for (final state in CustodyVerificationState.values) {
        await _pumpView(tester, _proof(state));
        final text = _renderedText(tester).join(' ');
        final lower = text.toLowerCase();

        for (final forbidden in [
          'score',
          'trust',
          'rating',
          'rated',
          'confidence',
          'grade',
          'out of',
          'integrity level',
          '%',
        ]) {
          expect(
            lower.contains(forbidden),
            isFalse,
            reason: '"$forbidden" reads as a score, in state $state',
          );
        }

        // No "3 of 4 entries verified" either: the report carries those
        // counts and they stay in the report.
        expect(
          RegExp(r'\d+\s*(of|/)\s*\d+').hasMatch(text),
          isFalse,
          reason: 'a ratio of entries reads as a grade, in state $state',
        );
      }
    });

    testWidgets('no hash, signature or key id is put in front of the reader', (
      tester,
    ) async {
      await _pumpView(tester, _proof(CustodyVerificationState.verified));
      final lower = _renderedText(tester).join(' ').toLowerCase();
      for (final noise in ['sha256', 'merkle', 'ecdsa', 'public key']) {
        expect(lower.contains(noise), isFalse, reason: 'raw crypto: $noise');
      }
    });
  });

  group('accessibility', () {
    testWidgets('the verdict and the timeline both announce themselves', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpView(tester, _proof(CustodyVerificationState.failed));

      // The verdict is its own announcement, not a tail on the card's.
      expect(
        tester.getSemantics(find.byType(MallStatusPill)).label,
        'Failed verification: the handover log cannot be shown to be intact.',
      );
      expect(
        find.bySemanticsLabel('Handovers recorded for this parcel'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Chain of custody for this parcel. Failed verification'),
        ),
        findsOneWidget,
      );
      // No control in this card is unlabelled: it is a read-only record, and
      // every node a screen reader can land on says what it is.
      expect(find.byType(MallStatusPill), findsOneWidget);
      handle.dispose();
    });

    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: CustodyProofView(
                  proof: _proof(CustodyVerificationState.couldNotVerify),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('parsing', () {
    test('an entry reads its own fields and invents none', () {
      final entry = CustodyEntry.fromJson(const {
        'id': 'abc',
        'sequence': 2,
        'eventKind': 3,
        'occurredUtc': '2026-09-17T02:40:00Z',
        'notes': '  swapped bags  ',
        'receivedByDelegateName': '  Sarita  ',
      });

      expect(entry.id, 'abc');
      expect(entry.sequence, 2);
      expect(entry.eventKind, CustodyEventKind.handedOff);
      expect(entry.occurredUtc, DateTime.utc(2026, 9, 17, 2, 40));
      expect(entry.notes, 'swapped bags');
      expect(entry.receivedByDelegateName, 'Sarita');
      expect(entry.isDelegatedHandover, isTrue);
    });

    test('an unparsable timestamp becomes null, never a substitute', () {
      final entry = CustodyEntry.fromJson(const {
        'id': 'abc',
        'sequence': 0,
        'eventKind': 2,
        'occurredUtc': 'not a date',
      });
      expect(entry.occurredUtc, isNull);
    });

    test('an unknown event kind still renders as a handover', () {
      expect(CustodyEventKind.fromCode(99), CustodyEventKind.unknown);
      expect(
        custodyEventTitle(CustodyEventKind.unknown),
        'Handover recorded',
      );
    });

    test('a report with isValid true is verified, false is failed', () {
      expect(
        CustodyVerification.fromJson(const {'isValid': true}).state,
        CustodyVerificationState.verified,
      );
      expect(
        CustodyVerification.fromJson(const {'isValid': false}).state,
        CustodyVerificationState.failed,
      );
    });

    test('a report with no isValid is could-not-verify, never a pass', () {
      expect(
        CustodyVerification.fromJson(const <String, dynamic>{}).state,
        CustodyVerificationState.couldNotVerify,
      );
    });
  });
}
