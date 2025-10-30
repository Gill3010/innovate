import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../features/auth/data/auth_store.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  static String _resolveDefaultBaseUrl() {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  final String baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final u = Uri.parse('$baseUrl$path');
    if (query == null) return u;
    final q = query.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    return u.replace(queryParameters: {...u.queryParameters, ...q});
  }

  Future<http.Response> get(String path, {Map<String, dynamic>? query}) async {
    final resp = await http.get(_uri(path, query), headers: await _headers());
    _ensureOk(resp);
    return resp;
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final resp = await http.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    _ensureOk(resp);
    return resp;
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final resp = await http.put(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    _ensureOk(resp);
    return resp;
  }

  Future<http.Response> delete(String path) async {
    final resp = await http.delete(_uri(path), headers: await _headers());
    _ensureOk(resp);
    return resp;
  }

  Future<Map<String, String>> _headers() async {
    final token = AuthStore.instance.token; // in-memory after load/login
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _ensureOk(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw ApiError('HTTP ${r.statusCode}: ${r.body}');
  }
}

class ApiError implements Exception {
  ApiError(this.message);
  final String message;
  @override
  String toString() => message;
}
