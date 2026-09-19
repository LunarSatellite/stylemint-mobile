import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/passport_claims_section.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';

/// The server's own deterministic sentences, copied from
/// `PassportPresentation`. Asserting on these rather than on anything the app
/// writes is the point: "rendered verbatim" is the property under test.
const _recordedLabel = 'Recorded by the seller. Nobody has checked it.';
const _verifiedLabel =
    'Independently checked by StyleMint against a source outside the '
    'claimant.';
const _failedLabel =
    'StyleMint checked this and it did not hold. Treat it as withdrawn, not '
    'as a claim.';
const _couldNotVerifyLabel =
    'StyleMint tried to check this and could not reach a conclusion. It '
    'remains unverified.';
const _listingScopeExplanation =
    'This passport identifies a catalogue listing and its seller. It cannot '
    'identify which physical item was shipped or returned, because no '
    'per-item marker is bound to an order line on this platform.';
const _coverageSummary =
    '3 passport records: 1 independently verified by StyleMint, 1 recorded '
    'but unverified and 1 that failed verification. Anything not listed is '
    'unknown, not assumed.';

PassportClaim _claim({
  required PassportAssurance assurance,
  required String assuranceLabel,
  String kindLabel = 'Origin',
  String statement = 'Made in Bhaktapur.',
  String issuerName = 'Himalaya Handwork',
  bool? presentAsFact,
}) => PassportClaim(
  claimId: 'c-${assurance.name}',
  kindLabel: kindLabel,
  statement: statement,
  assurance: assurance,
  assuranceLabel: assuranceLabel,
  presentAsFact: presentAsFact ?? (assurance == PassportAssurance.verified),
  issuerName: issuerName,
  isInEffect: true,
);

ProductPassport _passport({
  List<PassportClaim> claims = const <PassportClaim>[],
  PassportSubject? subject,
  PassportCoverage? coverage,
}) => ProductPassport(
  vendorBusinessName: 'Himalaya Handwork',
  vendorIdentityVerified: true,
  vendorOnPlatformSince: DateTime.utc(2024),
  authenticityStatement: 'Sold by a verified business on StyleMint.',
  schemaVersion: 2,
  claims: claims,
  subject:
      subject ??
      const PassportSubject(
        scope: 'listing',
        scopeExplanation: _listingScopeExplanation,
        identifiesPhysicalUnit: false,
      ),
  coverage: coverage,
);

