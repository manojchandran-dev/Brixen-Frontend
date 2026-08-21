import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  TokenService._();

  static const _kToken        = 'auth_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kRole         = 'auth_role';

  static String? _token;
  static String? _refreshToken;
  static String? _role;

  static String? get token        => _token;
  static String? get refreshToken => _refreshToken;
  static String? get role         => _role;
  static bool   get isLoggedIn    => _token != null && _token!.isNotEmpty;

  /// Call once in main() before runApp — loads tokens from disk into memory.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token        = prefs.getString(_kToken);
    _refreshToken = prefs.getString(_kRefreshToken);
    _role         = prefs.getString(_kRole);
  }

  /// Persist tokens + role after a successful login.
  static Future<void> save({
    required String token,
    required String role,
    String? refreshToken,
  }) async {
    _token        = token;
    _role         = role;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kToken, token),
      prefs.setString(_kRole, role),
      if (refreshToken != null)
        prefs.setString(_kRefreshToken, refreshToken),
    ]);
  }

  /// Remove all tokens on logout.
  static Future<void> clear() async {
    _token        = null;
    _refreshToken = null;
    _role         = null;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kToken),
      prefs.remove(_kRefreshToken),
      prefs.remove(_kRole),
    ]);
  }
}
