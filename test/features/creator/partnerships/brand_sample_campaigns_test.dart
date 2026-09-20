import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/datasources/brands_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_info_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/widgets/brand_partnership_record_panel.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/widgets/brand_partnership_record_view.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';

import '../../codes/support/recording_api_client.dart';

/// **Every brand was shown the same three Nike campaigns.**
///
/// `_SampleCampaignsTab` on `brand_info_screen.dart` held a `static const`
/// list of three campaigns — 'Nike Zoom Series: Athlete Sprint Edition',
/// 'Nike Tech Fleece Jacket. Athlete Style for Every Age' and 'Air Max
/// Collection: Street to Stadium' — each with a reel count and a
/// creator-collab count. None of it came from anywhere, and it rendered
/// identically for every brand, so a creator weighing up a small Nepali
/// vendor read Nike's campaigns as that vendor's, with six invented
/// engagement figures beside them.
///
/// The sibling screen `brand_detail_screen.dart` had a version that *looked*
/// sourced: it fetched `GET /v1/partnerships/{id}/campaigns` into a
/// `SampleCampaignDto`. That route does not exist in lead360, so the call
/// 404'd on every open and the tab read "Couldn't load campaigns." forever.
/// A fabrication and a permanent error are the same bug seen from two sides:
/// the screen claims the platform has campaign data.
///
/// These tests are written against the **shape** of the defect rather than
/// against one widget tree, so it cannot return through a different screen.

// ── Source scanning ──────────────────────────────────────────────────────────

const String _featureDir = 'lib/features/creator/partnerships';

