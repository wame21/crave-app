import 'dart:convert';
import '../models/restaurant_model.dart';
import 'api_client.dart';

class RestaurantService {
  static Future<Map<String, List<RestaurantModel>>> getHomeData() async {
    final response = await ApiClient.get('/restaurants/home');
    ApiClient.handleResponse(response);

    final data = jsonDecode(response.body);
    
    List<RestaurantModel> destacados = (data['destacados'] as List)
        .map((e) => RestaurantModel.fromJson(e))
        .toList();
        
    List<RestaurantModel> mejorValorados = (data['mejor_valorados'] as List)
        .map((e) => RestaurantModel.fromJson(e))
        .toList();
        
    List<RestaurantModel> novedades = (data['novedades'] as List)
        .map((e) => RestaurantModel.fromJson(e))
        .toList();

    return {
      'destacados': destacados,
      'mejor_valorados': mejorValorados,
      'novedades': novedades,
    };
  }

  static Future<List<RestaurantModel>> listRestaurants({String? query, String? category}) async {
    String url = '/restaurants/?';
    if (query != null && query.isNotEmpty) url += 'q=$query&';
    if (category != null && category.isNotEmpty) url += 'category=$category&';

    final response = await ApiClient.get(url);
    ApiClient.handleResponse(response);

    final data = jsonDecode(response.body);
    return (data['restaurants'] as List).map((e) => RestaurantModel.fromJson(e)).toList();
  }

  static Future<RestaurantModel> getRestaurant(int id) async {
    final response = await ApiClient.get('/restaurants/$id');
    ApiClient.handleResponse(response);
    return RestaurantModel.fromJson(jsonDecode(response.body));
  }

  static Future<RestaurantModel> getMyRestaurant() async {
    final response = await ApiClient.get('/restaurants/me');
    ApiClient.handleResponse(response);
    return RestaurantModel.fromJson(jsonDecode(response.body));
  }

  static Future<RestaurantModel> updateRestaurant(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/restaurants/$id', body: data);
    ApiClient.handleResponse(response);
    return RestaurantModel.fromJson(jsonDecode(response.body));
  }

  static Future<List<String>> getCategories() async {
    final response = await ApiClient.get('/restaurants/categories');
    ApiClient.handleResponse(response);
    final data = jsonDecode(response.body);
    return List<String>.from(data['categories']);
  }
}
