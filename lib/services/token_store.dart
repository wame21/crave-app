import 'package:shared_preferences/shared_preferences.dart';

/// Sesión que devuelve el backend al iniciar sesión o registrarse.
class AuthSession {
  final String token;
  final String role;
  final int userId;
  final String profileName;

  const AuthSession({
    required this.token,
    required this.role,
    required this.userId,
    required this.profileName,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['access_token'],
      role: json['role'],
      userId: json['user_id'],
      profileName: json['profile_name'],
    );
  }
}

/// Dónde se guarda la sesión. La app usa [SharedPrefsTokenStore];
/// las pruebas, una implementación en memoria.
abstract class TokenStore {
  Future<String?> readToken();
  Future<String?> readRole();
  Future<void> save(AuthSession session);
  Future<void> clear();
}

class SharedPrefsTokenStore implements TokenStore {
  static const String tokenKey = 'auth_token';
  static const String roleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String profileNameKey = 'profile_name';

  @override
  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    return (token == null || token.isEmpty) ? null : token;
  }

  @override
  Future<String?> readRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(roleKey);
  }

  @override
  Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, session.token);
    await prefs.setString(roleKey, session.role);
    await prefs.setInt(userIdKey, session.userId);
    await prefs.setString(profileNameKey, session.profileName);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(roleKey);
    await prefs.remove(userIdKey);
    await prefs.remove(profileNameKey);
  }
}
