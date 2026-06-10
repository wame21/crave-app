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
        // ¡AUTOMÁTICO! Guardamos el rol en la sesión w
        final user = data['user'];
        if (user != null && user['role'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', user['role'].toString());
        }
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
        // ¡AUTOMÁTICO! Guardamos el rol también al registrar
        final user = data['user'];
        if (user != null && user['role'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', user['role'].toString());
        }
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
    await prefs.remove('user_role'); // Limpiamos el rol al salir w
  }

  static Future<Map<String, dynamic>?> obtenerPerfil(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId'));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- 1. AGREGAR A FAVORITOS ---
  static Future<bool> agregarFavorito(
    String idClient,
    String idRestaurant,
  ) async {
    try {
      final response = await http.post(
        // AQUÍ ESTÁ LA CORRECCIÓN DE LA RUTA W
        Uri.parse('$baseUrl/favorite_restaurants'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_client': idClient,
          'id_restaurant': idRestaurant,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error al agregar favorito: $e');
      return false;
    }
  }

  // --- 2. QUITAR DE FAVORITOS ---
  static Future<bool> quitarFavorito(
    String idClient,
    String idRestaurant,
  ) async {
    try {
      // Para hacer un DELETE enviando datos en el body (como lo tienes en Node), se hace así:
      final request = http.Request(
        'DELETE',
        Uri.parse('$baseUrl/favorite_restaurants'),
      );
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = json.encode({
        'id_client': idClient,
        'id_restaurant': idRestaurant,
      });

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error al quitar favorito: $e');
      return false;
    }
  }

  // --- 3. CHECAR SI YA ES FAVORITO (Al abrir la pantalla) ---
  static Future<bool> checarSiEsFavorito(
    String idClient,
    String idRestaurant,
  ) async {
    try {
      final response = await http.get(
        // AQUÍ TAMBIÉN CORREGIMOS LA RUTA W
        Uri.parse(
          '$baseUrl/favorite_restaurants/check/$idClient/$idRestaurant',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error al checar favorito: $e');
      return false;
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

  // --- MANDAR RESEÑA NUEVA ---
  static Future<bool> crearResena(Map<String, dynamic> datos) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/reviews',
        ), // Asegúrate de que $baseUrl sea tu variable de conexión
        headers: {'Content-Type': 'application/json'},
        body: json.encode(datos),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error loco al mandar reseña: $e');
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

  // --- TRAER MIS PROPIAS RESEÑAS ---
  static Future<List<dynamic>> obtenerMisResenas(String userId) async {
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

  // Busca si el dueño ya tiene datos guardados
  static Future<Map<String, dynamic>?> obtenerMiRestaurante(
    String userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/restaurants/owner/$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data.isEmpty ? null : data; // Regresa null si está vacío
      }
      return null;
    } catch (e) {
      print('Error loco al traer mi restaurante: $e');
      return null;
    }
  }

  // Manda a guardar todos los campos de texto
  static Future<bool> guardarDatosRestaurante(
    Map<String, dynamic> datos,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/restaurants/upsert'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(datos),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error loco al guardar: $e');
      return false;
    }
  }

  // --- TRAER LA LISTA DE FAVORITOS DEL USUARIO ---
  static Future<List<dynamic>> obtenerFavoritos(String idClient) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favorite_restaurants/$idClient'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error al traer la lista de favoritos w: $e');
      return [];
    }
  }
}
