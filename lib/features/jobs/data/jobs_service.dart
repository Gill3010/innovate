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

class JobsService {
  JobsService(this._api);
  final ApiClient _api;

  Future<List<JobItem>> search({
    String? q,
    String? location,
    bool? remote,
    int? minSalary,
    int? maxSalary,
    String? country,
    String? contractTime, // full_time | part_time
    String? contractType, // permanent | contract
    int page = 1,
    int perPage = 20,
    int? distanceKm,
    int? maxDaysOld,
  }) async {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};
    if (q != null && q.isNotEmpty) query['q'] = q;
    if (location != null && location.isNotEmpty) query['location'] = location;
    if (remote != null) query['remote'] = remote;
    if (minSalary != null) query['min_salary'] = minSalary;
    if (maxSalary != null) query['max_salary'] = maxSalary;
    if (country != null && country.isNotEmpty) query['country'] = country;
    if (contractTime != null && contractTime.isNotEmpty)
      query['contract_time'] = contractTime;
    if (contractType != null && contractType.isNotEmpty)
      query['contract_type'] = contractType;
    if (distanceKm != null) query['distance_km'] = distanceKm;
    if (maxDaysOld != null) query['max_days_old'] = maxDaysOld;
    final r = await _api.get('/api/jobs/search', query: query);
    final List data = jsonDecode(r.body) as List;
    return data
        .map((e) => JobItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
