import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/customer_return_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/return_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_return_request_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_return_card.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/return_evidence.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/returns/return_evidence_section.dart';

import '../../../features/orders_test_harness.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

/// One snapshot, exactly as the backend puts it on the wire (camelCase), used
/// for both roles so any divergence between them shows up as a diff.
Map<String, dynamic> _evidenceJson() => <String, dynamic>{
  'collectedUtc': '2026-09-19T10:00:00Z',
  'hasEvidence': true,
  'hasDiscrepancy': true,
  'sources': <Map<String, dynamic>>[
    {
      'source': 'scanToReceive',
      'available': true,
      'detail': 'Recorded 17 Sep',
    },
    {
      'source': 'chainOfCustody',
      'available': true,
      'detail': 'Two entries kept',
    },
    {
      'source': 'productPassport',
      'available': false,
      'detail': 'The passport service could not be reached.',
    },
  ],
  'facts': <Map<String, dynamic>>[
    {
      'source': 'chainOfCustody',
      'key': 'custody.deliveryConfirmed',
      'label': 'Delivery confirmed',
      'value': 'No',
      'observedUtc': '2026-09-17T06:30:00Z',
    },
    {
      'source': 'scanToReceive',
      'key': 'scan.buyerConfirmed',
      'label': 'Buyer confirmed at handover',
      'value': 'Yes',
      'observedUtc': null,
    },
  ],
  'findings': <Map<String, dynamic>>[
    {
      'code': 'custody.neverHandedOver',
      'kind': 'discrepancy',
      'statement': 'The custody chain has no handover entry for this parcel.',
      'sources': <String>['chainOfCustody'],
      'citedFactKeys': <String>['custody.deliveryConfirmed'],
    },
    {
      'code': 'scan.buyerConfirmed',
      'kind': 'corroboration',
      'statement': 'The buyer confirmed the item at the door.',
      'sources': <String>['scanToReceive'],
      'citedFactKeys': <String>['scan.buyerConfirmed'],
    },
  ],
};

Map<String, dynamic> _customerJson(Object? evidence) => <String, dynamic>{
  'id': 'r-1',
  'submittedUtc': '2026-09-18T04:00:00Z',
  'orderNumber': 'NK2026-00321',
  'reason': 'Never arrived',
  'state': 1,
  'evidence': ?evidence,
};

Map<String, dynamic> _vendorJson(Object? evidence) => <String, dynamic>{
  'id': 'r-1',
  'orderId': 'o-1',
  'orderNumber': 'NK2026-00321',
  'subOrderId': 's-1',
  'subOrderLineId': 'l-1',
  'productTitleSnapshot': 'Linen Shirt',
  'quantity': 1,
  'reason': 'Never arrived',
  'state': 1,
  'submittedUtc': '2026-09-18T04:00:00Z',
  'evidence': ?evidence,
};

ReturnEvidence? _customerEvidence(Object? evidence) =>
    CustomerReturnDto.fromJson(_customerJson(evidence)).toDomain().evidence;

ReturnEvidence? _vendorEvidence(Object? evidence) =>
    VendorReturnRequestDto.fromJson(_vendorJson(evidence)).toDomain().evidence;

/// Every string the widget actually paints, in paint order.
List<String> _renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((s) => s.isNotEmpty)
    .toList(growable: false);

Future<void> _pump(
  WidgetTester tester,
  ReturnEvidence? evidence, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ordersTestApp(
      SingleChildScrollView(
        child: ReturnEvidenceSection(evidence: evidence),
      ),
      textScale: textScale,
    ),
  );
  await tester.pump();
}

