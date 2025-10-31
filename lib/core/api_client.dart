import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'dart:io' show Platform, NetworkInterface, InternetAddressType;
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/data/auth_store.dart';

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? _resolveDefaultBaseUrl();

  static String? _cachedLocalIp;
  static Future<String?> _getLocalIp() async {
    if (_cachedLocalIp != null) return _cachedLocalIp;
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Prefer IPv4, non-loopback, private network addresses
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.isLoopback &&
              (addr.address.startsWith('192.168.') ||
               addr.address.startsWith('10.') ||
               addr.address.startsWith('172.'))) {
            _cachedLocalIp = addr.address;
            return _cachedLocalIp;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String _resolveDefaultBaseUrl() {
    // Check for environment variable first (set during build)
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    
    // In release mode (production)
    if (kReleaseMode) {
      // Check for explicit production URL
      const prodUrl = String.fromEnvironment('PROD_API_URL');
      if (prodUrl.isNotEmpty) return prodUrl;
      
      // In web release mode, use the production Cloud Run backend URL
      if (kIsWeb) {
        // Production backend URL (Cloud Run)
        return 'https://innova-backend-zkniivwjuq-uc.a.run.app';
      }
      
      // For mobile release builds, fail if no URL is configured
      throw Exception('Production API URL not configured. Build with --dart-define=API_BASE_URL=<your-url>');
    }
    
    // Development mode
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) {
        // Default to emulator IP; async method will detect physical device IP
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  static Future<String> get defaultBaseUrl async {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    
    // In release mode web, use production URL
    if (kReleaseMode && kIsWeb) {
      const prodUrl = String.fromEnvironment('PROD_API_URL');
      if (prodUrl.isNotEmpty) return prodUrl;
      return 'https://innova-backend-zkniivwjuq-uc.a.run.app';
    }
    
    // Development mode
    if (kIsWeb) return 'http://127.0.0.1:8000';
    
    try {
      if (Platform.isAndroid) {
        // For Android, use the same baseUrl as the ApiClient instance
        // This ensures images use the same endpoint as API calls
        final instance = ApiClient();
        return instance.baseUrl;
      } else if (Platform.isIOS) {
        // For iOS, try to detect local IP for physical devices
        final localIp = await _getLocalIp();
        if (localIp != null && !localIp.startsWith('127.')) {
          // Physical device with detected IP
          return 'http://$localIp:8000';
        }
        // Simulator or no IP detected, use localhost
        return 'http://127.0.0.1:8000';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  final String baseUrl;
  
  // Helper to get base URL asynchronously for share URLs
  static Future<String> getBaseUrlAsync() => defaultBaseUrl;

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

  Future<http.Response> delete(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final resp = await http.delete(
      _uri(path, query),
      headers: await _headers(),
    );
    _ensureOk(resp);
    return resp;
  }

  Future<Map<String, String>> _headers() async {
    String? token = AuthStore.instance.tokenValue; // prefer in-memory
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('jwt_token');
    }
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
