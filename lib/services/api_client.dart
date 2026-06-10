import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web/Desktop
  // Change to your machine's IP address if testing on a real physical device on the same WiFi
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<http.Response> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      return await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  static Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      return await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  static Future<http.Response> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      return await http.delete(Uri.parse('$baseUrl$endpoint'), headers: headers);
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  static void handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    
    String errorMessage = 'Error ${response.statusCode}';
    try {
      final data = jsonDecode(response.body);
      if (data['detail'] != null) {
        errorMessage = data['detail'].toString();
      }
    } catch (_) {
      // Ignored
    }
    throw Exception(errorMessage);
  }
}
