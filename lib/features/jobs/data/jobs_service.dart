import 'dart:convert';
import '../../../core/api_client.dart';

class JobItem {
  JobItem({
    required this.title,
    required this.company,
    required this.location,
    required this.url,
    this.source,
  });

  final String title;
  final String company;
  final String location;
  final String url;
  final String? source;

  factory JobItem.fromJson(Map<String, dynamic> j) => JobItem(
        title: (j['title'] ?? '') as String,
        company: (j['company'] ?? '') as String,
        location: (j['location'] ?? '') as String,
        url: (j['url'] ?? '') as String,
        source: j['source'] as String?,
      );
}

class JobsService {
  JobsService(this._api);
  final ApiClient _api;

  Future<List<JobItem>> search({String? q, String? location, bool? remote, int? minSalary}) async {
    final query = <String, dynamic>{};
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (location != null && location.isNotEmpty) query['location'] = location;
    if (remote != null) query['remote'] = remote;
    if (minSalary != null) query['min_salary'] = minSalary;
    final r = await _api.get('/api/jobs/search', query: query);
    final List data = jsonDecode(r.body) as List;
    return data.map((e) => JobItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}


