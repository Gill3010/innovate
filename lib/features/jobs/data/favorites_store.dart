import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesStore {
  static const _kFavs = 'job_favorites';
  static const _kSavedSearches = 'job_saved_searches';
  static const _kLastCounts = 'job_last_counts';

  Future<Set<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kFavs) ?? const <String>[];
    return list.toSet();
  }

  Future<void> toggleFavorite(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_kFavs) ?? const <String>[]).toSet();
    if (set.contains(key)) {
      set.remove(key);
    } else {
      set.add(key);
    }
    await prefs.setStringList(_kFavs, set.toList());
  }

  Future<List<Map<String, String>>> loadSavedSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSavedSearches) ?? const <String>[];
    return raw.map((s) => Map<String, String>.from(jsonDecode(s) as Map)).toList();
  }

  Future<void> addSavedSearch({required String q, required String location, required bool remote}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kSavedSearches) ?? <String>[];
    final entry = jsonEncode({'q': q, 'location': location, 'remote': remote});
    if (!list.contains(entry)) {
      list.add(entry);
      await prefs.setStringList(_kSavedSearches, list);
    }
  }

  Future<Map<String, int>> loadLastCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kLastCounts);
    if (raw == null) return {};
    return Map<String, int>.from(jsonDecode(raw) as Map);
  }

  Future<void> saveLastCount(String key, int count) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await loadLastCounts();
    map[key] = count;
    await prefs.setString(_kLastCounts, jsonEncode(map));
  }
}


