import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'token_store.dart';

abstract class AuthService {
  Future<bool> isLoggedIn();
  Future<String?> getRole();
  Future<void> logout();
  Future<void> login(String email, String password);
  Future<void> registerClient(String name, String email, String password, String confirmPassword);
  Future<void> registerOwner(String name, String email, String password, String confirmPassword, String restaurantName, String foodType);
}

class HttpAuthService implements AuthService {
  final ApiClient _api;
  final TokenStore _tokenStore;

  HttpAuthService(this._api, this._tokenStore);

  @override
  Future<bool> isLoggedIn() async => await _tokenStore.readToken() != null;

  @override
  Future<String?> getRole() => _tokenStore.readRole();

  @override
  Future<void> logout() => _tokenStore.clear();

  @override
  Future<void> login(String email, String password) async {
    final response = await _api.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    await _saveSession(response);
  }

  @override
  Future<void> registerClient(String name, String email, String password, String confirmPassword) async {
    final response = await _api.post(
      '/auth/register/client',
      body: {
        'profile_name': name,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );
    await _saveSession(response);
  }

  @override
  Future<void> registerOwner(String name, String email, String password, String confirmPassword, String restaurantName, String foodType) async {
    final response = await _api.post(
      '/auth/register/owner',
      body: {
        'profile_name': name,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'restaurant_name': restaurantName,
        'food_type': foodType,
      },
    );
    await _saveSession(response);
  }

  Future<void> _saveSession(http.Response response) async {
    final data = _api.decode(response) as Map<String, dynamic>;
    await _tokenStore.save(AuthSession.fromJson(data));
  }
}
