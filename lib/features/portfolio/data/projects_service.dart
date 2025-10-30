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

  final int id;
  final String title;
  final String description;
  final String technologies;
  final String category;
  final bool featured;
  final String images; // JSON array string
  final String links; // JSON array string

  factory ProjectItem.fromJson(Map<String, dynamic> j) => ProjectItem(
    id: j['id'] as int,
    title: (j['title'] ?? '') as String,
    description: (j['description'] ?? '') as String,
    technologies: (j['technologies'] ?? '') as String,
    category: (j['category'] ?? 'general') as String,
    featured: (j['featured'] ?? false) as bool,
    images: (j['images'] ?? '') as String,
    links: (j['links'] ?? '') as String,
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

  Future<ProjectItem> getById(int id) async {
    final r = await _api.get('/api/projects/$id');
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    return ProjectItem.fromJson(j);
  }

  Future<int> create({
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
    return (j['id'] as num).toInt();
  }

  Future<void> update(
    int id, {
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

  Future<void> delete(int id) async {
    await _api.delete('/api/projects/$id');
  }

  Future<String> share(int id) async {
    final r = await _api.post('/api/projects/$id/share');
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    return (j['share_url'] ?? '') as String;
  }

  Future<String> sharePortfolio() async {
    final r = await _api.post('/api/projects/portfolio/share');
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    return (j['share_url'] ?? '') as String;
  }
}
