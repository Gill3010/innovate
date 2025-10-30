import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_client.dart';
import '../../auth/data/auth_store.dart';

class FavoritesStore {
  static const _kFavs = 'job_favorites';
  static const _kSavedSearches = 'job_saved_searches';
  static const _kLastCounts = 'job_last_counts';

  final ApiClient _api = ApiClient();

  Future<Set<String>> loadFavorites() async {
    if (AuthStore.instance.isLoggedIn) {
      try {
        final r = await _api.get('/api/favorites/jobs');
        final List data = jsonDecode(r.body) as List;
        final set = <String>{};
        for (final e in data) {
          final m = e as Map<String, dynamic>;
          set.add(_keyFrom(m['title'] as String, m['company'] as String, m['url'] as String));
        }
        return set;
      } catch (_) {
        // fallback local
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kFavs) ?? const <String>[];
    return list.toSet();
  }

  Future<void> toggleFavoriteKey(String key, {Map<String, String>? payload}) async {
    if (AuthStore.instance.isLoggedIn && payload != null) {
      final isFav = (await loadFavorites()).contains(key);
      if (isFav) {
        await _api.delete('/api/favorites/jobs', query: {'url': payload['url'] ?? ''});
      } else {
        await _api.post('/api/favorites/jobs', body: {
          'title': payload['title'] ?? '',
          'company': payload['company'] ?? '',
          'location': payload['location'] ?? '',
          'url': payload['url'] ?? '',
          'source': payload['source'] ?? 'adzuna',
        });
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_kFavs) ?? const <String>[]).toSet();
    if (set.contains(key)) {
      set.remove(key);
    } else {
      set.add(key);
    }
    await prefs.setStringList(_kFavs, set.toList());
  }

  String _keyFrom(String title, String company, String url) => '$title|$company|$url';

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


