import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/condition_assurance_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/condition_assurance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/condition_assurance_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';

/// A fake that answers with whatever the test hands it, including "nothing".
class _FakeConditionDataSource implements ConditionAssuranceDataSource {
  _FakeConditionDataSource(this._assurance);

  final ConditionAssurance? _assurance;

  @override
  Future<ConditionAssurance?> fetch(String trackingNumber) async => _assurance;
}

/// The server's real sentences, copied from
/// `ConditionAssuranceAssembler.Statement`. The tests assert on these rather
/// than on anything this app writes, because "rendered verbatim" is the
/// property under test.
const _integrityStatement =
    'Every record of the tamper seal for this parcel — one record — says it '
    'was undisturbed. That is consistent with the parcel not having been '
    'opened. It is not proof that nobody opened it.';
const _compromiseStatement =
    'The tamper seal was recorded as disturbed. That is what was seen and '
    'written down; what it means for this delivery is for a person to decide.';
const _inconclusiveStatement =
    'The tamper seal was checked and the result does not settle the question. '
    'Every record is shown as it was made.';
const _notRecordedStatement =
    'Nothing was recorded about the tamper seal for this parcel. Nothing is '
    'known either way — this is an absence of evidence, not a finding.';
const _contradictionStatement =
    'The records for the tamper seal disagree: it was recorded as intact at '
    'sealing and as disturbed at receipt. Both are shown. Neither can be '
    'relied on over the other, and this counts against neither party.';
const _noFeedReason =
    'No sensor, indicator device or carrier feed reports this control to the '
    'platform. The only way it is ever recorded is a person reading the '
    'indicator and entering what they saw, and nothing was entered for this '
    'consignment.';

ConditionAssurance _forState(
  ConditionEvidenceState state, {
  String statement = '',
  List<ConditionFinding> findings = const <ConditionFinding>[],
  List<ConditionUnsupportedControl> notSupported =
      const <ConditionUnsupportedControl>[],
  List<ConditionFact> facts = const <ConditionFact>[],
  List<String> citedFactKeys = const <String>[],
}) => ConditionAssurance(
  trackingNumber: 'SM-D-42',
  hasRequirements: true,
  hasObservations: true,
  controls: [
    ConditionControl(
      control: 'seal',
      required_: true,
      state: state,
      statement: statement,
      citedFactKeys: citedFactKeys,
    ),
  ],
  facts: facts,
  findings: findings,
  notSupported: notSupported,
);

