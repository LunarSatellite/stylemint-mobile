import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/search_suggestions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discover_repository.dart';

/// Live suggestions for the Discover search field.
sealed class SearchSuggestState {
  const SearchSuggestState();

  /// The normalized query this state is for; empty when idle.
  String get query;
}

/// The query is shorter than [minSuggestQueryLength]: show recent searches.
final class SuggestIdle extends SearchSuggestState {
  const SuggestIdle();

  @override
  String get query => '';
}

/// Waiting for the debounce or the server. [previous] keeps the last
/// results on screen while typing.
final class SuggestLoading extends SearchSuggestState {
  const SuggestLoading({required this.query, this.previous});

  @override
  final String query;
  final SearchSuggestions? previous;
}

final class SuggestLoaded extends SearchSuggestState {
  const SuggestLoaded({required this.query, required this.suggestions});

  @override
  final String query;
  final SearchSuggestions suggestions;
}

final class SuggestFailure extends SearchSuggestState {
  const SuggestFailure({required this.query, required this.failure});

  @override
  final String query;
  final NetworkExceptions failure;
}

/// Debounces the field and fetches grouped suggestions. Only the latest
/// query's answer is ever shown.
class SearchSuggestNotifier extends StateNotifier<SearchSuggestState> {
  SearchSuggestNotifier(
    this._repository, {
    this.debounce = defaultDebounce,
    this.limit = defaultLimit,
  }) : super(const SuggestIdle());

  static const Duration defaultDebounce = Duration(milliseconds: 250);
  static const int defaultLimit = 8;

  /// The server's answer to a query under two characters.
  static const String tooShortCode = 'validation.too_short';

  final DiscoverRepository _repository;
  final Duration debounce;
  final int limit;

  Timer? _timer;
  int _generation = 0;

  /// Call on every edit of the field.
  void onQueryChanged(String raw) {
    final query = normalizeSuggestQuery(raw);
    if (query.length < minSuggestQueryLength) {
      clear();
      return;
    }
    if (query == state.query) return;
    _timer?.cancel();
    final generation = ++_generation;
    state = SuggestLoading(query: query, previous: _latest);
    _timer = Timer(debounce, () => unawaited(_fetch(query, generation)));
  }

  /// Fetches the current query again, without waiting for the debounce.
  void retry() {
    final query = state.query;
    if (query.length < minSuggestQueryLength) return;
    _timer?.cancel();
    final generation = ++_generation;
    state = SuggestLoading(query: query, previous: _latest);
    unawaited(_fetch(query, generation));
  }

  /// Drops pending work and returns to idle.
  void clear() {
    _timer?.cancel();
    _generation++;
    if (state is! SuggestIdle) state = const SuggestIdle();
  }

  SearchSuggestions? get _latest => switch (state) {
    SuggestLoaded(:final suggestions) => suggestions,
    SuggestLoading(:final previous) => previous,
    _ => null,
  };

  Future<void> _fetch(String query, int generation) async {
    final result = await _repository.suggest(query, limit: limit);
    if (!mounted || generation != _generation) return;
    state = result.fold<SearchSuggestState>(
      (failure) => failure.validationCode == tooShortCode
          ? const SuggestIdle()
          : SuggestFailure(query: query, failure: failure),
      (suggestions) => SuggestLoaded(query: query, suggestions: suggestions),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
