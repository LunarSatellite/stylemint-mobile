// Fixture builders read better inline than hoisted.
// ignore_for_file: lines_longer_than_80_chars

/// **Guards for the lifecycle steward after the 730-day fabrication.**
///
/// `estimatedRemainingLifeDays` was a hard-coded 730-day product life minus
/// the item's age, shown to every customer for every product. It is gone from
/// the contract, and the screen that printed it branched on a recommendation
/// value (`do_not_replace_yet`) that the backend no longer sends — so every
/// card in the wardrobe silently re-labelled itself "Assess next life".
///
/// These tests pin the three things that went wrong:
///
/// 1. **Nothing falls through.** Each of the three states renders its own
///    pill, and a state this build has never heard of reads as unrecognised
///    rather than borrowing one of the three.
/// 2. **No life estimate can be produced.** Asserted over rendered text and
///    semantics labels, not over the source: a number the widget tree cannot
///    contain is a number no customer can read.
/// 3. **A route nobody can walk offers no button**, and says why in words a
///    customer can act on.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/lifecycle/presentation/lifecycle_steward_screen.dart';

// ---------------------------------------------------------------------------
// Fixtures — built from JSON so the parser is exercised on the way in.
// ---------------------------------------------------------------------------

final DateTime _returnCloses = DateTime.utc(2026, 9, 26, 12);
final DateTime _coverEnds = DateTime.utc(2027, 8, 19, 12);

String _shown(DateTime value) =>
    DateFormat('d MMM yyyy').format(value.toLocal());

Map<String, dynamic> _pathwayJson({
  required Object kind,
  required String status,
  required String carriedOutBy,
  bool available = false,
  List<String> blockers = const [],
  String explanation = 'Explained by the server.',
}) => <String, dynamic>{
  'pathway': kind,
  'available': available,
  'status': status,
  'explanation': explanation,
  'carriedOutBy': carriedOutBy,
  'blockers': blockers,
};

/// Repair and recycle: a person can carry these out once a partner exists.
final Map<String, dynamic> _repairJson = _pathwayJson(
  kind: 1,
  status: 'provider_required',
  carriedOutBy: 'person',
  blockers: const ['provider.notConfigured'],
  explanation:
      'No verified repair partner is configured, so the platform cannot book anything.',
);

final Map<String, dynamic> _recycleJson = _pathwayJson(
  kind: 4,
  status: 'provider_required',
  carriedOutBy: 'person',
  blockers: const ['provider.notConfigured'],
  explanation:
      'No verified recycling partner is configured, so the platform cannot arrange collection.',
);

/// Resale and trade-in: nobody can, and the backend refuses to start them.
final Map<String, dynamic> _resaleJson = _pathwayJson(
  kind: 3,
  status: 'requires_unit_identity',
  carriedOutBy: 'nobody',
  blockers: const ['unitIdentity.absent'],
  explanation:
      'The platform cannot tell one physical item from another. There is no marker provisioned per item.',
);

final Map<String, dynamic> _tradeInJson = _pathwayJson(
  kind: 2,
  status: 'requires_unit_identity',
  carriedOutBy: 'nobody',
  blockers: const ['unitIdentity.absent', 'pricing.humanOnly'],
  explanation:
      'The platform cannot tell one physical item from another. A trade-in figure is money.',
);

Map<String, dynamic> _assetJson({
  String state = 'not_assessed',
  String reason = 'Delivered 31 days ago.',
  int quantity = 1,
  String expectedLifeSource = 'notMeasured',
  Object? returnWindowClosesUtc,
  Object? warrantyEnds,
  Object? warrantyDays,
  Object? warrantyRemaining,
  Object? warrantySource,
  List<Map<String, dynamic>>? pathways,
  Object? estimatedRemainingLifeDays,
  String title = 'Oxford blue shirt',
}) => <String, dynamic>{
  'subOrderLineId': 'line-1',
  'productVariantId': 'variant-1',
  'title': title,
  'variantLabel': 'M',
  'thumbnailUrl': 'https://example.test/shirt.jpg',
  'deliveredUtc': '2026-08-19T00:00:00Z',
  'ageDays': 31,
  'quantity': quantity,
  // Always null on the wire now. Passed here as a live number on purpose:
  // these tests must fail if anything ever reads it again.
  'estimatedRemainingLifeDays': estimatedRemainingLifeDays,
  'expectedLifeSource': expectedLifeSource,
  'identityScope': 'orderLine',
  'identityScopeExplanation':
      'This row is one line of one order, not one physical item. It stands for $quantity item(s) the platform cannot tell apart.',
  'returnWindowClosesUtc': returnWindowClosesUtc,
  'warrantyCoverageEndsUtc': warrantyEnds,
  'warrantyCoverageDays': warrantyDays,
  'warrantyCoverageRemainingDays': warrantyRemaining,
  'warrantySource': warrantySource,
  'recommendation': state,
  'recommendationReason': reason,
  'pathways':
      pathways ?? [_repairJson, _tradeInJson, _resaleJson, _recycleJson],
};

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

