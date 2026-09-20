import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/custody_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/custody_chain.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/custody_proof_export_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

/// Handing over the custody export — the buyer-facing endpoint that had zero
/// callers, reached now by a control rather than a screen.
///
/// The rule these tests exist for: a StyleMint seal is not third-party
/// verification, so no state of this sheet may read as "verified", and the
/// server's limitations are never absent.
class _FakeCustodyDataSource implements CustodyDataSource {
  _FakeCustodyDataSource(this._export);

  final CustodyProofExport? _export;
  final List<bool> bearerRequests = [];

  @override
  Future<CustodyProof?> fetch(String trackingNumber) async => null;

  @override
  Future<CustodyProofExport?> export(
    String trackingNumber, {
    required bool bearer,
  }) async {
    bearerRequests.add(bearer);
    return _export;
  }
}

/// `CustodyAttestationMeanings.SelfAttested`, verbatim — the best any chain
/// reaches today.
const String selfAttestedMeaning =
    'SELF-ATTESTED. StyleMint signed this chain root with its own key. Only '
    'StyleMint vouches for it. No independent party has attested to it and it '
    "is not committed to any medium outside StyleMint's control, so this seal "
    'does not protect you against StyleMint.';

const String coverageLimitation =
    'Fields listed under coverage.notCovered are bound by no hash or '
    'signature and can be changed without breaking verification. They are '
    'context, not evidence.';

const String selfAttestedLimitation =
    'Only StyleMint has signed this chain root. StyleMint could rewrite the '
    'chain and re-seal it, and this export would still verify. A seal from '
    'the party being audited is not independent evidence.';

Map<String, dynamic> _exportJson({
  String state = 'self_attested',
  String meaning = selfAttestedMeaning,
  List<String> limitations = const [
    coverageLimitation,
    selfAttestedLimitation,
  ],
  String disclosure = 'full',
}) => {
  'format': 'smcp/v1',
  'disclosureProfile': disclosure,
  'chainRoot': 'a3f1c9',
  'entries': [
    {'sequence': 0, 'payloadHash': 'aa', 'prevEntryHash': ''},
  ],
  'limitations': limitations,
  'attestation': {
    'state': state,
    'meaning': meaning,
    'attestedBy': <String>[],
  },
};

Future<void> _pumpSheet(
  WidgetTester tester,
  _FakeCustodyDataSource source, {
  double width = 320,
  double textScale = 1.3,
}) async {
  final surface = Size(width, 900);
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [custodyDataSourceProvider.overrideWithValue(source)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(
            size: surface,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: CustodyProofExportSheet(trackingNumber: 'SM-TRACK-7781'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the model', () {
    test('refuses an export that arrives with no limitations', () {
      // A proof with no caveats is not a stronger proof, it is a malformed
      // one — and it is the exact shape that reads as a guarantee.
      final export = CustodyProofExport.fromJson(
        _exportJson(limitations: const []),
        '{}',
      );

      expect(export, isNull);
    });

    test('refuses an export with no attestation sentence', () {
      final export = CustodyProofExport.fromJson(
        _exportJson(meaning: '   '),
        '{}',
      );

      expect(export, isNull);
    });

    test('does not treat a StyleMint seal as independent', () {
      final export = CustodyProofExport.fromJson(_exportJson(), '{}')!;

      expect(export.attestationState, 'self_attested');
      expect(export.hasIndependentAttestation, isFalse);
      expect(export.attestedBy, isEmpty);
    });

    test('does not treat an anchor as a counter-signature', () {
      // An anchor is a timestamp over a 32-byte digest by a party that never
      // saw the parcel. The server says so in capitals; the client agrees.
      final export = CustodyProofExport.fromJson(
        _exportJson(state: 'anchored'),
        '{}',
      )!;

      expect(export.hasIndependentAttestation, isFalse);
    });
  });

  group('the sheet', () {
    testWidgets('offers both disclosure profiles and preselects neither', (
      tester,
    ) async {
      final source = _FakeCustodyDataSource(
        CustodyProofExport.fromJson(_exportJson(), '{}'),
      );
      await _pumpSheet(tester, source);

      expect(find.text('Everything, for you'), findsOneWidget);
      expect(
        find.text('Sealed record only, safe for a stranger'),
        findsOneWidget,
      );
      // Nothing has been fetched, so nothing about the buyer's parcel has
      // been pulled to the device for a share nobody asked for.
      expect(source.bearerRequests, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('says plainly that the full copy carries the address', (
      tester,
    ) async {
      final source = _FakeCustodyDataSource(
        CustodyProofExport.fromJson(_exportJson(), '{}'),
      );
      await _pumpSheet(tester, source);

      expect(
        find.textContaining('The places include your delivery address.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the attestation and every limitation before sending', (
      tester,
    ) async {
      final source = _FakeCustodyDataSource(
        CustodyProofExport.fromJson(_exportJson(), '{}'),
      );
      await _pumpSheet(tester, source);
      final option = find.text('Sealed record only, safe for a stranger');
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();

      expect(source.bearerRequests, [true]);
      // The server's sentence, in no other form. Every shorter rendering of
      // "self_attested" reads as third-party verification.
      expect(find.text(selfAttestedMeaning), findsOneWidget);
      expect(find.text('• $coverageLimitation'), findsOneWidget);
      expect(find.text('• $selfAttestedLimitation'), findsOneWidget);
      expect(find.text('Send it'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('never renders the word verified in any state', (tester) async {
      final source = _FakeCustodyDataSource(
        CustodyProofExport.fromJson(_exportJson(), '{}'),
      );
      await _pumpSheet(tester, source);
      final option = find.text('Everything, for you');
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();

      // The only occurrence anywhere on this sheet is inside the server's own
      // limitation, which uses it to say the opposite: that a re-sealed chain
      // "would still verify" and is not independent evidence.
      final composed = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .where(
            (line) =>
                line != selfAttestedMeaning &&
                line != '• $coverageLimitation' &&
                line != '• $selfAttestedLimitation',
          );
      for (final line in composed) {
        expect(
          line.toLowerCase(),
          isNot(contains('verified')),
          reason: 'The sheet composed a verification claim: "$line"',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('says the request failed, not that the record is missing', (
      tester,
    ) async {
      final source = _FakeCustodyDataSource(null);
      await _pumpSheet(tester, source);
      final option = find.text('Everything, for you');
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pumpAndSettle();

      expect(
        find.text(CustodyProofExportSheet.unavailableNote),
        findsOneWidget,
      );
      // Nothing is offered to send, because nothing could be described.
      expect(find.text('Send it'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
