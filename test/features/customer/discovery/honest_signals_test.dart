import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_signals_section.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../../../shared/presentation/mall/mall_harness.dart';

/// Answers every GET with the body registered for its path.
class _JsonApiClient extends ApiClient {
  _JsonApiClient(this.bodies) : super(dio: Dio());

  final Map<String, Object> bodies;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => bodies[uri];
}

class _Online implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;
}

const String _urgencyPath =
    '/api/v1/customer/discover/products/p-1/urgency';
const String _socialProofPath =
    '/api/v1/customer/discover/products/social-proof';

DiscoveryRepositoryImpl _repo(Map<String, Object> bodies) =>
    DiscoveryRepositoryImpl(
      remoteDataSource: DiscoveryRemoteDataSource(
        apiClient: _JsonApiClient(bodies),
      ),
      networkInfo: _Online(),
    );

Future<ProductUrgency> _urgency(Map<String, dynamic> body) async {
  final result = await _repo({_urgencyPath: body}).getProductUrgency('p-1');
  return result.getOrElse((_) => throw StateError('urgency call failed'));
}

Future<ProductSocialProof?> _socialProof(Map<String, dynamic> proof) async {
  final result = await _repo({
    _socialProofPath: {'p-1': proof},
  }).getSocialProof(['p-1']);
  final byId =
      result.getOrElse((_) => throw StateError('social proof failed'));
  return byId['p-1'];
}

// ── Source scanning ─────────────────────────────────────────────────────────

/// Every Dart source under lib/ and test/, with comment lines stripped.
///
/// Comments are stripped on purpose: the notes in `product_detail_screen.dart`
/// and `product_detail.dart` name the deleted fields deliberately, so the next
/// engineer knows what was removed and why. What must not come back is a
/// *reference* — code that reads or writes one.
Map<String, String> _sourceWithoutComments() {
  final sources = <String, String>{};
  for (final root in ['lib', 'test']) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      // Generated files mirror their sources; scanning them adds noise.
      if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
      // This file names every banned string in order to ban it.
      if (path.endsWith('honest_signals_test.dart')) continue;
      sources[path] = entity
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');
    }
  }
  return sources;
}

/// The shopper-facing surfaces and the shared kit they draw with.
///
/// Vendor screens are deliberately out of scope: a vendor's own exact
/// on-hand count is their inventory, shown to the person who owns it, and
/// "0 left in stock" on a vendor dashboard is information rather than a
/// scarcity claim aimed at a buyer.
bool _isShopperFacing(String path) =>
    !path.contains('/vendor/') && !path.contains('/creator/');

