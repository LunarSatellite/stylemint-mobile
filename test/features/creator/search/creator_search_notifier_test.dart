import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/entities/creator_search_result.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/repositories/creator_search_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/presentation/notifiers/creator_search_notifier.dart';

/// Slightly longer than the notifier's 350ms debounce.
const _pastDebounce = Duration(milliseconds: 450);

class _FakeRepository implements CreatorSearchRepository {
  _FakeRepository({this.brands, this.products, this.creators});

  NetworkEither<List<SearchBrandResult>>? brands;
  NetworkEither<List<SearchProductResult>>? products;
  NetworkEither<List<SearchCreatorResult>>? creators;

  final List<String> brandQueries = [];
  int brandCalls = 0;
  int productCalls = 0;
  int creatorCalls = 0;

  @override
  Future<NetworkEither<List<SearchBrandResult>>> searchBrands(
    String query,
  ) async {
    brandCalls++;
    brandQueries.add(query);
    return brands ?? networkRight([_brand()]);
  }

  @override
  Future<NetworkEither<List<SearchProductResult>>> searchProducts(
    String query,
  ) async {
    productCalls++;
    return products ?? networkRight(<SearchProductResult>[]);
  }

  @override
  Future<NetworkEither<List<SearchCreatorResult>>> searchCreators(
    String query,
  ) async {
    creatorCalls++;
    return creators ?? networkRight(<SearchCreatorResult>[]);
  }
}

SearchBrandResult _brand() => const SearchBrandResult(
      brandId: 'b1',
      name: 'Brand One',
      averageRating: 4.5,
      productCount: 12,
      commissionRange: '5-10%',
    );

void main() {
  group('CreatorSearchNotifier', () {
    test('starts idle and defaults to the brands tab', () {
      final notifier = CreatorSearchNotifier(_FakeRepository());

      expect(notifier.state, isA<CreatorSearchIdle>());
      expect(notifier.type, CreatorSearchType.brands);
    });

    test('a query resolves to results for the active tab', () async {
      final repo = _FakeRepository();
      final notifier = CreatorSearchNotifier(repo);

      notifier.onQueryChanged('shoes');
      await Future<void>.delayed(_pastDebounce);

      expect(notifier.state, isA<CreatorSearchBrandsLoaded>());
      expect((notifier.state as CreatorSearchBrandsLoaded).results, hasLength(1));
      expect(repo.brandQueries.single, 'shoes');
    });

    test('debounces rapid typing into a single request', () async {
      final repo = _FakeRepository();
      final notifier = CreatorSearchNotifier(repo);

      notifier
        ..onQueryChanged('s')
        ..onQueryChanged('sh')
        ..onQueryChanged('sho')
        ..onQueryChanged('shoe');
      await Future<void>.delayed(_pastDebounce);

      expect(repo.brandCalls, 1);
      expect(repo.brandQueries.single, 'shoe');
    });

    test('clearing the query returns to idle without searching', () async {
      final repo = _FakeRepository();
      final notifier = CreatorSearchNotifier(repo);

      notifier.onQueryChanged('  ');
      await Future<void>.delayed(_pastDebounce);

      expect(notifier.state, isA<CreatorSearchIdle>());
      expect(repo.brandCalls, 0);
    });

    test('surfaces the repository message rather than a generic prompt',
        () async {
      final repo = _FakeRepository(
        brands: networkLeft(const NetworkExceptions.noInternetConnection()),
      );
      final notifier = CreatorSearchNotifier(repo);

      notifier.onQueryChanged('shoes');
      await Future<void>.delayed(_pastDebounce);

      expect(notifier.state, isA<CreatorSearchFailed>());
      expect(
        (notifier.state as CreatorSearchFailed).message,
        'No internet connection.',
      );
    });

    test('switching tabs re-runs the current query against the new type',
        () async {
      final repo = _FakeRepository();
      final notifier = CreatorSearchNotifier(repo);

      notifier.onQueryChanged('shoes');
      await Future<void>.delayed(_pastDebounce);
      notifier.setType(CreatorSearchType.creators);
      await Future<void>.delayed(_pastDebounce);

      expect(repo.creatorCalls, 1);
      expect(notifier.state, isA<CreatorSearchCreatorsLoaded>());
    });

    test('switching tabs with no query stays idle', () async {
      final repo = _FakeRepository();
      final notifier = CreatorSearchNotifier(repo);

      notifier.setType(CreatorSearchType.products);
      await Future<void>.delayed(_pastDebounce);

      expect(notifier.state, isA<CreatorSearchIdle>());
      expect(repo.productCalls, 0);
    });

    test('setting the same tab twice does not re-search', () async {
      final repo = _FakeRepository();
      final notifier = CreatorSearchNotifier(repo);

      notifier.onQueryChanged('shoes');
      await Future<void>.delayed(_pastDebounce);
      notifier.setType(CreatorSearchType.brands);
      await Future<void>.delayed(_pastDebounce);

      expect(repo.brandCalls, 1);
    });

    test('a pending debounce does not fire after dispose', () async {
      final repo = _FakeRepository();
      final notifier = CreatorSearchNotifier(repo)..onQueryChanged('shoes');

      notifier.dispose();
      await Future<void>.delayed(_pastDebounce);

      expect(repo.brandCalls, 0);
    });
  });
}