Future<void> _pumpView(
  WidgetTester tester,
  ConditionAssurance assurance,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ConditionAssuranceView(assurance: assurance),
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

MallStatusPill _controlPill(WidgetTester tester) =>
    tester.widget<MallStatusPill>(find.byType(MallStatusPill).first);

void main() {
  group('the four states', () {
    testWidgets('each renders its own word and its own glyph', (tester) async {
      final seen = <ConditionEvidenceState, (String, IconData)>{};
      for (final state in ConditionEvidenceState.values) {
        await _pumpView(tester, _forState(state, statement: 'x'));
        final pill = _controlPill(tester);
        seen[state] = (pill.label, pill.icon!);
      }

      // Four distinct words for the four real states. A word repeated across
      // two states would be a collapse, which is exactly what this capability
      // exists to prevent.
      final realStates = ConditionEvidenceState.values
          .where((s) => s != ConditionEvidenceState.unrecognised)
          .toList();
      expect(
        realStates.map((s) => seen[s]!.$1).toSet().length,
        realStates.length,
      );
      // And four distinct glyph shapes, so the states survive greyscale.
      expect(
        realStates.map((s) => seen[s]!.$2).toSet().length,
        realStates.length,
      );
    });

    testWidgets('stay apart in greyscale — tone is never the only carrier', (
      tester,
    ) async {
      // notRecorded and inconclusive deliberately share the neutral tone.
      // They must therefore differ in word and glyph, which is the carrier
      // that survives a monochrome screen.
      await _pumpView(
        tester,
        _forState(ConditionEvidenceState.notRecorded, statement: 'x'),
      );
      final absent = _controlPill(tester);
      await _pumpView(
        tester,
        _forState(ConditionEvidenceState.inconclusive, statement: 'x'),
      );
      final unsettled = _controlPill(tester);

      expect(absent.tone, unsettled.tone);
      expect(absent.label, isNot(unsettled.label));
      expect(absent.icon, isNot(unsettled.icon));
    });

    testWidgets('render the backend statement verbatim, never a paraphrase', (
      tester,
    ) async {
      for (final (state, statement) in <(ConditionEvidenceState, String)>[
        (ConditionEvidenceState.notRecorded, _notRecordedStatement),
        (ConditionEvidenceState.consistentWithIntegrity, _integrityStatement),
        (ConditionEvidenceState.consistentWithCompromise, _compromiseStatement),
        (ConditionEvidenceState.inconclusive, _inconclusiveStatement),
      ]) {
        await _pumpView(tester, _forState(state, statement: statement));
        expect(
          find.text(statement),
          findsOneWidget,
          reason: 'the server wrote this sentence; the app must not rewrite it',
        );
      }
    });

    testWidgets('keep "It is not proof that nobody opened it" intact', (
      tester,
    ) async {
      await _pumpView(
        tester,
        _forState(
          ConditionEvidenceState.consistentWithIntegrity,
          statement: _integrityStatement,
        ),
      );

      expect(
        _renderedText(tester).join(' '),
        contains('It is not proof that nobody opened it.'),
      );
    });
  });

  group('inconclusive never reads as compromise', () {
    testWidgets('carries neither the compromise word nor its glyph', (
      tester,
    ) async {
      await _pumpView(
        tester,
        _forState(
          ConditionEvidenceState.consistentWithCompromise,
          statement: _compromiseStatement,
        ),
      );
      final compromise = _controlPill(tester);

      await _pumpView(
        tester,
        _forState(
          ConditionEvidenceState.inconclusive,
          statement: _inconclusiveStatement,
          findings: const [
            ConditionFinding(
              code: 'control.recordsDisagree',
              kind: ConditionFindingKind.contradiction,
              statement: _contradictionStatement,
            ),
          ],
        ),
      );
      final unsettled = _controlPill(tester);

      expect(unsettled.label, isNot(compromise.label));
      expect(unsettled.icon, isNot(compromise.icon));
      expect(unsettled.tone, isNot(compromise.tone));
      // Neutral, not caution: a contradiction is not a step toward tampering.
      expect(unsettled.tone, MallStatusTone.neutral);
    });

    testWidgets('a contradiction is named as a disagreement, not a finding', (
      tester,
    ) async {
      await _pumpView(
        tester,
        _forState(
          ConditionEvidenceState.inconclusive,
          statement: _inconclusiveStatement,
          findings: const [
            ConditionFinding(
              code: 'control.recordsDisagree',
              kind: ConditionFindingKind.contradiction,
              statement: _contradictionStatement,
            ),
          ],
        ),
      );

      final text = _renderedText(tester).join(' ');
      expect(text, contains('Records disagree'));
      expect(text, contains('counts against neither party'));
      // Nothing anywhere on the card accuses anyone.
      expect(text, isNot(contains('tampered with.')));
    });
  });

  group('attested versus typed', () {
    ConditionAssurance withFacts() => _forState(
      ConditionEvidenceState.consistentWithIntegrity,
      statement: _integrityStatement,
      citedFactKeys: const ['seal.custodyEntry', 'seal.receipt.state'],
      facts: [
        ConditionFact(
          source: 'chainOfCustody',
          key: 'seal.custodyEntry',
          label: 'Sealing signed into the custody chain',
          value: 'Yes',
          attested: true,
          observedUtc: DateTime.utc(2026, 9, 14, 3, 20),
        ),
        ConditionFact(
          source: 'conditionObservation',
          key: 'seal.receipt.state',
          label: 'Seal at receipt',
          value: 'Intact',
          attested: false,
          observedUtc: DateTime.utc(2026, 9, 18, 9, 15),
        ),
      ],
    );

    testWidgets('a signed fact and a typed fact read differently', (
      tester,
    ) async {
      await _pumpView(tester, withFacts());

      final text = _renderedText(tester).join(' ');
      expect(text, contains('Signed into the custody chain'));
      expect(text, contains('Typed in by a person'));
    });

    testWidgets('the card says no device measures anything', (tester) async {
      await _pumpView(tester, withFacts());

      // There is no sensor anywhere on the platform, and a reader must not be
      // left to assume there is one behind a temperature reading.
      expect(
        _renderedText(tester).join(' '),
        contains('Nothing on StyleMint measures a parcel.'),
      );
    });

    testWidgets('an absent attested flag is never promoted to signed', (
      tester,
    ) async {
      final fact = ConditionFact.fromJson(const {
        'source': 'conditionObservation',
        'key': 'seal.receipt.state',
        'label': 'Seal at receipt',
        'value': 'Intact',
      });
      expect(fact.attested, isFalse);

      await _pumpView(
        tester,
        _forState(
          ConditionEvidenceState.consistentWithIntegrity,
          statement: _integrityStatement,
          citedFactKeys: const ['seal.receipt.state'],
          facts: [fact],
        ),
      );
      expect(
        _renderedText(tester).join(' '),
        isNot(contains('Signed into the custody chain')),
      );
    });
  });

  group('notSupported', () {
    testWidgets('is visible, named and carries the reason verbatim', (
      tester,
    ) async {
      await _pumpView(
        tester,
        _forState(
          ConditionEvidenceState.notRecorded,
          statement: _notRecordedStatement,
          notSupported: const [
            ConditionUnsupportedControl(
              control: 'temperatureIndicator',
              reason: _noFeedReason,
            ),
          ],
        ),
      );

      expect(
        find.text('Required, but StyleMint cannot evidence it'),
        findsOneWidget,
      );
      expect(find.text('Temperature indicator'), findsOneWidget);
      // A requirement must never be mistaken for a capability, so the reason
      // is printed whole rather than summarised into "unavailable".
      expect(find.text(_noFeedReason), findsOneWidget);
    });
  });

  group('no score of any kind', () {
    testWidgets('nothing rendered grades the parcel, the seller or a courier', (
      tester,
    ) async {
      await _pumpView(
        tester,
        _forState(
          ConditionEvidenceState.consistentWithCompromise,
          statement: _compromiseStatement,
          findings: const [
            ConditionFinding(
              code: 'control.disturbedRecorded',
              kind: ConditionFindingKind.recordedObservation,
              statement:
                  'The tamper seal was recorded as disturbed at receipt on '
                  '18 September 2026. That is what was recorded and by whom. '
                  'It is not a finding that this parcel was tampered with, it '
                  'does not decide any claim, and nothing follows from it '
                  'automatically — a person decides what happens next.',
            ),
          ],
          notSupported: const [
            ConditionUnsupportedControl(
              control: 'shockIndicator',
              reason: _noFeedReason,
            ),
          ],
        ),
      );

      final text = _renderedText(tester).join(' ').toLowerCase();
      for (final banned in const [
        'score',
        'confidence',
        'probability',
        'rating',
        'risk level',
        '%',
        'out of 10',
        'trust level',
      ]) {
        expect(text, isNot(contains(banned)), reason: 'no grade may appear');
      }
    });
  });

  group('unknown values degrade safely', () {
    test('an unknown state never becomes consistentWithIntegrity', () {
      expect(
        ConditionEvidenceState.fromWire('consistentWithSomethingNew'),
        ConditionEvidenceState.unrecognised,
      );
      expect(
        ConditionEvidenceState.fromWire(null),
        ConditionEvidenceState.unrecognised,
      );
    });

    testWidgets('an unknown state reads as unrecognised, not as reassurance', (
      tester,
    ) async {
      await _pumpView(
        tester,
        _forState(
          ConditionEvidenceState.unrecognised,
          statement: 'A sentence from a newer server.',
        ),
      );

      final pill = _controlPill(tester);
      expect(pill.tone, isNot(MallStatusTone.success));
      expect(pill.label, 'State not recognised');
      // The server's own words still render, so nothing is lost.
      expect(find.text('A sentence from a newer server.'), findsOneWidget);
    });

    test('an unknown finding kind still renders its statement', () {
      final finding = ConditionFinding.fromJson(const {
        'code': 'control.somethingNew',
        'kind': 'somethingNew',
        'statement': 'A finding kind from a newer server.',
      });
      expect(finding.kind, ConditionFindingKind.unrecognised);
      expect(finding.statement, 'A finding kind from a newer server.');
    });
  });

  group('semantics', () {
    testWidgets('every control carries a spoken label', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpView(
        tester,
        _forState(
          ConditionEvidenceState.inconclusive,
          statement: _inconclusiveStatement,
          notSupported: const [
            ConditionUnsupportedControl(
              control: 'humidityIndicator',
              reason: _noFeedReason,
            ),
          ],
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp('Checked, and the records do not settle')),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Required, but StyleMint cannot evidence it'),
        ),
        findsWidgets,
      );
      // The card is a read-only record: every node a screen reader can land
      // on says what it is.
      expect(find.byType(MallStatusPill), findsOneWidget);
      handle.dispose();
    });

    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      tester.view.physicalSize = const Size(320, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ConditionAssuranceView(
                  assurance: _forState(
                    ConditionEvidenceState.consistentWithCompromise,
                    statement: _compromiseStatement,
                    citedFactKeys: const ['seal.receipt.state'],
                    facts: [
                      ConditionFact(
                        source: 'conditionObservation',
                        key: 'seal.receipt.state',
                        label: 'Seal at receipt',
                        value: 'Disturbed',
                        attested: false,
                        observedUtc: DateTime.utc(2026, 9, 18, 9, 15),
                      ),
                    ],
                    findings: const [
                      ConditionFinding(
                        code: 'control.disturbedRecorded',
                        kind: ConditionFindingKind.recordedObservation,
                        statement: _compromiseStatement,
                      ),
                    ],
                    notSupported: const [
                      ConditionUnsupportedControl(
                        control: 'temperatureIndicator',
                        reason: _noFeedReason,
                      ),
                    ],
                  ),
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

  group('the card', () {
    testWidgets('draws nothing when the endpoint has nothing to say', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conditionAssuranceDataSourceProvider.overrideWithValue(
              _FakeConditionDataSource(null),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ConditionAssuranceCard(trackingNumber: 'SM-D-42'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // An unavailable endpoint is not "notRecorded". The app declines to say
      // anything it did not read.
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('draws the record when there is one', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conditionAssuranceDataSourceProvider.overrideWithValue(
              _FakeConditionDataSource(
                _forState(
                  ConditionEvidenceState.consistentWithIntegrity,
                  statement: _integrityStatement,
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ConditionAssuranceCard(trackingNumber: 'SM-D-42'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Condition and tamper record'), findsOneWidget);
      expect(find.text(_integrityStatement), findsOneWidget);
    });
  });

  group('parsing', () {
    test('reads the document and invents nothing', () {
      final assurance = ConditionAssurance.fromJson(const {
        'trackingNumber': 'SM-D-42',
        'hasRequirements': true,
        'hasObservations': true,
        'collectedUtc': '2026-09-19T10:00:00Z',
        'controls': [
          {
            'control': 'seal',
            'required': true,
            'state': 'consistentWithCompromise',
            'statement': _compromiseStatement,
            'observationCount': 2,
            'citedFactKeys': ['seal.receipt.state'],
          },
        ],
        'facts': [
          {
            'source': 'conditionObservation',
            'key': 'seal.receipt.state',
            'label': 'Seal at receipt',
            'value': 'Disturbed',
            'observedUtc': '2026-09-18T09:15:00Z',
            'attested': false,
          },
        ],
        'findings': [
          {
            'code': 'control.disturbedRecorded',
            'kind': 'recordedObservation',
            'statement': _compromiseStatement,
            'citedFactKeys': ['seal.receipt.state'],
          },
        ],
        'notSupported': [
          {'control': 'temperatureIndicator', 'reason': _noFeedReason},
        ],
      });

      expect(
        assurance.controls.single.state,
        ConditionEvidenceState.consistentWithCompromise,
      );
      expect(assurance.controls.single.statement, _compromiseStatement);
      expect(assurance.facts.single.attested, isFalse);
      expect(
        assurance.findings.single.kind,
        ConditionFindingKind.recordedObservation,
      );
      expect(assurance.notSupported.single.reason, _noFeedReason);
      expect(
        assurance.factsFor(assurance.controls.single).single.key,
        'seal.receipt.state',
      );
    });

    test('an empty document is empty rather than a finding', () {
      final assurance = ConditionAssurance.fromJson(const {
        'trackingNumber': 'SM-D-42',
        'hasRequirements': false,
        'hasObservations': false,
      });
      expect(assurance.isEmpty, isTrue);
    });
  });
}
