import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/datasources/brands_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/widgets/brand_partnership_record_panel.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/widgets/brand_partnership_record_view.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';

import '../../codes/support/recording_api_client.dart';

/// **Every brand on StyleMint was shown a 0.0 star rating and "Success Rate
/// with Creators: 0%".**
///
/// The server built a brand's "trust score" from five hardcoded constants
/// and the recalculation that used them had no caller, so the row every
/// brand served was `score: 0`, `tier: New`, components `0`. This app drew
/// that as a rating and a success rate. Nothing threw — `required` binds a
/// Dart constructor and not the JSON, and `fromJson` filled every field with
/// `?? 0` — so the app quietly published a false statement about every
/// business on the platform.
///
/// These tests are written against the shape of that defect rather than
/// against the widget tree, so the same class of mistake cannot come back
/// through a different screen: a figure with no denominator, a null read as
/// a zero, a verdict where a fact belongs.

// ── Fixtures ─────────────────────────────────────────────────────────────────

const String _chatsStatement =
    'Replied in 9 of 12 partnership chats a creator wrote in, in the 180 '
    'days to 2026-09-19.';
const String _requestsStatement =
    'Answered 6 of 8 partnership requests from creators in the 180 days to '
    '2026-09-19.';

/// The full payload, with both rates measured.
Map<String, dynamic> _measuredJson() => <String, dynamic>{
  'vendorProfileId': 'vp-7',
  'windowDays': 180,
  'windowStartUtc': '2026-03-23T00:00:00+00:00',
  'windowEndUtc': '2026-09-19T00:00:00+00:00',
  'observedUtc': '2026-09-19T09:15:00+00:00',
  'minimumObservations': 5,
  'messagingRecordAvailable': true,
  'counts': <String, dynamic>{
    'partnershipsAllTime': 31,
    'activeNow': 4,
    'startedInWindow': 11,
    'endedInWindow': 7,
    'endedByBrandInWindow': 3,
    'endedByCreatorInWindow': 2,
    'creatorRequestsReceivedInWindow': 8,
    'creatorRequestsAnsweredInWindow': 6,
    'creatorChatsOpenedInWindow': 12,
    'creatorChatsRepliedInWindow': 9,
  },
  'creatorChatsReplied': <String, dynamic>{
    'observed': 9,
    'of': 12,
    'percent': 75.0,
    'windowDays': 180,
    'windowStartUtc': '2026-03-23T00:00:00+00:00',
    'windowEndUtc': '2026-09-19T00:00:00+00:00',
    'statement': _chatsStatement,
  },
  'creatorRequestsAnswered': <String, dynamic>{
    'observed': 6,
    'of': 8,
    'percent': 75.0,
    'windowDays': 180,
    'windowStartUtc': '2026-03-23T00:00:00+00:00',
    'windowEndUtc': '2026-09-19T00:00:00+00:00',
    'statement': _requestsStatement,
  },
};

/// A thin record: real rows, but under the server's minimum on both rates,
/// so both arrive null and only the counts ship. This is the shape that
/// used to render "0%".
Map<String, dynamic> _thinJson() => <String, dynamic>{
  'vendorProfileId': 'vp-8',
  'windowDays': 180,
  'windowStartUtc': '2026-03-23T00:00:00+00:00',
  'windowEndUtc': '2026-09-19T00:00:00+00:00',
  'observedUtc': '2026-09-19T09:15:00+00:00',
  'minimumObservations': 5,
  'messagingRecordAvailable': true,
  'counts': <String, dynamic>{
    'partnershipsAllTime': 3,
    'activeNow': 1,
    'startedInWindow': 2,
    'endedInWindow': 1,
    'endedByBrandInWindow': 1,
    'endedByCreatorInWindow': 0,
    'creatorRequestsReceivedInWindow': 2,
    'creatorRequestsAnsweredInWindow': 0,
    'creatorChatsOpenedInWindow': 2,
    'creatorChatsRepliedInWindow': 0,
  },
  'creatorChatsReplied': null,
  'creatorRequestsAnswered': null,
};

/// Real partnership rows, but the messaging record could not be read at all.
/// Unknown is not zero, and has to read differently from a brand that
/// replied to nobody.
Map<String, dynamic> _messagingUnknownJson() => <String, dynamic>{
  ..._measuredJson(),
  'messagingRecordAvailable': false,
  'creatorChatsReplied': null,
};

