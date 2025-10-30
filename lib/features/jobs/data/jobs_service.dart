import 'dart:convert';
import '../../../core/api_client.dart';

class JobItem {
  JobItem({
    required this.title,
    required this.company,
    required this.location,
    required this.url,
    this.source,
    this.contractTime,
    this.contractType,
  });

  final String title;
  final String company;
  final String location;
  final String url;
  final String? source;
  final String? contractTime; // full_time | part_time
  final String? contractType; // permanent | contract

  factory JobItem.fromJson(Map<String, dynamic> j) => JobItem(
        title: (j['title'] ?? '') as String,
        company: (j['company'] ?? '') as String,
        location: (j['location'] ?? '') as String,
        url: (j['url'] ?? '') as String,
        source: j['source'] as String?,
        contractTime: j['contract_time'] as String?,
        contractType: j['contract_type'] as String?,
      );
}

class JobsSearchResult {
  JobsSearchResult({required this.items, this.total});
  final List<JobItem> items;
  final int? total;
}

class JobsService {
  JobsService(this._api);
  final ApiClient _api;

  Future<JobsSearchResult> search({
    String? q,
    String? location,
    bool? remote,
    int? minSalary,
    String? sort, // relevance|date|salary
  }) async {
    final query = <String, dynamic>{'with_meta': true};
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (location != null && location.isNotEmpty) query['location'] = location;
    if (remote != null) query['remote'] = remote;
    if (minSalary != null) query['min_salary'] = minSalary;
    if (sort != null && sort.isNotEmpty) query['sort'] = sort;
    final r = await _api.get('/api/jobs/search', query: query);
    final decoded = jsonDecode(r.body);
    if (decoded is List) {
      final items = decoded.map<JobItem>((e) => JobItem.fromJson(e as Map<String, dynamic>)).toList();
      return JobsSearchResult(items: items, total: null);
    } else if (decoded is Map<String, dynamic>) {
      final List itemsRaw = decoded['items'] as List? ?? const [];
      final items = itemsRaw.map<JobItem>((e) => JobItem.fromJson(e as Map<String, dynamic>)).toList();
      final total = (decoded['total'] as num?)?.toInt();
      return JobsSearchResult(items: items, total: total);
    }
    return JobsSearchResult(items: const [], total: null);
  }
}
