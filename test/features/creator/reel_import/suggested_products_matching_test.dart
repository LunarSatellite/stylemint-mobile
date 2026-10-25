import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/datasources/reel_import_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/models/suggested_product_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/repositories/reel_import_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/tag_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

/// Creator reel import, AI features contract v1.0 §4.1: suggested products
/// come with a meaning `score`, a `matchType` and a `reason`, and the screen
/// shows them — while a fallback list (the creator's taggable products, no
/// meaning match) is neither scored nor called "based on your reel".
class _Api extends ApiClient {
  _Api(this.body) : super(dio: Dio());

  final Object? body;
  String? path;
  Map<String, dynamic>? query;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    path = uri;
    query = queryParameters;
    final answer = body;
    if (answer == null) {
      final request = RequestOptions(path: uri);
      throw DioException(
        requestOptions: request,
        response: Response<dynamic>(requestOptions: request, statusCode: 404),
      );
    }
    return answer;
  }
}

class _Repo implements ReelImportRepository {
  _Repo(this.products);

  final List<TaggedProductForImport> products;
  String? caption;

  @override
  Future<Either<NetworkExceptions, List<TaggedProductForImport>>>
  getSuggestedProducts({
    required SocialPlatform platform,
    required String externalId,
    String? caption,
  }) async {
    this.caption = caption;
    return right(products);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const Map<String, dynamic> _meaningRow = {
  'productId': 'p-1',
  'name': 'Linen kurta',
  'heroImageUrl': '',
  'price': 2499.0,
  'currency': 'NPR',
  'brandName': 'Kathmandu Weaves',
  'vendorAccountId': 'v-1',
  'isOwnProduct': false,
  'score': 0.86,
  'matchType': 'meaning',
  'reason': "Close in meaning to this reel's caption and #summer #linen",
};

const Map<String, dynamic> _fallbackRow = {
  'productId': 'p-2',
  'name': 'Wool shawl',
  'heroImageUrl': '',
  'price': 1800.0,
  'currency': 'NPR',
  'brandName': 'My shop',
  'isOwnProduct': true,
  'score': 0,
  'matchType': 'fallback',
  'reason': 'One of your products',
};

ImportableReel _reel() => ImportableReel(
  id: 'ig-1',
  platform: SocialPlatform.instagram,
  platformPostId: 'post 1',
  sourceUrl: 'https://www.instagram.com/reel/post1/',
  thumbnailUrl: '',
  caption: 'Summer linen #summer #linen',
  createdAt: DateTime(2026, 10, 20),
  videoDuration: 15,
);

Future<_Repo> _pumpScreen(
  WidgetTester tester,
  List<Map<String, dynamic>> rows,
) async {
  tester.view
    ..physicalSize = const Size(390, 1400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = _Repo([
    for (final row in rows) SuggestedProductDto.fromJson(row).toDomain(),
  ]);
  final router = GoRouter(
    initialLocation: '/tag',
    initialExtra: _reel(),
    routes: [
      GoRoute(path: '/tag', builder: (_, _) => const TagProductsScreen()),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        suggestedProductsNotifierProvider.overrideWith(
          (ref) => SuggestedProductsNotifier(repo),
        ),
        tagProductCommissionsProvider.overrideWith(
          (ref, key) async => const {},
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('SuggestedProductDto', () {
    test('a meaning match keeps its score and reason', () {
      final product = SuggestedProductDto.fromJson(_meaningRow).toDomain();

      expect(product.isMeaningMatch, isTrue);
      expect(product.matchScore, 0.86);
      expect(product.matchPercent, 86);
      expect(product.matchReason, startsWith('Close in meaning'));
      expect(product.isOwnProduct, isFalse);
      expect(product.vendorName, 'Kathmandu Weaves');
    });

    test('a fallback row is unscored, with no reason', () {
      final product = SuggestedProductDto.fromJson(_fallbackRow).toDomain();

      expect(product.isMeaningMatch, isFalse);
      expect(product.matchScore, isNull);
      expect(product.matchPercent, isNull);
      expect(product.matchReason, isNull);
    });

    test('an older row (no match fields) reads as before', () {
      final product = SuggestedProductDto.fromJson(const {
        'productId': 'p-3',
        'name': 'Cap',
        'price': 500,
      }).toDomain();

      expect(product.productName, 'Cap');
      expect(product.price.amount, 500);
      expect(product.matchPercent, isNull);
    });
  });

  group('datasource', () {
    test('sends the caption and a limit; reads the rows', () async {
      final api = _Api(const {
        'items': [_meaningRow],
        'aiApplied': true,
      });
      final rows = await ReelImportRemoteDataSource(
        apiClient: api,
      ).getSuggestedProducts(
        platform: SocialPlatform.instagram,
        externalId: 'post 1',
        caption: '  Summer linen  ',
      );

      expect(api.path, '/v1/creator/reels/post%201/suggested-products');
      expect(api.query?['caption'], 'Summer linen');
      expect(api.query?['limit'], 10);
      expect(rows.single.isMeaningMatch, isTrue);
    });

    test('a 404 (not deployed) is no suggestions, not an error', () async {
      final rows = await ReelImportRemoteDataSource(
        apiClient: _Api(null),
      ).getSuggestedProducts(
        platform: SocialPlatform.instagram,
        externalId: 'post-1',
      );

      expect(rows, isEmpty);
    });
  });

  group('TagProductsScreen', () {
    testWidgets('a meaning match shows its score and reason; one tap tags '
        'it', (tester) async {
      final repo = await _pumpScreen(tester, [_meaningRow]);

      expect(repo.caption, 'Summer linen #summer #linen');
      expect(find.text('Suggested Products (Based on your reel)'), findsOneWidget);
      expect(find.text('86% match'), findsOneWidget);
      expect(
        find.text("Close in meaning to this reel's caption and #summer #linen"),
        findsOneWidget,
      );

      await tester.tap(find.text('Tag').first);
      await tester.pumpAndSettle();

      // Tagged: it leaves the suggestions in one tap.
      expect(find.text('86% match'), findsNothing);
      expect(
        find.text('You’ve tagged all the suggested products'),
        findsOneWidget,
      );
    });

    testWidgets('a fallback list is not scored nor called based on the reel', (
      tester,
    ) async {
      await _pumpScreen(tester, [_fallbackRow]);

      expect(find.text('Products you can tag'), findsOneWidget);
      expect(
        find.text('Suggested Products (Based on your reel)'),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('suggested-match-chip')), findsNothing);
      expect(find.text('One of your products'), findsNothing);
      expect(find.text('Wool shawl'), findsOneWidget);
    });
  });
}
