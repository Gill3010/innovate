import 'dart:convert';
import '../../../core/api_client.dart';
import '../../auth/data/auth_store.dart';

class ProjectItem {
  ProjectItem({
    required this.id,
    required this.title,
    required this.description,
    required this.technologies,
    required this.category,
    required this.featured,
    this.images = '',
    this.links = '',
  });

  final String id; // String para compatibilidad con Firebase (puede ser string o int convertido)
  final String title;
  final String description;
  final String technologies;
  final String category;
  final bool featured;
  final String images; // JSON array string
  final String links; // JSON array string

  factory ProjectItem.fromJson(Map<String, dynamic> j) => ProjectItem(
    id: j['id']?.toString() ?? '', // Convertir int o string a string
    title: (j['title'] ?? '') as String,
    description: (j['description'] ?? '') as String,
    technologies: (j['technologies'] ?? '') as String,
    category: (j['category'] ?? 'general') as String,
    featured: (j['featured'] ?? false) as bool,
    // Manejar images como string o array (desde Firestore puede venir como array)
    images: () {
      final img = j['images'];
      if (img == null) return '';
      if (img is List) {
        // Si viene como array, convertirlo a string JSON
        return jsonEncode(img);
      }
      return img.toString();
    }(),
    // Manejar links como string o array
    links: () {
      final lnk = j['links'];
      if (lnk == null) return '';
      if (lnk is List) {
        // Si viene como array, convertirlo a string JSON
        return jsonEncode(lnk);
      }
      return lnk.toString();
    }(),
  );
}

class ProjectsService {
  ProjectsService(this._api);
  final ApiClient _api;

  Future<List<ProjectItem>> list({String? category, bool? featured}) async {
    final query = <String, dynamic>{};
    // Force server to return only current owner's projects when authenticated
    try {
      final token = AuthStore.instance.tokenValue;
      if (token != null && token.isNotEmpty) {
        query['owner'] = 'me';
      }
    } catch (_) {}
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (featured != null) query['featured'] = featured;
    final r = await _api.get('/api/projects', query: query);
    final List data = jsonDecode(r.body) as List;
    return data
        .map((e) => ProjectItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectItem> getById(String id) async {
    final r = await _api.get('/api/projects/$id');
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    return ProjectItem.fromJson(j);
  }

  Future<String> create({
    required String title,
    String description = '',
    String technologies = '',
    String category = 'general',
    bool featured = false,
    String images = '',
    String links = '',
  }) async {
    final r = await _api.post(
      '/api/projects',
      body: {
        'title': title,
        'description': description,
        'technologies': technologies,
        'category': category,
        'featured': featured,
        'images': images,
        'links': links,
      },
    );
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    return j['id']?.toString() ?? '';
  }

  Future<void> update(
    String id, {
    String? title,
    String? description,
    String? technologies,
    String? category,
    bool? featured,
    String? images,
    String? links,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (technologies != null) body['technologies'] = technologies;
    if (category != null) body['category'] = category;
    if (featured != null) body['featured'] = featured;
    if (images != null) body['images'] = images;
    if (links != null) body['links'] = links;
    await _api.put('/api/projects/$id', body: body);
  }

  Future<void> delete(String id) async {
    await _api.delete('/api/projects/$id');
  }

  Future<String> share(String id) async {
    final r = await _api.post('/api/projects/$id/share');
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    // Prefer share_page_url (HTML page) over share_url (JSON API)
    final relativeUrl = (j['share_page_url'] ?? j['share_url'] ?? '') as String;
    // Build absolute URL using the API's base URL
    if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) {
      return relativeUrl; // Already absolute
    }
    // Convert relative to absolute using the same baseUrl as API calls
    return '${_api.baseUrl}$relativeUrl';
  }

  Future<String> sharePortfolio() async {
    final r = await _api.post('/api/projects/portfolio/share');
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    // Prefer share_page_url (HTML page) over share_url (JSON API)
    final relativeUrl = (j['share_page_url'] ?? j['share_url'] ?? '') as String;
    // Build absolute URL using the API's base URL
    if (relativeUrl.startsWith('http://') || relativeUrl.startsWith('https://')) {
      return relativeUrl; // Already absolute
    }
    // Convert relative to absolute using the same baseUrl as API calls
    return '${_api.baseUrl}$relativeUrl';
  }

  Future<Map<String, dynamic>> getPublicProfile(String token) async {
    final r = await _api.get('/api/users/profile/$token');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  Future<List<ProjectItem>> listPortfolioByToken(String token) async {
    final r = await _api.get('/api/projects/portfolio/$token');
    final List data = jsonDecode(r.body) as List;
    return data
        .map((e) => ProjectItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PublicListResult> listPublic({
    int page = 1,
    int perPage = 20,
    String? q,
    String? category,
    String order = 'new',
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'order': order,
    };
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (category != null && category.isNotEmpty) query['category'] = category;
    final r = await _api.get('/api/projects/public', query: query);
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    final List items = (j['items'] as List? ?? const []);
    return PublicListResult(
      page: (j['page'] as num).toInt(),
      perPage: (j['per_page'] as num).toInt(),
      total: (j['total'] as num).toInt(),
      items: items
          .map((e) => ProjectItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PublicListResult {
  PublicListResult({
    required this.page,
    required this.perPage,
    required this.total,
    required this.items,
  });
  final int page;
  final int perPage;
  final int total;
  final List<ProjectItem> items;
}
