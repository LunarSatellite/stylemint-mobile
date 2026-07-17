import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/data/datasources/creator_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/entities/creator_search_result.dart';

sealed class CreatorSearchState {}

class CreatorSearchIdle extends CreatorSearchState {}

class CreatorSearchLoading extends CreatorSearchState {}

class CreatorSearchBrandsLoaded extends CreatorSearchState {
  CreatorSearchBrandsLoaded(this.results);
  final List<SearchBrandResult> results;
}

class CreatorSearchProductsLoaded extends CreatorSearchState {
  CreatorSearchProductsLoaded(this.results);
  final List<SearchProductResult> results;
}

class CreatorSearchCreatorsLoaded extends CreatorSearchState {
  CreatorSearchCreatorsLoaded(this.results);
  final List<SearchCreatorResult> results;
}

class CreatorSearchFailed extends CreatorSearchState {
  CreatorSearchFailed(this.message);
  final String message;
}

/// Debounced, type-scoped search for the creator-facing search screen.
/// Defaults to Brands (partnership discovery) since that's the most
/// distinctly creator-specific use case; Products and Creators tabs cover
/// "find something to make content about" and "find other creators".
class CreatorSearchNotifier extends StateNotifier<CreatorSearchState> {
  CreatorSearchNotifier(this._dataSource) : super(CreatorSearchIdle());

  final CreatorSearchRemoteDataSource _dataSource;

  CreatorSearchType _type = CreatorSearchType.brands;
  String _query = '';
  Timer? _debounce;

  CreatorSearchType get type => _type;

  void setType(CreatorSearchType type) {
    if (_type == type) return;
    _type = type;
    if (_query.trim().isNotEmpty) {
      unawaited(_runSearch(_query));
    } else {
      state = CreatorSearchIdle();
    }
  }

  void onQueryChanged(String query) {
    _query = query;
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = CreatorSearchIdle();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_runSearch(query));
    });
  }

  Future<void> _runSearch(String query) async {
    state = CreatorSearchLoading();
    try {
      switch (_type) {
        case CreatorSearchType.brands:
          state = CreatorSearchBrandsLoaded(await _dataSource.searchBrands(query));
        case CreatorSearchType.products:
          state = CreatorSearchProductsLoaded(await _dataSource.searchProducts(query));
        case CreatorSearchType.creators:
          state = CreatorSearchCreatorsLoaded(await _dataSource.searchCreators(query));
      }
    } on Object catch (_) {
      state = CreatorSearchFailed('Search failed. Please try again.');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
