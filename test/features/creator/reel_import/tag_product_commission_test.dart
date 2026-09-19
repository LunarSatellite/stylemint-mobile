import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/datasources/reel_import_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/models/tag_product_commission_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/tag_product_commission.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/tag_product_commission_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/tag_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// **The invented ten percent, and the real rate that replaced it.**
///
/// Two `_commissionLabel()` methods in `tag_products_screen.dart` built
/// `Est. 10% commission (~Rs 450 per sale)` from a hardcoded `const pct = 10`
/// and showed it to a creator choosing which products to tag. Ten percent
/// was not a rate anybody had agreed to; the real one is a term of that
/// creator's partnership with the product's vendor, now read from
/// `GET /v1/creator/tag-products/commission`.
///
/// The pair these tests exist for is the two **zero-shaped** answers:
///
///   * `Status: "Applies"` with `CommissionRateFraction: 0` — a partnership
///     covers the product and its agreed rate is nought. It is a recorded
///     zero and renders **"0% commission"**.
///   * `Status: "NoPartnership"` with nulls — no partnership covers it, so
///     there is no rate. It renders **"No commission applies"** and draws no
///     numeral at all.
///
/// The server distinguishes them twice over, in the status name and in null
/// versus zero, so the client cannot collapse them by accident. A future
/// edit that treats a null rate as zero, or drops the zero as if it were
/// absence, fails here.

// ── Fakes ────────────────────────────────────────────────────────────────────

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient(this.itemsFor) : super(dio: Dio());

  /// Builds the payload for whatever ids the call asked about.
  final List<Map<String, dynamic>> Function(List<String> ids) itemsFor;

  final List<List<String>> calls = <List<String>>[];

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final ids = (queryParameters?['productIds'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    calls.add(ids);
    return <String, dynamic>{'Items': itemsFor(ids)};
  }
}

class _FakeCommissionRepository implements TagProductCommissionRepository {
  _FakeCommissionRepository(this.answers);

  final Map<String, TagProductCommission> answers;

  @override
  Future<Either<NetworkExceptions, Map<String, TagProductCommission>>>
  getCommissions(List<String> productIds) async => right(answers);
}

// ── Builders ─────────────────────────────────────────────────────────────────

TaggedProductForImport _product(String id, {String name = 'Kurta'}) =>
    TaggedProductForImport(
      productId: id,
      productName: name,
      imageUrl: '',
      price: const Money(amount: 3000, currency: 'NPR'),
      vendorName: 'Hamro Pasal',
    );

