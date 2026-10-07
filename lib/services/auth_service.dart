import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  static const String tokenKey = 'auth_token';
  static const String roleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String profileNameKey = 'profile_name';

  static Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, data['access_token']);
    await prefs.setString(roleKey, data['role']);
    await prefs.setInt(userIdKey, data['user_id']);
    await prefs.setString(profileNameKey, data['profile_name']);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(roleKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(roleKey);
    await prefs.remove(userIdKey);
    await prefs.remove(profileNameKey);
  }

  static Future<void> login(String email, String password) async {
    final response = await ApiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    ApiClient.handleResponse(response);
    final data = jsonDecode(response.body);
    await _saveAuthData(data);
  }

  static Future<void> registerClient(String name, String email, String password, String confirmPassword) async {
    final response = await ApiClient.post(
      '/auth/register/client',
      body: {
        'profile_name': name,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
      },
    );

    ApiClient.handleResponse(response);
    final data = jsonDecode(response.body);
    await _saveAuthData(data);
  }

  static Future<void> registerOwner(String name, String email, String password, String confirmPassword, String restaurantName, String foodType) async {
    final response = await ApiClient.post(
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

    ApiClient.handleResponse(response);
    final data = jsonDecode(response.body);
    await _saveAuthData(data);
  }
}