Future<void> _pump(
  WidgetTester tester, {
  required List<Map<String, dynamic>> assets,
  List<Map<String, dynamic>> register = const [],
  Size size = const Size(1080, 4200),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lifecycleAssetsProvider.overrideWith(
          (ref) async =>
              assets.map(LifecycleAsset.fromJson).toList(growable: false),
        ),
        lifecyclePathwayRegisterProvider.overrideWith(
          (ref) async =>
              register.map(LifecyclePathway.fromJson).toList(growable: false),
        ),
      ],
      child: MaterialApp(
        home: const LifecycleStewardScreen(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Everything a customer could read: rendered `Text`, plus the semantics
/// labels a screen reader would speak. A number hidden in a semantics label
/// is still a number the platform asserted.
List<String> _readable(WidgetTester tester) {
  final out = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    if (text.data case final data?) out.add(data);
    if (text.textSpan case final span?) out.add(span.toPlainText());
  }
  for (final node in tester.widgetList<Semantics>(find.byType(Semantics))) {
    if (node.properties.label case final label?) out.add(label);
  }
  return out;
}

/// The shapes the fabrication took, and the shapes a replacement would take.
///
/// `"Keep & care · 0 days est."` is the exact string the broken screen would
/// have printed once `estimatedRemainingLifeDays` started arriving null.
final RegExp _lifeEstimate = RegExp(
  r'days?\s*est\b'
  r'|\best\.'
  r'|\b(?:estimated|expected|remaining|useful|predicted|approximate)\s+life\b'
  r'|\blife\s*(?:span|time)?\s*(?:left|remaining|expectancy|estimate)\b'
  r'|\blasts?\s+(?:about\s+)?\d'
  r'|\b\d+\s*days?\s+(?:of\s+)?life\b',
  caseSensitive: false,
);

/// Every interactive control the screen can put on a card.
const List<Type> _controlTypes = [
  OutlinedButton,
  FilledButton,
  TextButton,
  IconButton,
];

/// The semantics node a screen reader would land on for each control.
List<SemanticsData> _controls(WidgetTester tester) {
  final found = <SemanticsData>[];
  for (final type in _controlTypes) {
    final finder = find.byType(type);
    for (var i = 0; i < tester.widgetList(finder).length; i++) {
      found.add(tester.getSemantics(finder.at(i)).getSemanticsData());
    }
  }
  return found;
}

void main() {
  // -------------------------------------------------------------------------
  group('contract', () {
    test('parses the measured fields the contract now carries', () {
      final asset = LifecycleAsset.fromJson(
        _assetJson(
          state: 'warranty_active',
          quantity: 3,
          warrantyEnds: _coverEnds.toIso8601String(),
          warrantyDays: 365,
          warrantyRemaining: 334,
          warrantySource: 'vendorDeclaredWarrantyPolicy',
          returnWindowClosesUtc: _returnCloses.toIso8601String(),
        ),
      );

      expect(asset.lineId, 'line-1');
      expect(asset.quantity, 3);
      expect(asset.state, 'warranty_active');
      expect(asset.expectedLifeSource, 'notMeasured');
      expect(asset.identityScope, 'orderLine');
      expect(asset.identityScopeExplanation, contains('cannot tell apart'));
      expect(asset.returnWindowClosesUtc, _returnCloses);
      expect(asset.warranty?.coverageDays, 365);
      expect(asset.warranty?.coverageRemainingDays, 334);
      expect(asset.warranty?.coverEndsUtc, _coverEnds);
      expect(asset.warranty?.source, 'vendorDeclaredWarrantyPolicy');
      expect(asset.lifeIsUnmeasured, isTrue);
      expect(asset.identityCaveatMatters, isTrue);
    });

    test(
      'a seller with no policy yields no warranty object, not zero cover',
      () {
        final asset = LifecycleAsset.fromJson(_assetJson());
        expect(asset.warranty, isNull);
      },
    );

    test('parses pathway status, executor and blockers', () {
      final trade = LifecyclePathway.fromJson(_tradeInJson);
      expect(trade.kind, 2);
      expect(trade.status, 'requires_unit_identity');
      expect(trade.carriedOutBy, 'nobody');
      expect(trade.blockers, ['unitIdentity.absent', 'pricing.humanOnly']);
      expect(trade.blockedByUnitIdentity, isTrue);
      expect(trade.blockedByPricing, isTrue);
      expect(trade.canBeRequested, isFalse);
    });

    test('accepts the pathway enum as a number or as a name', () {
      for (final spelling in ['TradeIn', 'trade_in', 'trade-in', 'tradein']) {
        expect(
          LifecyclePathway.fromJson(
            _pathwayJson(
              kind: spelling,
              status: 'requires_unit_identity',
              carriedOutBy: 'nobody',
            ),
          ).label,
          'Trade in',
          reason: '$spelling should resolve to the trade-in pathway',
        );
      }
      expect(LifecyclePathway.fromJson(_repairJson).label, 'Repair');
    });
  });

  // -------------------------------------------------------------------------
  group('the three states each render distinctly', () {
    const labels = {
      'return_window_open': 'Return window open',
      'warranty_active': 'Warranty cover active',
      'not_assessed': 'Not assessed',
    };

    for (final entry in labels.entries) {
      testWidgets('${entry.key} renders "${entry.value}" and nothing else', (
        tester,
      ) async {
        await _pump(
          tester,
          assets: [
            _assetJson(
              state: entry.key,
              returnWindowClosesUtc: entry.key == 'return_window_open'
                  ? _returnCloses.toIso8601String()
                  : null,
              warrantyEnds: entry.key == 'warranty_active'
                  ? _coverEnds.toIso8601String()
                  : null,
              warrantyDays: entry.key == 'warranty_active' ? 365 : null,
              warrantyRemaining: entry.key == 'warranty_active' ? 334 : null,
            ),
          ],
        );

        expect(find.text(entry.value), findsOneWidget);
        for (final other in labels.values.where((l) => l != entry.value)) {
          expect(find.text(other), findsNothing);
        }
        expect(find.text('Status not recognised'), findsNothing);
        // The label the broken screen defaulted every card to.
        expect(find.text('Assess next life'), findsNothing);
      });
    }

    testWidgets(
      'an unknown state reads as unrecognised, not as one of the three',
      (
        tester,
      ) async {
        await _pump(
          tester,
          assets: [
            _assetJson(
              state: 'a_state_invented_after_this_build',
              reason: 'Server prose for a state this app has not met.',
            ),
          ],
        );

        expect(find.text('Status not recognised'), findsOneWidget);
        for (final known in labels.values) {
          expect(find.text(known), findsNothing);
        }
        // The server's own words still reach the customer.
        expect(
          find.text('Server prose for a state this app has not met.'),
          findsOneWidget,
        );
        expect(
          _readable(tester).join(' '),
          contains('does not recognise the status'),
        );
      },
    );

    testWidgets('a missing state does not borrow a state that fits', (
      tester,
    ) async {
      await _pump(tester, assets: [_assetJson(state: '')]);
      expect(find.text('Status not recognised'), findsOneWidget);
      expect(find.text('Not assessed'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  group('no life estimate can be produced', () {
    testWidgets('even when the wire still carries a number for it', (
      tester,
    ) async {
      await _pump(
        tester,
        assets: [
          // 700 is what the removed formula produced for a 30-day-old item.
          _assetJson(
            estimatedRemainingLifeDays: 700,
            warrantyEnds: _coverEnds.toIso8601String(),
            warrantyDays: 365,
            warrantyRemaining: 334,
            warrantySource: 'vendorDeclaredWarrantyPolicy',
          ),
        ],
      );

      final readable = _readable(tester);
      expect(
        readable.where((s) => s.contains('700')),
        isEmpty,
        reason:
            'estimatedRemainingLifeDays reached the screen. The model must not '
            'carry that field at all.',
      );
      for (final line in readable) {
        expect(
          _lifeEstimate.hasMatch(line),
          isFalse,
          reason: 'reads as a life estimate: "$line"',
        );
      }
      expect(find.textContaining('days est.'), findsNothing);
    });

    testWidgets('and says so plainly instead of staying silent', (
      tester,
    ) async {
      await _pump(tester, assets: [_assetJson()]);
      expect(find.text('How long it will last'), findsOneWidget);
      expect(
        _readable(tester).join(' '),
        contains('Nobody has measured this'),
      );
    });

    testWidgets('the warranty day count is never offered as one', (
      tester,
    ) async {
      await _pump(
        tester,
        assets: [
          _assetJson(
            state: 'warranty_active',
            warrantyEnds: _coverEnds.toIso8601String(),
            warrantyDays: 365,
            warrantyRemaining: 334,
          ),
        ],
      );

      for (final line in _readable(tester)) {
        expect(_lifeEstimate.hasMatch(line), isFalse, reason: line);
      }
      // 334 may appear, but only ever attached to the word "cover".
      final mentions = _readable(tester).where((s) => s.contains('334'));
      expect(mentions, isNotEmpty);
      for (final line in mentions) {
        expect(line.toLowerCase(), contains('cover'), reason: line);
      }
    });
  });

  // -------------------------------------------------------------------------
  group('a route nobody can walk offers no action', () {
    testWidgets('resale shows its reason and no button', (tester) async {
      await _pump(
        tester,
        assets: [
          _assetJson(pathways: [_resaleJson]),
        ],
      );

      expect(find.text('Resell'), findsOneWidget);
      expect(find.text('Not possible yet'), findsOneWidget);
      expect(
        find.textContaining('cannot yet tell your item apart'),
        findsOneWidget,
      );
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text('Ask about this route'), findsNothing);
    });

    testWidgets(
      'trade-in names the money limit too, and still offers nothing',
      (
        tester,
      ) async {
        await _pump(
          tester,
          assets: [
            _assetJson(pathways: [_tradeInJson]),
          ],
        );

        expect(find.text('Trade in'), findsOneWidget);
        expect(
          _readable(tester).join(' '),
          allOf(
            contains('cannot yet tell your item apart'),
            contains('nobody here sets'),
          ),
        );
        expect(find.byType(OutlinedButton), findsNothing);
      },
    );

    testWidgets('repair, which a person can take forward, does offer one', (
      tester,
    ) async {
      await _pump(
        tester,
        assets: [
          _assetJson(pathways: [_repairJson]),
        ],
      );

      expect(find.text('Repair'), findsOneWidget);
      expect(find.text('No partner yet'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Ask for a repair'),
        findsOneWidget,
      );
    });

    testWidgets('an unrecognised executor withholds the button', (
      tester,
    ) async {
      await _pump(
        tester,
        assets: [
          _assetJson(
            pathways: [
              _pathwayJson(
                kind: 1,
                status: 'available',
                available: true,
                carriedOutBy: 'an_executor_invented_later',
              ),
            ],
          ),
        ],
      );

      expect(find.text('Repair'), findsOneWidget);
      expect(find.text('Available now'), findsOneWidget);
      expect(
        find.byType(OutlinedButton),
        findsNothing,
        reason: 'fail closed: an unknown executor is not a known-good one',
      );
    });

    testWidgets('an unrecognised status still renders, named as unknown', (
      tester,
    ) async {
      await _pump(
        tester,
        assets: [
          _assetJson(
            pathways: [
              _pathwayJson(
                kind: 9,
                status: 'a_status_invented_later',
                carriedOutBy: 'nobody',
                explanation: 'Server prose for an unknown route.',
              ),
            ],
          ),
        ],
      );

      expect(find.text('Another route'), findsOneWidget);
      expect(find.text('Status not recognised'), findsOneWidget);
      expect(find.text('Server prose for an unknown route.'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  group('warranty is cover, not life', () {
    testWidgets('active cover names its end date and what the date means', (
      tester,
    ) async {
      await _pump(
        tester,
        assets: [
          _assetJson(
            state: 'warranty_active',
            warrantyEnds: _coverEnds.toIso8601String(),
            warrantyDays: 365,
            warrantyRemaining: 334,
            warrantySource: 'vendorDeclaredWarrantyPolicy',
          ),
        ],
      );

      expect(find.text('Warranty cover'), findsOneWidget);
      expect(find.text('Cover ends ${_shown(_coverEnds)}'), findsOneWidget);
      expect(
        _readable(tester).join(' '),
        allOf(
          contains('365 days of cover from delivery'),
          contains('the cover stops, not the item'),
          contains('Stated by the seller in their own warranty policy.'),
        ),
      );
    });

    testWidgets('expired cover says ended, not expired item', (tester) async {
      final ended = DateTime.utc(2026, 3, 1, 12);
      await _pump(
        tester,
        assets: [
          _assetJson(
            warrantyEnds: ended.toIso8601String(),
            warrantyDays: 90,
            warrantyRemaining: 0,
            warrantySource: 'vendorDeclaredWarrantyPolicy',
          ),
        ],
      );

      expect(find.text('Cover ended ${_shown(ended)}'), findsOneWidget);
      expect(find.textContaining('About 0 days'), findsNothing);
    });

    testWidgets('no policy reads as an absence of a policy', (tester) async {
      await _pump(tester, assets: [_assetJson()]);
      expect(
        _readable(tester).join(' '),
        contains('declared no warranty for this item'),
      );
    });

    testWidgets('an unknown warranty source is attributed, not dropped', (
      tester,
    ) async {
      await _pump(
        tester,
        assets: [
          _assetJson(
            warrantyEnds: _coverEnds.toIso8601String(),
            warrantyDays: 365,
            warrantyRemaining: 334,
            warrantySource: 'somethingNewerThanThisBuild',
          ),
        ],
      );
      expect(
        find.text('Stated by: somethingNewerThanThisBuild.'),
        findsOneWidget,
      );
    });
  });

  // -------------------------------------------------------------------------
  group('quantity and identity scope', () {
    testWidgets(
      'a line of three says it is three items nobody can tell apart',
      (
        tester,
      ) async {
        await _pump(tester, assets: [_assetJson(quantity: 3)]);

        expect(find.text('One line, 3 items'), findsOneWidget);
        expect(find.text('3 items'), findsOneWidget);
        expect(
          _readable(tester).join(' '),
          contains('cannot tell apart'),
        );
      },
    );

    testWidgets('a line of one does not spend the customer on the caveat', (
      tester,
    ) async {
      await _pump(tester, assets: [_assetJson()]);
      expect(find.textContaining('One line,'), findsNothing);
      expect(find.text('1 item'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  group('layout and accessibility', () {
    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      await _pump(
        tester,
        assets: [
          _assetJson(
            title: 'Heavyweight organic cotton oxford shirt, button-down',
            state: 'warranty_active',
            quantity: 3,
            warrantyEnds: _coverEnds.toIso8601String(),
            warrantyDays: 365,
            warrantyRemaining: 334,
            warrantySource: 'vendorDeclaredWarrantyPolicy',
            returnWindowClosesUtc: _returnCloses.toIso8601String(),
          ),
          _assetJson(state: 'unknown_state'),
        ],
        size: const Size(320, 9000),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'every control carries a label a screen reader can speak and press',
      (
        tester,
      ) async {
        // Disposed inline, not in a tear-down: the framework verifies semantics
        // handles before tear-downs run.
        final handle = tester.ensureSemantics();

        await _pump(
          tester,
          assets: [
            _assetJson(pathways: [_repairJson, _resaleJson]),
          ],
        );

        final controls = _controls(tester);
        expect(controls, isNotEmpty);
        for (final node in controls) {
          expect(
            node.label.trim(),
            isNotEmpty,
            reason: 'a control with no spoken label',
          );
          // Wrapping a button in `Semantics(excludeSemantics: true)` to give it
          // a label silently removes its tap action, leaving a control a screen
          // reader can read but never press. This is that regression's guard.
          expect(
            node.hasAction(SemanticsAction.tap),
            isTrue,
            reason: 'control "${node.label}" cannot be activated',
          );
        }
        expect(
          tester.getSemantics(find.byType(OutlinedButton)).label,
          'Ask for a repair for Oxford blue shirt',
        );
        handle.dispose();
      },
    );
  });

  // -------------------------------------------------------------------------
  group('empty wardrobe', () {
    testWidgets('still says what the platform can and cannot arrange', (
      tester,
    ) async {
      await _pump(
        tester,
        assets: const [],
        register: [_repairJson, _resaleJson],
      );

      expect(find.text('Nothing delivered yet'), findsOneWidget);
      expect(find.text('What this platform can arrange'), findsOneWidget);
      expect(find.text('Repair'), findsOneWidget);
      expect(find.text('Resell'), findsOneWidget);
      // Item-independent: there is nothing to request without an item.
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets(
      'an unavailable register degrades to nothing, not to an error',
      (
        tester,
      ) async {
        await _pump(tester, assets: const []);
        expect(find.text('Nothing delivered yet'), findsOneWidget);
        expect(find.text('What this platform can arrange'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