/// Source of every `.dart` file in the partnerships feature, comments
/// stripped.
///
/// The bans below are about what the app **reads and renders**, never about
/// what a comment may explain. The files that deleted these tabs name the
/// campaign titles in prose so the next reader knows exactly what was
/// removed and why; that prose must not fail the guard that keeps it gone.
/// Stripping is deliberately crude — a `//` inside a string literal
/// truncates that line — which can only ever hide a match, never invent
/// one, and no banned phrase below lives on a line with a URL.
Map<String, String> _featureCode() {
  final lineComment = RegExp('//.*');
  final blockComment = RegExp(r'/\*.*?\*/', dotAll: true);
  final out = <String, String>{};
  for (final entity in Directory(_featureDir).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    out[entity.path.replaceAll(r'\', '/')] = entity
        .readAsStringSync()
        .replaceAll(blockComment, '')
        .replaceAll(lineComment, '');
  }
  return out;
}

// ── Widget harness ───────────────────────────────────────────────────────────

const _seed = BrandInfoData(
  name: 'Hamro Pasal',
  logoUrl: null,
  commissionMinPercent: 8,
  commissionMaxPercent: 14,
  vendorAccountId: 'acct-7',
);

/// A real approved-vendor profile for a brand that has done nothing yet.
Map<String, dynamic> _brandDetailJson() => <String, dynamic>{
  'id': 'vp-7',
  'accountId': 'acct-7',
  'businessName': 'Hamro Pasal',
  'businessType': 2,
  'commissionRangeMin': 0.08,
  'commissionRangeMax': 0.14,
  'description': null,
  'logoUrl': null,
  'websiteUrl': null,
};

/// A partnership record with no history at all — the state a brand new to
/// the platform is in, and the one the removed tabs used to paper over.
Map<String, dynamic> _blankRecordJson() => <String, dynamic>{
  'vendorProfileId': 'vp-7',
  'windowDays': 180,
  'windowStartUtc': '2026-03-23T00:00:00+00:00',
  'windowEndUtc': '2026-09-19T00:00:00+00:00',
  'observedUtc': '2026-09-19T09:15:00+00:00',
  'minimumObservations': 5,
  'messagingRecordAvailable': true,
  'counts': <String, dynamic>{
    'partnershipsAllTime': 0,
    'activeNow': 0,
    'startedInWindow': 0,
    'endedInWindow': 0,
    'endedByBrandInWindow': 0,
    'endedByCreatorInWindow': 0,
    'creatorRequestsReceivedInWindow': 0,
    'creatorRequestsAnsweredInWindow': 0,
    'creatorChatsOpenedInWindow': 0,
    'creatorChatsRepliedInWindow': 0,
  },
  'creatorChatsReplied': null,
  'creatorRequestsAnswered': null,
};

Future<void> _pumpScreen(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  BrandInfoData seed = _seed,
  Object? Function(RecordedCall call)? respond,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final client = RecordingApiClient(
    respond ??
        (call) {
          if (call.uri == '/v1/brands/acct-7') return _brandDetailJson();
          if (call.uri == '/v1/creator/brands/vp-7/partnership-record') {
            return _blankRecordJson();
          }
          return dioError(404, path: call.uri);
        },
  );

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => BrandInfoScreen(data: seed),
      ),
      GoRoute(
        path: '/creator/partnerships/:partnershipId/apply',
        builder: (_, _) => const Scaffold(body: Text('apply screen')),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        brandsRemoteDataSourceProvider.overrideWithValue(
          BrandsRemoteDataSource(apiClient: client),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every string the screen actually put on screen, plus every spoken label —
/// a fabricated figure whispered to a screen reader is still fabricated.
List<String> _allText(WidgetTester tester) => [
  ...tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? ''),
  ...tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((s) => s.properties.label ?? ''),
].where((s) => s.isNotEmpty).toList();

void main() {
  // ── The fabricated campaigns are gone from the source ──────────────────────

  group('no invented campaign survives in the feature', () {
    test('no brand name is hardcoded anywhere in the feature', () {
      // The three campaigns named two brands StyleMint has no relationship
      // with. A brand name in this feature's source can only ever be a
      // fabrication: every real one arrives from `GET /v1/brands`,
      // `GET /v1/brands/{id}` or `GET /v1/partnerships/{id}` at runtime.
      const banned = <String>[
        'Nike',
        'Air Max',
        'Zoom Series',
        'Tech Fleece',
        'Adidas',
        'Puma',
      ];
      final offenders = <String>[];
      _featureCode().forEach((path, code) {
        for (final name in banned) {
          if (code.contains(name)) offenders.add('$path: $name');
        }
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no campaign list, DTO or tab is left to render one', () {
      // Every identifier that carried the fabrication, on both screens.
      // `SampleCampaignDto` is included because a DTO documented against a
      // route that does not exist is what made the sibling screen look
      // sourced when it was not.
      const banned = <String>[
        'SampleCampaignDto',
        '_SampleCampaignsTab',
        'Sample Campaigns',
        'sampleCampaign',
        'creatorCollabCount',
        'reelCount',
        'Creator Collabs',
        '/campaigns',
      ];
      final offenders = <String>[];
      _featureCode().forEach((path, code) {
        for (final token in banned) {
          if (code.contains(token)) offenders.add('$path: $token');
        }
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('no invented count is hardcoded in the feature', () {
      // '5.8k', '2.7k', '4.1k' reels and '269', '345', '512' collabs. The
      // pattern, not the literals: a bare abbreviated count or a bare
      // three-digit total in a string literal has no denominator and no
      // source, which is the shape every fabricated figure on this screen
      // has taken.
      final abbreviated = RegExp(r"'\d+(\.\d+)?k'");
      final bareCount = RegExp(r"'\d{2,}'\s*,");
      final offenders = <String>[];
      _featureCode().forEach((path, code) {
        for (final match in abbreviated.allMatches(code)) {
          offenders.add('$path: ${match.group(0)}');
        }
        for (final match in bareCount.allMatches(code)) {
          offenders.add('$path: ${match.group(0)}');
        }
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the guard has teeth', () {
      // If the comment stripper ever ate the whole file, every ban above
      // would pass vacuously. Prove it still sees real code, and that it
      // does strip the prose that documents the removal.
      final code = _featureCode();
      expect(code, isNotEmpty);
      expect(
        code['$_featureDir/presentation/screens/brand_info_screen.dart'],
        contains('class BrandInfoScreen'),
      );
      // The prose below the strip names the campaigns; the stripped source
      // must not.
      expect(
        File(
          '$_featureDir/presentation/screens/brand_info_screen.dart',
        ).readAsStringSync(),
        contains('Nike'),
        reason: 'the record of what was removed should stay in the file',
      );
    });
  });

  // ── The fabricated partnership terms are gone too ──────────────────────────

  group('no invented partnership terms survive on the brand info screen', () {
    test('no hardcoded eligibility rule or content rule is left', () {
      // The Partnership Terms tab on `brand_info_screen.dart` was two cards
      // of hardcoded bullets, identical for every brand. Terms on StyleMint
      // are authored per partnership by the vendor (`PublishTermsVm`), read
      // back at `GET /v1/partnerships/{id}/terms/active` — so they are keyed
      // by a partnership id, which a creator deciding whether to apply does
      // not have. An invented follower threshold is worse than none: it can
      // talk a creator out of applying.
      const banned = <String>[
        'engaged followers',
        'policy violations',
        'first 3 seconds',
        'minimum 15s',
        'candid framing',
        'comparative claims',
      ];
      final code =
          _featureCode()['$_featureDir/presentation/screens/'
              'brand_info_screen.dart']!;
      for (final phrase in banned) {
        expect(code, isNot(contains(phrase)), reason: phrase);
      }
    });

    test('brand_detail_screen keeps its terms tab, which is real', () {
      // Not a fabrication there: the partnership id is in hand and the
      // terms are the vendor's own. Deleting it would be over-correction.
      final code =
          _featureCode()['$_featureDir/presentation/screens/'
              'brand_detail_screen.dart']!;
      expect(code, contains('partnershipTermsProvider'));
      expect(code, contains('Partnership Terms'));
    });
  });

  // ── Parsed fields must have readers ────────────────────────────────────────

  group('no figure is parsed without a reader', () {
    test('successRatePercent and avgOrderValue are parsed nowhere', () {
      // Neither exists on the backend's `PartnershipDto`, so
      // `GET /v1/partnerships/{id}` never sent either and both read null on
      // every response. "Success Rate with Creators" is exactly the figure
      // that rendered "0%" for every brand on this screen, and it got there
      // because a field was parsed before anything measured it.
      final offenders = <String>[];
      for (final dir in ['lib', 'test']) {
        for (final entity in Directory(dir).listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          final path = entity.path.replaceAll(r'\', '/');
          if (path.endsWith('brand_sample_campaigns_test.dart')) continue;
          final code = entity
              .readAsStringSync()
              .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
              .replaceAll(RegExp('//.*'), '');
          for (final field in ['successRatePercent', 'avgOrderValue']) {
            if (code.contains(field)) offenders.add('$path: $field');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('a PartnershipDetailDto built from a rich payload drops them', () {
      // Even when a server starts sending them — the JSON shape is not ours
      // to control — nothing in the app can pick them up.
      final dto = PartnershipDetailDto.fromJson(<String, dynamic>{
        'id': 'p-1',
        'vendorProfileId': 'vp-7',
        'state': 3,
        'commissionMinPercent': 8.0,
        'commissionMaxPercent': 14.0,
        'vendorName': 'Hamro Pasal',
        'vendorRating': 4.2,
        'avgOrderValue': 12899.98,
        'successRatePercent': 97.0,
      });

      expect(dto.vendorName, 'Hamro Pasal');
      expect(dto.stateLabel, 'Active');
      // Kept: a real property of the backend DTO, joined at read time by
      // `CatalogVendorRatingProvider` from Catalog's weighted product-review
      // rollup, and read by three screens.
      expect(dto.vendorRating, 4.2);
      expect(
        dto.toString(),
        isNot(contains('97')),
        reason: 'the success rate must not survive anywhere on the object',
      );
    });

    test('vendorRating is kept only because something reads it', () {
      // The rule this group enforces is "no parsed field without a reader",
      // not "no rating". If the last reader ever goes, this fails and the
      // parsing must go with it.
      final readers = <String>[];
      _featureCode().forEach((path, code) {
        if (path.endsWith('brand_detail_dto.dart')) return;
        if (code.contains('vendorRating')) readers.add(path);
      });
      expect(
        readers,
        isNotEmpty,
        reason:
            'nothing reads vendorRating any more — delete the parsing in '
            'brand_detail_dto.dart rather than leaving a sourceless figure '
            'one widget away from being rendered again',
      );
    });
  });

  // ── A missing rating is never a zero ───────────────────────────────────────

  group('no rating is defaulted to zero anywhere in the feature', () {
    test('no rating is filled in with a literal zero or a ?? 0', () {
      // Found while removing the campaigns: three cards on
      // `partnership_requests_screen.dart` drew "★ 0.0 Stars" for every
      // brand, because `_Request.rating` was a non-nullable double fed by
      // `vendorRating ?? 0` on the invite path and by a literal `0` on the
      // active path. Same shape as the retired trust score — a null read as
      // a zero — one screen over.
      final defaulted = RegExp(r'[Rr]ating\s*(\?\?\s*0|:\s*0\b)');
      final offenders = <String>[];
      _featureCode().forEach((path, code) {
        for (final match in defaulted.allMatches(code)) {
          offenders.add('$path: ${match.group(0)}');
        }
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('every rating the feature holds is nullable', () {
      // A non-nullable rating field has to be given something when there is
      // nothing, and "something" is always a zero.
      final nonNullable = RegExp(r'(final|required)\s+double\s+\w*[Rr]ating');
      final offenders = <String>[];
      _featureCode().forEach((path, code) {
        for (final match in nonNullable.allMatches(code)) {
          offenders.add('$path: ${match.group(0)}');
        }
      });
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('the chat header carries no rating at all', () {
      // `BrandMessagingArgs.rating` was required, always passed as 0 or
      // `?? 0`, and printed in the header subtitle whenever the category
      // was non-empty — which no caller made it. A dormant "0.0 • …".
      final code =
          _featureCode()['$_featureDir/presentation/screens/'
              'brand_messaging_screen.dart']!;
      expect(code, isNot(contains('rating')));
    });
  });

  // ── The app never draws a brand mark it invented ───────────────────────────

  group('no brand mark is forged', () {
    test('the request card draws no name-matched glyph', () {
      // `_BrandLogo` drew a bold '✓' for any brand whose lowercased name
      // *contained* "nike" and a bold 'S' for one containing "sephora" —
      // the app forging a mark for two companies StyleMint has no
      // relationship with, and by substring, so "Nikesh Traders" would have
      // been given a swoosh stand-in too.
      final code =
          _featureCode()['$_featureDir/presentation/screens/'
              'partnership_requests_screen.dart']!;
      expect(code, isNot(contains('sephora')));
      expect(code, isNot(contains('nike')));
      expect(code, isNot(contains("'✓'")));
      // What is left is the brand's own initial.
      expect(code, contains('toUpperCase()'));
    });
  });

  // ── What the screen shows a brand with no data ─────────────────────────────

  group('the brand info screen renders honestly with no data', () {
    testWidgets('only the two tabs that can be sourced are offered', (
      tester,
    ) async {
      await _pumpScreen(tester);

      expect(find.text('Partnership Record'), findsOneWidget);
      expect(find.text('Top Products'), findsOneWidget);
      expect(find.text('Sample Campaigns'), findsNothing);
      expect(find.text('Partnership Terms'), findsNothing);
      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('no campaign, reel count or collab count is spoken or drawn', (
      tester,
    ) async {
      await _pumpScreen(tester);

      final shown = _allText(tester).join('\n');
      for (final phrase in [
        'Nike',
        'Air Max',
        'Reels',
        'Creator Collabs',
        'Success Rate',
      ]) {
        expect(shown, isNot(contains(phrase)), reason: phrase);
      }
    });

    testWidgets('the screen states no campaign absence it cannot know', (
      tester,
    ) async {
      // An empty "No sample campaigns yet" would be a claim: that this
      // brand has run none. The platform holds nothing either way, so the
      // honest reading is that the platform holds nothing — the tab is
      // gone, not emptied.
      await _pumpScreen(tester);

      final shown = _allText(tester).join('\n').toLowerCase();
      expect(shown, isNot(contains('campaign')));
    });

    testWidgets('the partnership record panel still renders as before', (
      tester,
    ) async {
      await _pumpScreen(tester);

      expect(find.byType(BrandPartnershipRecordPanel), findsOneWidget);
      expect(find.byType(BrandPartnershipRecordView), findsOneWidget);
    });

    testWidgets('the record is still keyed by the resolved profile id', (
      tester,
    ) async {
      // The catalog card carries the vendor ACCOUNT id; the record is keyed
      // by the PROFILE id, resolved through the brand detail response.
      // Removing two tabs must not disturb that.
      final calls = <String>[];
      await _pumpScreen(
        tester,
        respond: (call) {
          calls.add(call.uri);
          if (call.uri == '/v1/brands/acct-7') return _brandDetailJson();
          if (call.uri == '/v1/creator/brands/vp-7/partnership-record') {
            return _blankRecordJson();
          }
          return dioError(404, path: call.uri);
        },
      );

      expect(
        calls,
        containsAll(<String>[
          '/v1/brands/acct-7',
          '/v1/creator/brands/vp-7/partnership-record',
        ]),
      );
      expect(find.byType(BrandPartnershipRecordView), findsOneWidget);
      expect(
        calls.where((c) => c.contains('campaign')),
        isEmpty,
        reason: 'the screen must not ask for campaigns any more',
      );
    });
  });

  // ── Accessibility ──────────────────────────────────────────────────────────

  group('accessibility', () {
    testWidgets('every tappable node is labelled and answers a tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpScreen(tester);

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

      walk(tester.getSemantics(find.byType(BrandInfoScreen)));

      expect(
        tappable,
        isNotEmpty,
        reason: 'the back button, the tabs and Apply are all controls',
      );
      for (final node in tappable) {
        final data = node.getSemanticsData();
        // A tooltip is announced in place of a label, so either will do —
        // what must never happen is a control that is silent.
        expect(
          data.label.isNotEmpty || data.tooltip.isNotEmpty,
          isTrue,
          reason: 'unlabelled tappable node: $data',
        );
      }

      handle.dispose();
    });

    testWidgets('the apply button is a labelled button that answers a tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpScreen(tester);

      final apply = tester.getSemantics(
        find.bySemanticsLabel('Apply for Partnership'),
      );
      final data = apply.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      await tester.tap(find.bySemanticsLabel('Apply for Partnership'));
      await tester.pumpAndSettle();
      expect(find.text('apply screen'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('an unavailable apply says so in a word and a glyph', (
      tester,
    ) async {
      // The disabled state used to be a 40%-alpha fill and nothing else.
      final handle = tester.ensureSemantics();
      await _pumpScreen(
        tester,
        seed: const BrandInfoData(
          name: 'Hamro Pasal',
          logoUrl: null,
          commissionMinPercent: 8,
          commissionMaxPercent: 14,
          vendorAccountId: '',
        ),
        respond: (call) => dioError(404, path: call.uri),
      );

      expect(find.text('Apply unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      final apply = tester.getSemantics(
        find.textContaining('Apply unavailable'),
      );
      expect(
        apply.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );

      handle.dispose();
    });

    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      for (final seed in <BrandInfoData>[
        _seed,
        const BrandInfoData(
          name: 'Kathmandu Handloom and Pashmina Collective',
          logoUrl: null,
          commissionMinPercent: 8,
          commissionMaxPercent: 14,
          vendorAccountId: 'acct-7',
        ),
        const BrandInfoData(
          name: '',
          logoUrl: null,
          commissionMinPercent: 0,
          commissionMaxPercent: 0,
          vendorAccountId: '',
        ),
      ]) {
        await _pumpScreen(
          tester,
          seed: seed,
          size: const Size(320, 640),
          textScale: 1.3,
        );
        expect(tester.takeException(), isNull);

        // And on the second tab, which is where the other tab bodies used
        // to be. The tab bar is scrollable, so at 320dp the second tab
        // starts off-screen.
        final products = find.text('Top Products');
        if (products.evaluate().isNotEmpty) {
          await tester.ensureVisible(products);
          await tester.pumpAndSettle();
          await tester.tap(products);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });
  });
}