Future<void> _pumpSheet(
  WidgetTester tester,
  Map<String, TagProductCommission> answers, {
  List<TaggedProductForImport> products = const [],
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tagProductCommissionRepositoryProvider.overrideWithValue(
          _FakeCommissionRepository(answers),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          home: Scaffold(
            body: TaggedProductsSheet(
              taggedProducts: products,
              onUntag: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _allText(WidgetTester tester) => <String>[
  ...tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? ''),
  ...tester
      .widgetList<Semantics>(find.byType(Semantics))
      .map((s) => s.properties.label ?? ''),
].where((s) => s.isNotEmpty).join('\n');

void main() {
  // ── 1. The pair a future edit is most likely to break ──────────────────────

  group('the two zero-shaped answers', () {
    testWidgets('a 0% Applies term renders "0%"', (tester) async {
      await _pumpSheet(
        tester,
        {
          'prod-1': const TagProductCommission(
            productId: 'prod-1',
            status: TagProductCommissionStatus.applies,
            partnershipId: 'part-1',
            commissionRateFraction: 0,
            commissionPerSale: Money(amount: 0, currency: 'NPR'),
          ),
        },
        products: [_product('prod-1')],
      );

      final text = _allText(tester);
      // A partnership exists and pays nought. The creator is told so.
      expect(text, contains('0% commission'));
      expect(text, isNot(contains('No commission applies')));
    });

    testWidgets('NoPartnership renders no numeral and no rate', (tester) async {
      await _pumpSheet(
        tester,
        {
          'prod-1': const TagProductCommission(
            productId: 'prod-1',
            status: TagProductCommissionStatus.noPartnership,
          ),
        },
        products: [_product('prod-1')],
      );

      final text = _allText(tester);
      expect(text, contains('No commission applies'));
      // Absence is not a zero: no percent at all, in either direction.
      expect(text, isNot(contains('% commission')));
      expect(text, isNot(contains('0%')));
      expect(text, isNot(contains('per sale')));
    });

    testWidgets('the two do not render the same thing', (tester) async {
      await _pumpSheet(
        tester,
        {
          'a': const TagProductCommission(
            productId: 'a',
            status: TagProductCommissionStatus.applies,
            commissionRateFraction: 0,
            commissionPerSale: Money(amount: 0, currency: 'NPR'),
          ),
          'b': const TagProductCommission(
            productId: 'b',
            status: TagProductCommissionStatus.noPartnership,
          ),
        },
        products: [_product('a', name: 'Recorded zero'), _product('b')],
      );

      final text = _allText(tester);
      expect(text, contains('0% commission'));
      expect(text, contains('No commission applies'));
    });
  });

  // ── 2. A real rate is rendered as the rate it is ───────────────────────────

  group('Applies', () {
    testWidgets('renders the percent and the money verbatim', (tester) async {
      await _pumpSheet(
        tester,
        {
          'prod-1': const TagProductCommission(
            productId: 'prod-1',
            status: TagProductCommissionStatus.applies,
            partnershipId: 'part-1',
            commissionRateFraction: 0.15,
            commissionPerSale: Money(amount: 450, currency: 'NPR'),
          ),
        },
        products: [_product('prod-1')],
      );

      final text = _allText(tester);
      // 0.15 is fifteen percent. `.round()` on the fraction is 0, which is
      // the bug that made a 15% partnership advertise "0% commissions".
      expect(text, contains('15% commission'));
      expect(text, contains('Rs 450.00 per sale'));
      // No hedging left: these are not estimates any more.
      expect(text, isNot(contains('Est.')));
      expect(text, isNot(contains('(est.)')));
      expect(text, isNot(contains('~Rs')));
    });

    testWidgets('a fractional rate keeps its fraction', (tester) async {
      await _pumpSheet(
        tester,
        {
          'prod-1': const TagProductCommission(
            productId: 'prod-1',
            status: TagProductCommissionStatus.applies,
            commissionRateFraction: 0.125,
            commissionPerSale: Money(amount: 375, currency: 'NPR'),
          ),
        },
        products: [_product('prod-1')],
      );
      expect(_allText(tester), contains('12.5% commission'));
    });

    testWidgets('ProductUnavailable asserts nothing', (tester) async {
      await _pumpSheet(
        tester,
        {
          'prod-1': const TagProductCommission(
            productId: 'prod-1',
            status: TagProductCommissionStatus.productUnavailable,
          ),
        },
        products: [_product('prod-1')],
      );

      final text = _allText(tester);
      expect(text, isNot(contains('commission')));
      expect(text, isNot(contains('per sale')));
    });

    testWidgets('an answer that never arrived draws nothing', (tester) async {
      await _pumpSheet(tester, const {}, products: [_product('prod-1')]);
      final text = _allText(tester);
      expect(text, isNot(contains('commission')));
      expect(text, isNot(contains('per sale')));
    });

    testWidgets('no overflow at 320dp and a 1.3 text scale', (tester) async {
      await _pumpSheet(
        tester,
        {
          'prod-1': const TagProductCommission(
            productId: 'prod-1',
            status: TagProductCommissionStatus.applies,
            commissionRateFraction: 0.225,
            commissionPerSale: Money(amount: 1234567.89, currency: 'NPR'),
          ),
        },
        products: [
          _product('prod-1', name: 'Sagarmatha Handloom Winter Kurta Set'),
        ],
        size: const Size(320, 900),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ── 3. The percent never goes through .round() ─────────────────────────────

  group('commissionPercentLabel', () {
    test('scales the fraction instead of rounding it', () {
      String? label(double? fraction) => TagProductCommission(
        productId: 'p',
        status: TagProductCommissionStatus.applies,
        commissionRateFraction: fraction,
      ).commissionPercentLabel;

      expect(label(0.15), '15%');
      expect(label(0.125), '12.5%');
      expect(label(0.2), '20%');
      expect(label(1), '100%');
      // The recorded zero survives as a zero.
      expect(label(0), '0%');
      // Absence stays absent.
      expect(label(null), isNull);
    });
  });

  // ── 4. The wire ────────────────────────────────────────────────────────────

  group('TagProductCommissionDto', () {
    test('reads the PascalCase payload', () {
      final domain = TagProductCommissionDto.fromJson(const {
        'ProductId': 'prod-1',
        'Status': 'Applies',
        'PartnershipId': 'part-1',
        'CommissionRateFraction': 0.15,
        'CommissionRateMinFraction': 0.10,
        'CommissionRateMaxFraction': 0.20,
        'ProductVariantId': 'var-1',
        'UnitPrice': {'Amount': 3000, 'Currency': 'NPR'},
        'CommissionPerSale': {'Amount': 450, 'Currency': 'NPR'},
      }).toDomain();

      expect(domain.status, TagProductCommissionStatus.applies);
      expect(domain.commissionRateFraction, 0.15);
      expect(
        domain.commissionPerSale,
        const Money(amount: 450, currency: 'NPR'),
      );
      expect(domain.unitPrice, const Money(amount: 3000, currency: 'NPR'));
      expect(domain.partnershipId, 'part-1');
    });

    test('NoPartnership keeps every rate field null', () {
      final domain = TagProductCommissionDto.fromJson(const {
        'ProductId': 'prod-2',
        'Status': 'NoPartnership',
        'PartnershipId': null,
        'CommissionRateFraction': null,
        'CommissionPerSale': null,
      }).toDomain();

      expect(domain.status, TagProductCommissionStatus.noPartnership);
      expect(domain.commissionRateFraction, isNull);
      expect(domain.commissionPerSale, isNull);
      expect(domain.commissionPercentLabel, isNull);
    });

    test('a zero rate under Applies is kept as zero, not nulled', () {
      final domain = TagProductCommissionDto.fromJson(const {
        'ProductId': 'prod-3',
        'Status': 'Applies',
        'CommissionRateFraction': 0,
        'CommissionPerSale': {'Amount': 0, 'Currency': 'NPR'},
      }).toDomain();

      expect(domain.status, TagProductCommissionStatus.applies);
      expect(domain.commissionRateFraction, 0);
      expect(domain.commissionPercentLabel, '0%');
    });

    test('an unrecognised status asserts nothing', () {
      final domain = TagProductCommissionDto.fromJson(const {
        'ProductId': 'prod-4',
        'Status': 'SomethingNewTheServerAdded',
        'CommissionRateFraction': 0.5,
      }).toDomain();
      expect(domain.status, TagProductCommissionStatus.productUnavailable);
    });
  });

  // ── 5. One call per list, chunked at the limit the server enforces ─────────

  group('the batched lookup', () {
    test('asks for a whole list in one call', () async {
      final api = _RecordingApiClient(
        (ids) => [
          for (final id in ids)
            {'ProductId': id, 'Status': 'NoPartnership'},
        ],
      );
      final dtos = await ReelImportRemoteDataSource(
        apiClient: api,
      ).getTagProductCommissions(['a', 'b', 'c']);

      expect(api.calls.length, 1, reason: 'a call per product is an N+1');
      expect(api.calls.single, ['a', 'b', 'c']);
      expect(dtos.length, 3);
    });

    test('chunks past the 50-id limit instead of truncating', () async {
      // The server rejects a longer list rather than truncating it, and a
      // silently dropped id would show no rate on a product that has one.
      final ids = List.generate(120, (i) => 'p$i');
      final api = _RecordingApiClient(
        (batch) => [
          for (final id in batch) {'ProductId': id, 'Status': 'NoPartnership'},
        ],
      );
      final dtos = await ReelImportRemoteDataSource(
        apiClient: api,
      ).getTagProductCommissions(ids);

      expect(api.calls.map((c) => c.length).toList(), [50, 50, 20]);
      expect(dtos.length, 120);
      expect(dtos.map((d) => d.productId).toList(), ids);
    });

    test('an empty list asks nothing at all', () async {
      final api = _RecordingApiClient((_) => const []);
      final dtos = await ReelImportRemoteDataSource(
        apiClient: api,
      ).getTagProductCommissions(const []);
      expect(api.calls, isEmpty);
      expect(dtos, isEmpty);
    });

    test('the family key is order-independent and deduplicated', () {
      expect(
        tagProductCommissionKey(['b', 'a', 'b']),
        tagProductCommissionKey(['a', 'b']),
      );
      expect(tagProductCommissionKey(const []), '');
    });
  });

  // ── 6. The invented figure cannot come back through the source ─────────────

  group('the invented ten percent is gone from both sites', () {
    const path =
        'lib/features/creator/reel_import/presentation/screens/'
        'tag_products_screen.dart';

    /// The screen's source with comments stripped.
    ///
    /// The bans are about what the app **computes and renders**, never about
    /// what a comment may explain: the docs that record exactly what was
    /// removed name the old label in prose, and must not fail the guard that
    /// keeps it gone. Stripping is deliberately crude — a `//` inside a
    /// string truncates that line — which can only hide a match, never
    /// invent one.
    String code() => File(path)
        .readAsStringSync()
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
        .replaceAll(RegExp('//.*'), '');

    test('no product chip computes a rate from a hardcoded percent', () {
      final source = code();
      expect(source, isNot(contains('const pct = 10')));
      expect(source, isNot(contains(r'Est. $pct% commission')));
      expect(source, isNot(contains('Est. 10%')));
      expect(source, isNot(contains('_commissionLabel')));
      // Both chips go through the one widget that renders the real answer.
      expect('_CommissionChip(commission:'.allMatches(source).length, 2);
    });
  });
}
