import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

class AuthStore {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  final _token = BehaviorSubject<String?>.seeded(null);
  Stream<String?> get token => _token.stream;
  bool get isLoggedIn => _token.value != null;
  String? get tokenValue => _token.value;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token.add(prefs.getString('jwt_token'));
  }

  Future<void> load() => init();

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    _token.add(token);
  }

  Future<void> save(String token) => saveToken(token);

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    _token.add(null);
  }

  Future<void> clear() => clearToken();
}
