import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3000/api';

  static Future<List<dynamic>> getRestaurants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/restaurants'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error de conexión loco: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'message': data['error']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión w'};
    }
  }

  static Future<Map<String, dynamic>> registerUser(
    String name,
    String email,
    String password,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'profile_name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'message': data['error']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión w'};
    }
  }

  static Future<void> guardarSesion(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  static Future<String?> obtenerUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  static Future<Map<String, dynamic>?> obtenerPerfil(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> obtenerFavoritos(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/favorites/$userId'));
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> obtenerResenasPropias(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/user/$userId'),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> actualizarFotoPerfil(String userId, XFile imagen) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/$userId/photo'),
      );
      final bytes = await imagen.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('photo', bytes, filename: imagen.name),
      );
      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checarSiEsFavorito(
    String userId,
    String restaurantId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorites/check/$userId/$restaurantId'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> agregarFavorito(
    String userId,
    String restaurantId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favorites'),
        headers: {'Content-Type': 'application/json'},
        // <-- ¡AQUÍ ESTÁ LA CORRECCIÓN W! -->
        body: json.encode({'id_user': userId, 'id_restaurant': restaurantId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> quitarFavorito(String userId, String restaurantId) async {
    try {
      final request = http.Request('DELETE', Uri.parse('$baseUrl/favorites'));
      request.headers.addAll({'Content-Type': 'application/json'});
      // <-- ¡AQUÍ ESTÁ LA CORRECCIÓN W! -->
      request.body = json.encode({
        'id_user': userId,
        'id_restaurant': restaurantId,
      });
      final response = await http.Client().send(request);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> crearResena(
    String userId,
    String restaurantId,
    String rating,
    String comment,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        // <-- ¡AQUÍ ESTÁ LA CORRECCIÓN W! -->
        body: json.encode({
          'id_user': userId,
          'id_restaurant': restaurantId,
          'overall_rating': double.parse(rating),
          'comment': comment,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> obtenerResenasRestaurante(
    String restaurantId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/restaurant/$restaurantId'),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }
}
