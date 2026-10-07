import 'dart:convert';
import '../models/favorite_model.dart';
import 'api_client.dart';

class FavoritesService {
  static Future<List<FavoriteModel>> getMyFavorites() async {
    final response = await ApiClient.get('/favorites/');
    ApiClient.handleResponse(response);
    final data = jsonDecode(response.body);
    return (data['favorites'] as List).map((e) => FavoriteModel.fromJson(e)).toList();
  }

  static Future<FavoriteModel> addFavorite(int restaurantId) async {
    final response = await ApiClient.post('/favorites/$restaurantId');
    ApiClient.handleResponse(response);
    final data = jsonDecode(response.body);
    return FavoriteModel.fromJson(data['favorite']);
  }

  static Future<void> removeFavorite(int restaurantId) async {
    final response = await ApiClient.delete('/favorites/$restaurantId');
    ApiClient.handleResponse(response);
  }
}
