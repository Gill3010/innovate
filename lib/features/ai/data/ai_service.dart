import 'dart:convert';
import '../../../core/api_client.dart';

class AiService {
  AiService(this._api);
  final ApiClient _api;

  Future<String> careerChat(String message) async {
    final r = await _api.post('/api/ai/career-chat', body: {'message': message});
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    return (j['reply'] ?? '') as String;
  }
}