Future<void> _pump(WidgetTester tester, ProductPassport passport) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PassportClaimsSection(passport: passport),
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
  group('an unverified claim is attributed, never asserted', () {
    testWidgets('a recorded claim is named to its issuer and quoted', (
      tester,
    ) async {
      await _pump(
        tester,
        _passport(
          claims: [
            _claim(
              assurance: PassportAssurance.recorded,
              assuranceLabel: _recordedLabel,
            ),
          ],
        ),
      );

      final text = _renderedText(tester);
      // Attributed: somebody said this, and the passport says who.
      expect(text, contains('Himalaya Handwork states:'));
      expect(text, contains('“Made in Bhaktapur.”'));
      // The bare statement never appears as the platform's own sentence.
      expect(text, isNot(contains('Made in Bhaktapur.')));
      // And the server's sentence about how far it may be relied on is
      // printed exactly as written.
      expect(text, contains(_recordedLabel));
    });

    testWidgets('a couldNotVerify claim stays attributed and says so', (
      tester,
    ) async {
      await _pump(
        tester,
        _passport(
          claims: [
            _claim(
              assurance: PassportAssurance.couldNotVerify,
              assuranceLabel: _couldNotVerifyLabel,
            ),
          ],
        ),
      );

      final text = _renderedText(tester);
      expect(text, contains('Himalaya Handwork states:'));
      expect(text, contains(_couldNotVerifyLabel));
      // "Could not check" is not "checked and failed", and not "not checked".
      expect(
        tester.widget<MallStatusPill>(find.byType(MallStatusPill)).label,
        'Could not be checked',
      );
    });

    testWidgets('only a verified claim is stated by the platform', (
      tester,
    ) async {
      await _pump(
        tester,
        _passport(
          claims: [
            _claim(
              assurance: PassportAssurance.verified,
              assuranceLabel: _verifiedLabel,
            ),
          ],
        ),
      );

      final text = _renderedText(tester);
      expect(text, contains('Made in Bhaktapur.'));
      expect(text, isNot(contains('Himalaya Handwork states:')));
      expect(text, contains(_verifiedLabel));
    });

    testWidgets('presentAsFact false outranks anything else on the row', (
      tester,
    ) async {
      // A server that sent Verified but presentAsFact:false is contradicting
      // itself; the app takes the cautious half of the contradiction.
      await _pump(
        tester,
        _passport(
          claims: [
            _claim(
              assurance: PassportAssurance.verified,
              assuranceLabel: _verifiedLabel,
              presentAsFact: false,
            ),
          ],
        ),
      );

      expect(_renderedText(tester), contains('Himalaya Handwork states:'));
    });

    testWidgets('a claim with no issuer name is still not asserted', (
      tester,
    ) async {
      await _pump(
        tester,
        _passport(
          claims: [
            _claim(
              assurance: PassportAssurance.recorded,
              assuranceLabel: _recordedLabel,
              issuerName: '',
            ),
          ],
        ),
      );

      expect(_renderedText(tester), contains('Recorded on this listing:'));
    });

    test('each assurance has its own word and its own glyph', () {
      // Verified, couldNotVerify and verificationFailed must never share a
      // word: "checked and it held", "could not check" and "checked and it
      // failed" are three different facts, and the whole enum exists so a
      // reader cannot collapse them.
      final distinct = const [
        PassportAssurance.verified,
        PassportAssurance.recorded,
        PassportAssurance.couldNotVerify,
        PassportAssurance.verificationFailed,
      ].map(passportAssuranceCopy).toList();

      expect(distinct.map((c) => c.glyph).toSet().length, distinct.length);
      // `recorded` and `unrecognised` deliberately share the "Not checked"
      // word, because that is what both of them are. Every other pair
      // differs.
      expect(
        distinct.map((c) => c.pillLabel).toSet().length,
        distinct.length,
      );
      // An unrecognised assurance must never wear the verified tone.
      expect(
        passportAssuranceCopy(PassportAssurance.unrecognised).tone,
        isNot(passportAssuranceCopy(PassportAssurance.verified).tone),
      );
    });
  });

  group('a failed check is withdrawn, not a claim', () {
    testWidgets('is drawn under Withdrawn with no issuer attribution', (
      tester,
    ) async {
      await _pump(
        tester,
        _passport(
          claims: [
            _claim(
              assurance: PassportAssurance.verificationFailed,
              assuranceLabel: _failedLabel,
              kindLabel: 'Authorised supply',
              statement: 'We are an authorised distributor.',
            ),
          ],
        ),
      );

      final text = _renderedText(tester);
      expect(text, contains('Withdrawn'));
      expect(text, contains('Authorised supply — withdrawn'));
      expect(text, contains(_failedLabel));
      // Never resurrected as "the seller says X".
      expect(text, isNot(contains('Himalaya Handwork states:')));
      expect(text, isNot(contains('“We are an authorised distributor.”')));
    });

    testWidgets('its statement is struck through, not merely greyed', (
      tester,
    ) async {
      await _pump(
        tester,
        _passport(
          claims: [
            _claim(
              assurance: PassportAssurance.verificationFailed,
              assuranceLabel: _failedLabel,
              statement: 'We are an authorised distributor.',
            ),
          ],
        ),
      );

      final struck = tester.widget<Text>(
        find.text('We are an authorised distributor.'),
      );
      expect(struck.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('never appears among the standing claims', (tester) async {
      final passport = _passport(
        claims: [
          _claim(
            assurance: PassportAssurance.recorded,
            assuranceLabel: _recordedLabel,
          ),
          _claim(
            assurance: PassportAssurance.verificationFailed,
            assuranceLabel: _failedLabel,
          ),
        ],
      );

      expect(passport.standingClaims.length, 1);
      expect(
        passport.standingClaims.single.assurance,
        PassportAssurance.recorded,
      );
      expect(passport.withdrawnClaims.length, 1);
    });
  });

  group('listing, not the object in your hands', () {
    testWidgets('identifiesPhysicalUnit false is said plainly', (tester) async {
      await _pump(tester, _passport());

      final text = _renderedText(tester).join(' ');
      expect(
        text,
        contains(
          'This describes the listing, not the individual item you receive.',
        ),
      );
      // And the server's own explanation, verbatim beside it.
      expect(text, contains(_listingScopeExplanation));
    });

    testWidgets('a batch number never implies it is your item', (tester) async {
      await _pump(
        tester,
        _passport(
          subject: const PassportSubject(
            scope: 'batch',
            scopeExplanation:
                "This passport narrows to batch or serial identity 'B-19', "
                'which StyleMint verified independently. It still cannot '
                'identify which physical item within that batch was shipped '
                'or returned.',
            identifiesPhysicalUnit: false,
            serialOrBatchNumber: 'B-19',
          ),
        ),
      );

      final text = _renderedText(tester).join(' ');
      expect(text, contains('Batch or serial number: B-19'));
      expect(
        text,
        contains(
          'This describes the listing, not the individual item you receive.',
        ),
      );
    });

    testWidgets('a passport that did identify a unit drops the caveat', (
      tester,
    ) async {
      // Nothing produces this today. The branch exists so that if a per-item
      // marker ever ships, the screen stops saying something untrue.
      await _pump(
        tester,
        _passport(
          subject: const PassportSubject(
            scope: 'unit',
            scopeExplanation: 'This passport identifies one physical item.',
            identifiesPhysicalUnit: true,
          ),
        ),
      );

      expect(
        _renderedText(tester).join(' '),
        isNot(contains('not the individual item you receive')),
      );
    });
  });

  group('absent reads as absent', () {
    testWidgets('unknownKinds are named and are not read as "none"', (
      tester,
    ) async {
      await _pump(
        tester,
        _passport(
          coverage: const PassportCoverage(
            knownKinds: ['Origin'],
            unknownKinds: ['Warranty', 'Recall or safety notice'],
            summary: _coverageSummary,
          ),
        ),
      );

      final text = _renderedText(tester).join(' ');
      expect(text, contains('Not recorded for this listing'));
      expect(text, contains('Warranty'));
      expect(text, contains('Recall or safety notice'));
      expect(text, contains('Not recorded is not the same as none.'));
      // The passport never claims the listing lacks a warranty.
      expect(text, isNot(contains('No warranty')));
      expect(text, isNot(contains('no warranty')));
      // And the server's own summary sentence is printed as written.
      expect(text, contains(_coverageSummary));
    });

    testWidgets('a passport with nothing recorded still answers', (
      tester,
    ) async {
      await _pump(
        tester,
        _passport(
          coverage: const PassportCoverage(
            unknownKinds: ['Origin', 'Warranty'],
            summary:
                "Nothing has been recorded against this listing's passport. "
                'Origin, authorised supply, serial or batch number, '
                'warranty, care and recall are all unknown.',
          ),
        ),
      );

      expect(
        _renderedText(tester).join(' '),
        contains("Nothing has been recorded against this listing's passport."),
      );
    });
  });

  group('unknown values degrade safely', () {
    test('an unknown assurance is never verified', () {
      expect(
        PassportAssurance.fromJson(99),
        PassportAssurance.unrecognised,
      );
      expect(
        PassportAssurance.fromJson('SomethingNew'),
        PassportAssurance.unrecognised,
      );
      expect(PassportAssurance.fromJson(null), PassportAssurance.unrecognised);
      // Both wire forms of the real values still map.
      expect(PassportAssurance.fromJson(2), PassportAssurance.verified);
      expect(
        PassportAssurance.fromJson('Verified'),
        PassportAssurance.verified,
      );
    });

    testWidgets('an unknown assurance renders as unchecked and attributed', (
      tester,
    ) async {
      await _pump(
        tester,
        _passport(
          claims: [
            _claim(
              assurance: PassportAssurance.unrecognised,
              assuranceLabel: 'A label from a newer server.',
              presentAsFact: false,
            ),
          ],
        ),
      );

      final pill = tester.widget<MallStatusPill>(find.byType(MallStatusPill));
      expect(pill.tone, isNot(MallStatusTone.success));
      expect(_renderedText(tester), contains('Himalaya Handwork states:'));
      expect(
        _renderedText(tester),
        contains('A label from a newer server.'),
      );
    });
  });

  group('no score anywhere', () {
    testWidgets('nothing rendered grades the listing or the seller', (
      tester,
    ) async {
      await _pump(
        tester,
        _passport(
          claims: [
            _claim(
              assurance: PassportAssurance.verified,
              assuranceLabel: _verifiedLabel,
            ),
            _claim(
              assurance: PassportAssurance.recorded,
              assuranceLabel: _recordedLabel,
              kindLabel: 'Materials',
              statement: '100% wool.',
            ),
            _claim(
              assurance: PassportAssurance.verificationFailed,
              assuranceLabel: _failedLabel,
            ),
          ],
          coverage: const PassportCoverage(
            knownKinds: ['Origin', 'Materials'],
            unknownKinds: ['Warranty'],
            summary: _coverageSummary,
          ),
        ),
      );

      final text = _renderedText(tester).join(' ').toLowerCase();
      for (final banned in const [
        'score',
        'confidence',
        'authenticity rating',
        'trust level',
        'out of 10',
        '/5',
      ]) {
        expect(text, isNot(contains(banned)), reason: 'no grade may appear');
      }
    });
  });

  group('rendering', () {
    testWidgets('a v1 passport draws nothing new', (tester) async {
      await _pump(
        tester,
        const ProductPassport(
          vendorBusinessName: 'Himalaya Handwork',
          vendorIdentityVerified: true,
          vendorOnPlatformSince: null,
          authenticityStatement: 'Sold by a verified business.',
        ),
      );

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('semantics: every claim carries a spoken label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        _passport(
          claims: [
            _claim(
              assurance: PassportAssurance.recorded,
              assuranceLabel: _recordedLabel,
            ),
          ],
          coverage: const PassportCoverage(
            unknownKinds: ['Warranty'],
            summary: _coverageSummary,
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(RegExp('Recorded, and nobody has checked it')),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(RegExp('Not recorded: Warranty')),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('cannot tell which physical item was shipped'),
        ),
        findsWidgets,
      );
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
                child: PassportClaimsSection(
                  passport: _passport(
                    claims: [
                      _claim(
                        assurance: PassportAssurance.recorded,
                        assuranceLabel: _recordedLabel,
                      ),
                      _claim(
                        assurance: PassportAssurance.verificationFailed,
                        assuranceLabel: _failedLabel,
                      ),
                    ],
                    coverage: const PassportCoverage(
                      knownKinds: ['Origin'],
                      unknownKinds: [
                        'Authorised supply',
                        'Serial or batch number',
                        'Warranty',
                        'Care and handling',
                        'Recall or safety notice',
                      ],
                      summary: _coverageSummary,
                    ),
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
}