void main() {
  group('ReturnEvidenceSection', () {
    testWidgets('both roles render the same snapshot identically', (
      tester,
    ) async {
      setPhoneView(tester);

      await _pump(tester, _customerEvidence(_evidenceJson()));
      final buyerText = _renderedText(tester);
      final buyerPills = tester
          .widgetList<MallStatusPill>(find.byType(MallStatusPill))
          .map((p) => '${p.label}/${p.icon}/${p.tone}')
          .toList(growable: false);

      await _pump(tester, _vendorEvidence(_evidenceJson()));
      final sellerText = _renderedText(tester);
      final sellerPills = tester
          .widgetList<MallStatusPill>(find.byType(MallStatusPill))
          .map((p) => '${p.label}/${p.icon}/${p.tone}')
          .toList(growable: false);

      expect(buyerText, isNotEmpty);
      expect(sellerText, buyerText);
      expect(sellerPills, buyerPills);
    });

    testWidgets('the buyer sees it on their return detail', (tester) async {
      setPhoneView(tester);
      final repository = _MockOrdersRepository();
      when(() => repository.getReturn('r-1')).thenAnswer(
        (_) async => right(
          CustomerReturnDto.fromJson(
            _customerJson(_evidenceJson()),
          ).toDomain(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersRepositoryProvider.overrideWithValue(repository),
            returnPickupProvider.overrideWith((ref, returnId) async => null),
            replacementShipmentProvider.overrideWith(
              (ref, returnId) async => null,
            ),
          ],
          child: ordersTestApp(
            const ReturnDetailScreen(returnId: 'r-1'),
            wrapInScaffold: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReturnEvidenceSection), findsOneWidget);
      expect(
        find.text('The custody chain has no handover entry for this parcel.'),
        findsOneWidget,
      );
    });

    testWidgets('the seller sees it on the return card the buyer sees on '
        'their return detail', (tester) async {
      setPhoneView(tester);
      final vendorReturn = VendorReturnRequestDto.fromJson(
        _vendorJson(_evidenceJson()),
      ).toDomain();

      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: VendorReturnCard(
              request: vendorReturn,
              busy: false,
              onApprove: () {},
              onReject: () {},
              onComplete: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ReturnEvidenceSection), findsOneWidget);
      expect(
        find.text('The custody chain has no handover entry for this parcel.'),
        findsOneWidget,
      );
    });

    testWidgets('statements are printed verbatim, with the sources they rest '
        'on', (tester) async {
      setPhoneView(tester);
      await _pump(tester, _customerEvidence(_evidenceJson()));

      expect(
        find.text('The custody chain has no handover entry for this parcel.'),
        findsOneWidget,
      );
      expect(
        find.text('The buyer confirmed the item at the door.'),
        findsOneWidget,
      );
      expect(find.text('Rests on: Chain of custody'), findsOneWidget);
      expect(find.text('Rests on: Scan to receive'), findsOneWidget);
      // The cited fact, with the value the backend recorded.
      expect(
        find.textContaining('Delivery confirmed: No'),
        findsOneWidget,
      );
    });

    testWidgets('findings keep the backend order — nothing is sorted by kind', (
      tester,
    ) async {
      setPhoneView(tester);
      await _pump(tester, _customerEvidence(_evidenceJson()));

      final text = _renderedText(tester);
      final discrepancy = text.indexWhere((s) => s.startsWith('The custody'));
      final corroboration = text.indexWhere((s) => s.startsWith('The buyer'));
      expect(discrepancy, lessThan(corroboration));
      expect(
        text.indexOf('Discrepancy'),
        lessThan(text.indexOf('Corroboration')),
      );
    });

    testWidgets('discrepancy and corroboration differ without colour', (
      tester,
    ) async {
      setPhoneView(tester);
      await _pump(tester, _customerEvidence(_evidenceJson()));

      final pills = tester
          .widgetList<MallStatusPill>(find.byType(MallStatusPill))
          .toList(growable: false);
      expect(pills, hasLength(2));

      // Each kind is named in words...
      expect(pills.map((p) => p.label), ['Discrepancy', 'Corroboration']);
      // ...and carries its own glyph, so greyscale still separates them.
      expect(pills[0].icon, isNotNull);
      expect(pills[1].icon, isNotNull);
      expect(pills[0].icon, isNot(pills[1].icon));
    });

    testWidgets('screen readers get the kind as a word', (tester) async {
      setPhoneView(tester);
      final handle = tester.ensureSemantics();
      await _pump(tester, _customerEvidence(_evidenceJson()));

      expect(
        find.bySemanticsLabel(
          RegExp(
            r'^Discrepancy\. The custody chain has no handover entry for '
            r'this parcel\.',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Corroboration\. The buyer confirmed')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('an unavailable source states why', (tester) async {
      setPhoneView(tester);
      await _pump(tester, _customerEvidence(_evidenceJson()));

      expect(find.text('Product passport · Not available'), findsOneWidget);
      expect(
        find.text('The passport service could not be reached.'),
        findsOneWidget,
      );
      expect(find.text('Scan to receive · Recorded'), findsOneWidget);
    });

    testWidgets('an unavailable source with no reason says so rather than '
        'implying it found nothing', (tester) async {
      setPhoneView(tester);
      final json = _evidenceJson();
      (json['sources']! as List)[2] = <String, dynamic>{
        'source': 'productPassport',
        'available': false,
        'detail': null,
      };
      await _pump(tester, _customerEvidence(json));

      expect(find.text('Product passport · Not available'), findsOneWidget);
      expect(find.text('No reason was recorded.'), findsOneWidget);
      expect(find.textContaining('found nothing'), findsNothing);
    });

    testWidgets('no score, no count, no meter anywhere in the output', (
      tester,
    ) async {
      setPhoneView(tester);
      await _pump(tester, _customerEvidence(_evidenceJson()));

      final text = _renderedText(tester).join(' | ');
      for (final banned in const [
        'score',
        'confidence',
        'rating',
        'risk',
        'out of',
        'strength',
        '%',
      ]) {
        expect(
          text.toLowerCase(),
          isNot(contains(banned)),
          reason: 'the snapshot exposes no number and the UI must derive none',
        );
      }
      // No "2 findings", no "1 of 3", no bare tallies.
      expect(text, isNot(matches(RegExp(r'\d+\s*(of|/)\s*\d+'))));
      expect(
        _renderedText(tester),
        everyElement(isNot(matches(RegExp(r'^\s*\d+\s*$')))),
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('an absent snapshot renders nothing at all', (tester) async {
      setPhoneView(tester);
      await _pump(tester, _customerEvidence(null));

      expect(_customerEvidence(null), isNull);
      expect(find.byType(Text), findsNothing);
      expect(find.byType(MallStatusPill), findsNothing);
      expectNoLayoutErrors(tester);
    });

    testWidgets('an explicit null snapshot renders nothing and no error', (
      tester,
    ) async {
      setPhoneView(tester);
      expect(_customerEvidence(null), isNull);
      expect(_vendorEvidence(null), isNull);

      await _pump(tester, null);
      expect(find.byType(Text), findsNothing);
      expectNoLayoutErrors(tester);
    });

    testWidgets('a snapshot with nothing recorded renders nothing, not an '
        'empty card', (tester) async {
      setPhoneView(tester);
      final empty = <String, dynamic>{
        'collectedUtc': '2026-09-19T10:00:00Z',
        'hasEvidence': false,
        'hasDiscrepancy': false,
        'sources': <Map<String, dynamic>>[
          {'source': 'scanToReceive', 'available': false, 'detail': null},
        ],
        'facts': <Map<String, dynamic>>[],
        'findings': <Map<String, dynamic>>[],
      };
      await _pump(tester, _customerEvidence(empty));

      expect(find.byType(Text), findsNothing);
      expect(find.textContaining('No evidence'), findsNothing);
      expectNoLayoutErrors(tester);
    });

    testWidgets('unknown source and kind values degrade instead of throwing', (
      tester,
    ) async {
      setPhoneView(tester);
      final json = _evidenceJson();
      json['sources'] = <Map<String, dynamic>>[
        {
          'source': 'quantumLedger',
          'available': true,
          'detail': 'From a newer backend',
        },
      ];
      json['facts'] = <Map<String, dynamic>>[
        {
          'source': 'quantumLedger',
          'key': 'q.spin',
          'label': 'Ledger entry',
          'value': 'Present',
          'observedUtc': null,
        },
      ];
      json['findings'] = <Map<String, dynamic>>[
        {
          'code': 'q.future',
          'kind': 'speculation',
          'statement': 'A kind this build has never heard of.',
          'sources': <String>['quantumLedger'],
          'citedFactKeys': <String>['q.spin'],
        },
      ];

      await _pump(tester, _customerEvidence(json));

      expect(
        find.text('A kind this build has never heard of.'),
        findsOneWidget,
      );
      // Named plainly, never guessed at.
      expect(find.text('Finding'), findsOneWidget);
      expect(find.text('Other record · Recorded'), findsOneWidget);
      expect(find.text('Rests on: Other record'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('malformed members do not throw', (tester) async {
      setPhoneView(tester);
      await _pump(
        tester,
        _customerEvidence(<String, dynamic>{
          'hasEvidence': true,
          'sources': 'not a list',
          'facts': <Object>[42, 'nonsense'],
          'findings': <Map<String, dynamic>>[
            {'statement': 'Only a statement survived.'},
          ],
        }),
      );

      expect(find.text('Only a statement survived.'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      setPhoneView(tester, width: 320);
      await _pump(tester, _customerEvidence(_evidenceJson()), textScale: 1.3);

      expectNoLayoutErrors(tester);
      expect(find.byType(ReturnEvidenceSection), findsOneWidget);
    });
  });
}