/// A brand StyleMint has recorded nothing about.
Map<String, dynamic> _blankJson() => <String, dynamic>{
  'vendorProfileId': 'vp-9',
  'windowDays': 180,
  'windowStartUtc': '2026-03-23T00:00:00+00:00',
  'windowEndUtc': '2026-09-19T00:00:00+00:00',
  'observedUtc': '2026-09-19T09:15:00+00:00',
  'minimumObservations': 5,
  'messagingRecordAvailable': true,
  'counts': const <String, dynamic>{},
};

Map<String, dynamic> _brandDetailJson() => <String, dynamic>{
  // `id` is the vendor PROFILE id; `accountId` is what the catalog card
  // carries and what this endpoint is addressed by. The record must be
  // fetched with the former.
  'id': 'vp-7',
  'accountId': 'acct-7',
  'businessName': 'Himal Supply Co.',
  'businessType': 4,
  'commissionRangeMin': 0.1,
  'commissionRangeMax': 0.2,
};

// ── Harness ──────────────────────────────────────────────────────────────────

Widget _host(Widget child, {double textScale = 1}) => MediaQuery(
  data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
  child: MaterialApp(home: Scaffold(body: child)),
);

Future<void> _pumpView(
  WidgetTester tester,
  Map<String, dynamic> json, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _host(
      BrandPartnershipRecordView(
        record: BrandPartnershipRecordDto.fromJson(json),
      ),
      textScale: textScale,
    ),
  );
  await tester.pump();
}

/// Every string the view actually put on screen.
List<String> _renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((s) => s.isNotEmpty)
    .toList();

/// Rendered text plus every spoken label, because a verdict whispered to a
/// screen reader is still a verdict.
List<String> _allText(WidgetTester tester) => [
  ..._renderedText(tester),
  ...tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((s) => s.properties.label ?? '')
      .where((s) => s.isNotEmpty),
];

/// Files inside the partnerships feature that may say "tier", and why.
///
/// All of them are the **creator's own rate card** — the price bands a
/// creator publishes for their own work. That is the creator grading their
/// rates, not StyleMint grading a brand, which is the thing the retired
/// `TrustTier` did and the thing this feature must never do again.
const Map<String, String> _tierExemptions = <String, String>{
  'lib/features/creator/partnerships/domain/entities/rate_card.dart':
      "The creator's own rate tiers (RateTier, tierName).",
  'lib/features/creator/partnerships/domain/repositories/partnerships_repository.dart':
      'Passes the rate card through.',
  'lib/features/creator/partnerships/data/repositories/partnerships_repository_impl.dart':
      'Passes the rate card through.',
  'lib/features/creator/partnerships/data/datasources/partnerships_remote_datasource.dart':
      "Posts the creator's own rate tiers.",
  'lib/features/creator/partnerships/presentation/screens/rate_card_screen.dart':
      'The creator edits their own rate tiers here.',
  'lib/features/creator/partnerships/shared/providers.dart':
      're-exports RateTier for the rate card screen.',
};

