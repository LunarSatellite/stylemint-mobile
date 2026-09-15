import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/recent_searches_local_datasource.dart';

/// The last [maxEntries] searches, newest first, each once (ignoring case).
class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier(this._store) : super(const []) {
    _loaded = _load();
  }

  static const int maxEntries = 8;

  final RecentSearchesStore _store;
  late final Future<void> _loaded;

  /// Completes once the saved list has been read.
  Future<void> get ready => _loaded;

  /// Moves [term] to the front.
  Future<void> add(String term) async {
    final value = term.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return;
    await _loaded;
    if (!mounted) return;
    final key = value.toLowerCase();
    await _save([
      value,
      ...state.where((entry) => entry.toLowerCase() != key),
    ]);
  }

  Future<void> remove(String term) async {
    await _loaded;
    if (!mounted) return;
    await _save([...state.where((entry) => entry != term)]);
  }

  Future<void> clear() async {
    await _loaded;
    if (!mounted) return;
    await _save(const []);
  }

  Future<void> _load() async {
    try {
      final saved = await _store.read();
      if (mounted) state = _normalize(saved);
    } on Object catch (_) {
      // Unreadable storage: start with no recent searches.
    }
  }

  Future<void> _save(List<String> terms) async {
    final next = _normalize(terms);
    state = next;
    try {
      await _store.write(next);
    } on Object catch (_) {
      // Kept in memory for this session.
    }
  }

  static List<String> _normalize(Iterable<String> terms) {
    final seen = <String>{};
    return [
      for (final term in terms.map((entry) => entry.trim()))
        if (term.isNotEmpty && seen.add(term.toLowerCase())) term,
    ].take(maxEntries).toList(growable: false);
  }
}
