import 'dart:convert';
import '../../../core/api_client.dart';
import 'auth_store.dart';

class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final r = await _api.post(
      '/api/auth/register',
      body: {'email': email, 'password': password},
    );
    // ignore body; if 201, created
    if (r.statusCode != 201) {
      throw Exception('Registro fallido: ${r.body}');
    }
  }

  Future<void> login({required String email, required String password}) async {
    final r = await _api.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
    final token = (j['access_token'] ?? '') as String;
    if (token.isEmpty) throw Exception('Token vacío');
    await AuthStore.instance.save(token);
  }

  Future<void> logout() async {
    await AuthStore.instance.clear();
  }
}