void main() {
  // ── The contract, at the parse boundary ───────────────────────────────────

  group('urgency payload', () {
    test('an empty payload is all nulls, not zeros and falses', () async {
      final urgency = await _urgency(const {});

      expect(urgency.isInStock, isNull);
      expect(urgency.isLowStock, isNull);
      expect(urgency.viewersRightNow, isNull);
      expect(urgency.flashSaleEndsAt, isNull);
      expect(urgency.flashSalePrice, isNull);
    });

    test('a measured payload survives the mapper intact', () async {
      final urgency = await _urgency(const {
        'isInStock': true,
        'isLowStock': true,
        'viewersRightNow': 4,
        'flashSaleEndsAt': '2026-09-20T10:00:00Z',
        'flashSalePrice': 2499.5,
        'flashSaleCurrency': 'NPR',
      });

      expect(urgency.isInStock, isTrue);
      expect(urgency.isLowStock, isTrue);
      expect(urgency.viewersRightNow, 4);
      expect(urgency.flashSaleEndsAt, DateTime.utc(2026, 9, 20, 10));
      expect(urgency.flashSalePrice?.amount, 2499.5);
    });

    test('the flash-sale price is formatted in the currency it came '
        'back with, not an assumed one', () async {
      final npr = await _urgency(const {
        'flashSalePrice': 2499,
        'flashSaleCurrency': 'NPR',
      });
      final usd = await _urgency(const {
        'flashSalePrice': 2499,
        'flashSaleCurrency': 'USD',
      });

      expect(npr.flashSalePrice?.currency, 'NPR');
      expect(usd.flashSalePrice?.currency, 'USD');
      // The same number, two currencies: the client cannot be defaulting.
      expect(npr.flashSalePrice?.amount, usd.flashSalePrice?.amount);
    });

    test('a sale price with no currency is dropped rather than guessed',
        () async {
      final urgency = await _urgency(const {'flashSalePrice': 2499});

      expect(urgency.flashSalePrice, isNull);
    });
  });

  group('social proof payload', () {
    test('absent figures stay absent', () async {
      final proof = await _socialProof(const {'reviewCount': 0});

      expect(proof, isNotNull);
      expect(proof!.reviewCount, 0);
      expect(proof.unitsSoldLast30Days, isNull);
      expect(proof.viewersRightNow, isNull);
      // Null with no reviews behind it — never a 0.0 average.
      expect(proof.averageRating, isNull);
      expect(proof.hasRating, isFalse);
    });

    test('a rating is only a rating when reviews back it', () async {
      final unreviewed = await _socialProof(const {
        'reviewCount': 0,
        'averageRating': null,
      });
      final reviewed = await _socialProof(const {
        'reviewCount': 22,
        'averageRating': 4.6,
      });

      expect(unreviewed!.hasRating, isFalse);
      expect(reviewed!.hasRating, isTrue);
      expect(reviewed.averageRating, 4.6);
    });

    test('measured units sold come through', () async {
      final proof = await _socialProof(const {
        'reviewCount': 3,
        'unitsSoldLast30Days': 128,
      });

      expect(proof?.unitsSoldLast30Days, 128);
    });
  });

  // ── What gets drawn ───────────────────────────────────────────────────────

  group('ProductSignals', () {
    testWidgets('a response with every optional field absent draws nothing', (
      tester,
    ) async {
      await pumpMall(
        tester,
        const ProductSignals(
          urgency: ProductUrgency(),
          socialProof: ProductSocialProof(reviewCount: 0),
        ),
      );

      // Not "0 sold", not an empty bar, not a heading over nothing.
      expect(find.byType(MallSignalLine), findsNothing);
      expect(find.textContaining('0'), findsNothing);
      expect(find.textContaining('sold'), findsNothing);
      expect(find.textContaining(RegExp('left', caseSensitive: false)),
          findsNothing);
      expectNoLayoutErrors(tester);
    });

    testWidgets('no signals at all still draws nothing', (tester) async {
      await pumpMall(tester, const ProductSignals());

      expect(find.byType(MallSignalLine), findsNothing);
      expectNoLayoutErrors(tester);
    });

    testWidgets('a null rating never becomes a star row', (tester) async {
      await pumpMall(
        tester,
        const ProductSignals(
          socialProof: ProductSocialProof(reviewCount: 0),
        ),
      );

      // The regression the browse pass found in three places: an unreviewed
      // product wearing "0.0 Stars".
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_outline), findsNothing);
      expect(find.text('0.0'), findsNothing);
      expect(find.textContaining(RegExp('star', caseSensitive: false)),
          findsNothing);
    });

    testWidgets('measured units sold are stated plainly', (tester) async {
      await pumpMall(
        tester,
        const ProductSignals(
          socialProof: ProductSocialProof(
            reviewCount: 3,
            unitsSoldLast30Days: 128,
          ),
        ),
      );

      expect(find.text('128 sold in the last 30 days'), findsOneWidget);
      // No velocity theatre bolted onto the measured figure.
      expect(find.textContaining(RegExp('fast|hurry|trending|selling',
          caseSensitive: false)), findsNothing);
    });

    testWidgets('low stock is stated without a number', (tester) async {
      await pumpMall(
        tester,
        const ProductSignals(
          urgency: ProductUrgency(isInStock: true, isLowStock: true),
        ),
      );

      expect(find.text(MallStrings.english.onlyAFewLeft), findsOneWidget);
      // Whatever the copy says, it may not contain a count.
      final lines = tester.widgetList<Text>(find.byType(Text));
      for (final line in lines) {
        expect(line.data ?? '', isNot(matches(RegExp(r'\d'))),
            reason: 'the stock signal must carry no figure');
      }
    });

    testWidgets('plenty of stock and unknown stock both draw no stock line', (
      tester,
    ) async {
      for (final urgency in const [
        ProductUrgency(isInStock: true, isLowStock: false),
        ProductUrgency(),
      ]) {
        await pumpMall(tester, ProductSignals(urgency: urgency));
        expect(find.byType(MallSignalLine), findsNothing);
      }
    });

    testWidgets('a null viewer count — the production case — draws nothing', (
      tester,
    ) async {
      await pumpMall(
        tester,
        const ProductSignals(
          urgency: ProductUrgency(isInStock: true),
          socialProof: ProductSocialProof(reviewCount: 9),
        ),
      );

      expect(find.byType(MallSignalLine), findsNothing);
      expect(find.textContaining(RegExp('viewing|watching|shopper',
          caseSensitive: false)), findsNothing);
    });

    testWidgets('a measured viewer count is shown', (tester) async {
      await pumpMall(
        tester,
        const ProductSignals(
          urgency: ProductUrgency(isInStock: true, viewersRightNow: 4),
        ),
      );

      expect(find.text('4 shoppers viewing now'), findsOneWidget);
    });

    testMallLayouts('every signal at once fits', (
      tester,
      width,
      textScale,
    ) async {
      await pumpMall(
        tester,
        const ProductSignals(
          urgency: ProductUrgency(
            isInStock: true,
            isLowStock: true,
            viewersRightNow: 12,
          ),
          socialProof: ProductSocialProof(
            reviewCount: 41,
            unitsSoldLast30Days: 1284,
            averageRating: 4.6,
          ),
        ),
        width: width,
        textScale: textScale,
      );

      expect(find.byType(MallSignalLine), findsNWidgets(3));
      expectNoLayoutErrors(tester);
    });
  });

  // ── Guards on the source itself ───────────────────────────────────────────

  group('source guards', () {
    test('no code reads a field the contract no longer sends', () {
      // Removed from SocialProofDto and UrgencyDto, plus the rename of
      // viewingNow → viewersRightNow.
      final removed = [
        'recentPurchases',
        'addedToCartToday',
        'friendNames',
        'trendingLabel',
        'isBackInStock',
        'stockRemaining',
        'cartAddsLast10Min',
        'cartAdds10Min',
        'viewingNow',
      ];

      final offenders = <String>[];
      _sourceWithoutComments().forEach((path, source) {
        for (final field in removed) {
          if (source.contains(field)) offenders.add('$path → $field');
        }
      });

      expect(offenders, isEmpty,
          reason: 'a removed field is still referenced in code');
    });

    test('nothing reconstructs an exact stock figure or an "only N left"',
        () {
      // "Only a few left" is fine — it carries no count. A digit, an
      // interpolation or a plural noun next to "left" is not.
      final banned = [
        RegExp(r'[Oo]nly\s+(\$|\{|\d)'),
        RegExp(r'\$\w+\s+left\b'),
        RegExp(r'\{\s*\w+\s*\}\s*left\b'),
        RegExp(r'\d+\s+left\b'),
        RegExp(r'left\s+in\s+stock', caseSensitive: false),
        RegExp(r'\bstockRemaining\b'),
      ];

      final offenders = <String>[];
      _sourceWithoutComments().forEach((path, source) {
        if (!_isShopperFacing(path)) return;
        for (final pattern in banned) {
          final match = pattern.firstMatch(source);
          if (match != null) offenders.add('$path → "${match.group(0)}"');
        }
      });

      expect(offenders, isEmpty,
          reason: 'an exact stock figure has been reconstructed');
    });

    test('the DO NOT RESTORE note still points at the real backend file', () {
      final note = File(
        'lib/features/customer/discovery/presentation/screens/'
        'product_detail_screen.dart',
      ).readAsStringSync();

      expect(note, contains('DO NOT RESTORE'));
      expect(
        note,
        contains(
          'StyleMint.Modules.Discovery/Service/SocialProofService/'
          'SocialProofService.cs',
        ),
      );
      // It must describe the contract as it is now, not as it was.
      expect(note, contains('UnitsSoldLast30Days'));
      expect(note, contains('IsLowStock'));
    });
  });
}
