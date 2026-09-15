import 'package:shared_preferences/shared_preferences.dart';

/// Where the Discover tab keeps its recent searches.
abstract interface class RecentSearchesStore {
  Future<List<String>> read();

  Future<void> write(List<String> terms);
}

/// Recent searches in `shared_preferences`, on this device only.
class SharedPreferencesRecentSearchesStore implements RecentSearchesStore {
  const SharedPreferencesRecentSearchesStore();

  static const String storageKey = 'discover.recent_searches';

  @override
  Future<List<String>> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(storageKey) ?? const [];
  }

  @override
  Future<void> write(List<String> terms) async {
    final preferences = await SharedPreferences.getInstance();
    if (terms.isEmpty) {
      await preferences.remove(storageKey);
    } else {
      await preferences.setStringList(storageKey, terms);
    }
  }
}