/// Source of every `.dart` file under `lib/`, with comments stripped.
///
/// The bans below are about what the app **reads and renders**, not about
/// what a comment may explain. The files that deleted the trust contract
/// name it in prose so the next reader knows why it is gone; that prose
/// must not fail the guard that keeps it gone. Stripping is deliberately
/// crude — a `//` inside a string literal truncates that line — which can
/// only ever hide a match, and no banned identifier here lives on a line
/// with a URL.
Map<String, String> _libCode() {
  final lineComment = RegExp('//.*');
  final blockComment = RegExp(r'/\*.*?\*/', dotAll: true);
  final out = <String, String>{};
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    out[entity.path.replaceAll(r'\', '/')] = entity
        .readAsStringSync()
        .replaceAll(blockComment, '')
        .replaceAll(lineComment, '');
  }
  return out;
}

void main() {
  // ── The retired contract is gone from the source, not just unused ──────────

  group('the trust contract is gone', () {
    test('no file in lib/ reads a trust score, a tier or their companions', () {
      // `trustScore` / `score` never had a source; `tier` was derived from
      // it; `totalCampaignValue` and `verifiedByCount` were columns nothing
      // ever wrote. The four component names are the ones with no data
      // source anywhere on the platform — brand→creator payment is never
      // recorded, nothing rates a brief, no creator rates a brand, and
      // there is no "completed" partnership outcome.
      const banned = <String>[
        'BrandTrustDto',
        'brandTrustProvider',
        'getBrandTrust',
        'trustScore',
        'TrustTier',
        'tierLabel',
        'totalCampaignValue',
        'verifiedByCount',
        'partnershipCompletionRate',
        'paymentReliability',
        'briefQuality',
        'creatorSatisfaction',
        'communicationResponseRate',
      ];

      final offenders = <String, List<String>>{};
      _libCode().forEach((path, code) {
        final hits = banned.where(code.contains).toList();
        if (hits.isNotEmpty) offenders[path] = hits;
      });

      expect(
        offenders,
        isEmpty,
        reason:
            'These names belong to the retired brand-trust contract, which '
            'served every brand a zero. Nothing in lib/ may read them again.',
      );
    });

    test('nothing in the partnerships feature ranks a brand into a tier', () {
      // The ban is on ranking a *brand*, so it is scoped to the feature
      // that owned the brand trust tier rather than to the word everywhere
      // — the app has unrelated tier surfaces, and one of them lives right
      // here. Each carve-out names the file and its reason, and is checked
      // for existence below so it cannot quietly outlive the code.
      final offenders = <String, int>{};
      _libCode().forEach((path, code) {
        if (!path.contains('features/creator/partnerships/')) return;
        if (_tierExemptions.keys.any(path.endsWith)) return;
        final hits = RegExp('tier', caseSensitive: false).allMatches(code);
        if (hits.isNotEmpty) offenders[path] = hits.length;
      });

      expect(offenders, isEmpty, reason: 'No brand is ranked into a tier.');
    });

    test('every tier carve-out still points at real code', () {
      for (final path in _tierExemptions.keys) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path no longer exists — drop the carve-out',
        );
      }
    });

    test('nothing calls the retired brand trust route', () {
      final route = RegExp(r'brands/[^\x27]*?/trust');
      final offenders = <String>[];
      _libCode().forEach((path, code) {
        if (route.hasMatch(code)) offenders.add(path);
      });
      expect(offenders, isEmpty);
    });
  });

  // ── The wire contract ─────────────────────────────────────────────────────

  group('the record parses honestly', () {
    test('a measured payload keeps its figures and its sentence', () {
      final record = BrandPartnershipRecordDto.fromJson(_measuredJson());

      expect(record.vendorProfileId, 'vp-7');
      expect(record.windowDays, 180);
      expect(record.minimumObservations, 5);
      expect(record.counts.activeNow, 4);
      expect(record.counts.partnershipsAllTime, 31);

      final chats = record.creatorChatsReplied!;
      expect(chats.observed, 9);
      expect(chats.of, 12);
      expect(chats.fraction, '9 of 12');
      expect(chats.statement, _chatsStatement);
      expect(chats.windowDays, 180);
      expect(chats.windowEndUtc, DateTime.utc(2026, 9, 19));
    });

    test('a rate with no denominator is never built', () {
      // The server withholds a rate below its minimum. A malformed zero
      // denominator must not become a division either — that is the exact
      // arithmetic behind "0%".
      for (final of in <Object?>[0, null, '', -3]) {
        final rate = MeasuredRateDto.tryFromJson(<String, dynamic>{
          'observed': 0,
          'of': of,
          'statement': 'nonsense',
        });
        expect(rate, isNull, reason: 'denominator $of must yield no rate');
      }
    });

    test('a numerator larger than its denominator yields no rate', () {
      final rate = MeasuredRateDto.tryFromJson(const <String, dynamic>{
        'observed': 13,
        'of': 12,
      });
      expect(rate, isNull);
    });

    test('an unreadable messaging record cannot surface as a reply rate', () {
      // Unknown is not zero, and a payload that contradicts itself is
      // resolved towards saying less about the brand, never more.
      final record = BrandPartnershipRecordDto.fromJson(<String, dynamic>{
        ..._measuredJson(),
        'messagingRecordAvailable': false,
      });
      expect(record.creatorChatsReplied, isNull);
      expect(record.messagingRecordAvailable, isFalse);
      // The request rate has its own source and is unaffected.
      expect(record.creatorRequestsAnswered, isNotNull);
    });

    test('unknown future fields are ignored rather than fatal', () {
      final record = BrandPartnershipRecordDto.fromJson(<String, dynamic>{
        ..._measuredJson(),
        'brandSentimentIndex': 88,
        'nested': <String, dynamic>{'anything': true},
        'counts': <String, dynamic>{
          ..._measuredJson()['counts']! as Map<String, dynamic>,
          'disputesRaisedInWindow': 2,
        },
        'creatorChatsReplied': <String, dynamic>{
          ..._measuredJson()['creatorChatsReplied']! as Map<String, dynamic>,
          'medianReplyMinutes': 41,
        },
      });

      expect(record.counts.activeNow, 4);
      expect(record.creatorChatsReplied?.fraction, '9 of 12');
    });

    test('a missing or wrongly typed payload reads as nothing recorded', () {
      final record = BrandPartnershipRecordDto.fromJson(const <String, dynamic>{
        'counts': <String, dynamic>{'activeNow': null, 'endedInWindow': 'x'},
        'creatorChatsReplied': 'not an object',
        'creatorRequestsAnswered': 42,
      });

      expect(record.hasNoRecord, isTrue);
      expect(record.creatorChatsReplied, isNull);
      expect(record.creatorRequestsAnswered, isNull);
      expect(record.windowDays, 0);
    });

    test('numeric counts sent as strings still count', () {
      final record = BrandPartnershipRecordDto.fromJson(const <String, dynamic>{
        'counts': <String, dynamic>{'activeNow': '5', 'partnershipsAllTime': 9},
      });
      expect(record.counts.activeNow, 5);
      expect(record.hasNoRecord, isFalse);
    });
  });

  // ── What the screen draws ─────────────────────────────────────────────────

  group('the view states facts, never a verdict', () {
    testWidgets('a measured rate shows its sentence verbatim', (tester) async {
      await _pumpView(tester, _measuredJson());

      // Not paraphrased, not re-templated, not truncated. The sentence was
      // written to be exact; rephrasing is how a number becomes a verdict.
      expect(find.text(_chatsStatement), findsOneWidget);
      expect(find.text(_requestsStatement), findsOneWidget);
    });

    testWidgets('a rate never appears without its denominator', (tester) async {
      await _pumpView(tester, _measuredJson());

      expect(find.text('9 of 12'), findsOneWidget);
      expect(find.text('6 of 8'), findsOneWidget);

      // And no bare percentage anywhere: the fraction and the sentence say
      // everything a percent sign would, without inviting the misread.
      for (final text in _renderedText(tester)) {
        expect(text, isNot(contains('%')), reason: 'rendered: $text');
      }
    });

    testWidgets('a null rate renders a dash and its count, never 0%', (
      tester,
    ) async {
      await _pumpView(tester, _thinJson());

      final rendered = _renderedText(tester);
      for (final text in rendered) {
        expect(text, isNot(contains('%')), reason: 'rendered: $text');
      }

      // The dash stands where a figure would, and the count that was too
      // thin to divide by is still shown, so a creator can see how little
      // there is rather than being told a number.
      expect(find.text('--'), findsNWidgets(2));
      expect(
        rendered.where((t) => t.contains('A rate needs at least 5')).length,
        2,
      );
      expect(find.text('Too few to rate'), findsNWidgets(2));
    });

    testWidgets('an unreadable record reads as unknown, not as zero', (
      tester,
    ) async {
      await _pumpView(tester, _messagingUnknownJson());

      expect(find.text('Not recorded'), findsOneWidget);
      expect(
        _renderedText(
          tester,
        ).any((t) => t.contains('unknown rather than zero')),
        isTrue,
      );
      for (final text in _renderedText(tester)) {
        expect(text, isNot(contains('%')));
      }
    });

    testWidgets('a brand with no history gets the calm empty state', (
      tester,
    ) async {
      await _pumpView(tester, _blankJson());

      expect(find.text('Nothing recorded yet'), findsOneWidget);

      // Not a wall of zeros standing in for facts, and not a finding
      // against the brand either.
      final rendered = _renderedText(tester);
      expect(rendered.any((t) => t.trim() == '0'), isFalse);
      expect(find.text('--'), findsNothing);
      for (final text in rendered) {
        expect(text, isNot(contains('%')));
      }
    });

    testWidgets('no judgement vocabulary in any state', (tester) async {
      // This is shown to creators about other people's businesses. A low
      // count is something a creator weighs, not something this app
      // accuses a brand of.
      final banned = RegExp(
        'risk|poor|bad|unreliable|avoid|warning|low trust',
        caseSensitive: false,
      );

      for (final json in [
        _measuredJson(),
        _thinJson(),
        _messagingUnknownJson(),
        _blankJson(),
      ]) {
        await _pumpView(tester, json);
        for (final text in _allText(tester)) {
          expect(text, isNot(matches(banned)), reason: 'said: $text');
        }
      }
    });

    testWidgets('the method note expands and collapses', (tester) async {
      await _pumpView(tester, _measuredJson());

      const note = 'How these figures are counted';
      expect(find.text(note), findsOneWidget);
      expect(find.textContaining('Nothing is estimated.'), findsNothing);

      await tester.ensureVisible(find.text(note));
      await tester.pumpAndSettle();
      await tester.tap(find.text(note));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nothing is estimated.'), findsOneWidget);
      expect(
        find.textContaining('The window is the 180 days to 2026-09-19.'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text(note));
      await tester.pumpAndSettle();
      await tester.tap(find.text(note));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nothing is estimated.'), findsNothing);
    });
  });

  // ── Reachable and readable ────────────────────────────────────────────────

  group('accessibility', () {
    testWidgets('every tappable node is labelled and answers a tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpView(tester, _measuredJson());

      final tappable = <SemanticsNode>[];
      void walk(SemanticsNode node) {
        if (node.getSemanticsData().hasAction(SemanticsAction.tap)) {
          tappable.add(node);
        }
        node.visitChildren((child) {
          walk(child);
          return true;
        });
      }

      walk(tester.getSemantics(find.byType(BrandPartnershipRecordView)));

      expect(tappable, isNotEmpty, reason: 'the method note is a control');
      for (final node in tappable) {
        expect(node.label, isNotEmpty, reason: 'unlabelled tappable node');
      }

      final disclosure = tester.getSemantics(
        find.text('How these figures are counted'),
      );
      final data = disclosure.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(disclosure.label, 'How these figures are counted');

      handle.dispose();
    });

    testWidgets('each rate is spoken with its figure and its sentence', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpView(tester, _measuredJson());

      final spoken = _allText(tester);
      expect(
        spoken.any(
          (s) =>
              s.contains('Replies in partnership chats') &&
              s.contains('9 of 12') &&
              s.contains(_chatsStatement),
        ),
        isTrue,
      );

      handle.dispose();
    });

    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      for (final json in [
        _measuredJson(),
        _thinJson(),
        _messagingUnknownJson(),
        _blankJson(),
      ]) {
        await _pumpView(
          tester,
          json,
          size: const Size(320, 640),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);

        // And with the method note open, which is the tallest the block
        // ever gets.
        final note = find.text('How these figures are counted');
        if (note.evaluate().isNotEmpty) {
          await tester.ensureVisible(note);
          await tester.pumpAndSettle();
          await tester.tap(note);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });
  });

  // ── Wiring ────────────────────────────────────────────────────────────────

  group('the panel asks the right endpoint for the right id', () {
    testWidgets('the record is keyed by the vendor profile id', (tester) async {
      // The catalog card carries the vendor ACCOUNT id. Partnerships are
      // keyed by the PROFILE id. The retired trust endpoint documented an
      // account id and created a row for whatever it was handed, so the
      // drift never surfaced; the panel now resolves one to the other
      // through the brand detail response.
      final client = RecordingApiClient((call) {
        if (call.uri == '/v1/brands/acct-7') return _brandDetailJson();
        if (call.uri == '/v1/creator/brands/vp-7/partnership-record') {
          return _measuredJson();
        }
        return dioError(404, path: call.uri);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            brandsRemoteDataSourceProvider.overrideWithValue(
              BrandsRemoteDataSource(apiClient: client),
            ),
          ],
          child: _host(
            const BrandPartnershipRecordPanel(vendorAccountId: 'acct-7'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        client.calls.map((c) => c.uri),
        containsAll(<String>[
          '/v1/brands/acct-7',
          '/v1/creator/brands/vp-7/partnership-record',
        ]),
      );
      expect(find.text(_chatsStatement), findsOneWidget);
    });

    test('the datasource calls the partnership-record route', () async {
      final client = RecordingApiClient((_) => _measuredJson());
      final source = BrandsRemoteDataSource(apiClient: client);

      final record = await source.getBrandPartnershipRecord('vp-7');

      expect(client.last.uri, '/v1/creator/brands/vp-7/partnership-record');
      expect(record.vendorProfileId, 'vp-7');
    });
  });
}
