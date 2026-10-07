import '../models/restaurant_model.dart';
import 'api_client.dart';

abstract class RestaurantService {
  Future<Map<String, List<RestaurantModel>>> getHomeData();
  Future<List<RestaurantModel>> listRestaurants({String? query, String? category});
  Future<RestaurantModel> getRestaurant(int id);
  Future<RestaurantModel> getMyRestaurant();
  Future<RestaurantModel> updateRestaurant(int id, Map<String, dynamic> data);
  Future<List<String>> getCategories();
}

class HttpRestaurantService implements RestaurantService {
  final ApiClient _api;

  HttpRestaurantService(this._api);

  @override
  Future<Map<String, List<RestaurantModel>>> getHomeData() async {
    final data = _api.decode(await _api.get('/restaurants/home'));

    List<RestaurantModel> parse(String key) =>
        (data[key] as List).map((e) => RestaurantModel.fromJson(e)).toList();

    return {
      'destacados': parse('destacados'),
      'mejor_valorados': parse('mejor_valorados'),
      'novedades': parse('novedades'),
    };
  }

  @override
  Future<List<RestaurantModel>> listRestaurants({String? query, String? category}) async {
    final response = await _api.get('/restaurants/', query: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (category != null && category.isNotEmpty) 'category': category,
    });
    final data = _api.decode(response);
    return (data['restaurants'] as List).map((e) => RestaurantModel.fromJson(e)).toList();
  }

  @override
  Future<RestaurantModel> getRestaurant(int id) async {
    return RestaurantModel.fromJson(_api.decode(await _api.get('/restaurants/$id')));
  }

  @override
  Future<RestaurantModel> getMyRestaurant() async {
    return RestaurantModel.fromJson(_api.decode(await _api.get('/restaurants/me')));
  }

  @override
  Future<RestaurantModel> updateRestaurant(int id, Map<String, dynamic> data) async {
    return RestaurantModel.fromJson(_api.decode(await _api.put('/restaurants/$id', body: data)));
  }

  @override
  Future<List<String>> getCategories() async {
    final data = _api.decode(await _api.get('/restaurants/categories'));
    return List<String>.from(data['categories']);
  }
}
