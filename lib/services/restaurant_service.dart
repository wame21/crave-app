import '../models/page_model.dart';
import '../models/restaurant_model.dart';
import '../models/screen_models.dart';
import 'api_client.dart';

abstract class RestaurantService {
  /// Pantalla de inicio, compuesta por el BFF.
  Future<HomeData> getHomeData();

  /// Pantalla de detalle (restaurante, reseñas y favorito), compuesta por el BFF.
  Future<RestaurantScreenData> getRestaurantScreen(int id, {int reviewsLimit = 20});
  Future<PageModel<RestaurantModel>> listRestaurants({String? query, String? category, int limit = 50});
  Future<RestaurantModel> getRestaurant(int id);
  Future<RestaurantModel> getMyRestaurant();
  Future<RestaurantModel> updateRestaurant(int id, Map<String, dynamic> data);
  Future<List<String>> getCategories();
}

class HttpRestaurantService implements RestaurantService {
  final ApiClient _api;

  HttpRestaurantService(this._api);

  @override
  Future<HomeData> getHomeData() async {
    return HomeData.fromJson(_api.decode(await _api.get('/bff/home')));
  }

  @override
  Future<RestaurantScreenData> getRestaurantScreen(int id, {int reviewsLimit = 20}) async {
    final response = await _api.get('/bff/restaurants/$id', query: {'limit': '$reviewsLimit'});
    return RestaurantScreenData.fromJson(_api.decode(response));
  }

  @override
  Future<PageModel<RestaurantModel>> listRestaurants({String? query, String? category, int limit = 50}) async {
    final response = await _api.get('/restaurants', query: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (category != null && category.isNotEmpty) 'category': category,
      'limit': '$limit',
    });
    return PageModel.fromJson(_api.decode(response), RestaurantModel.fromJson);
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
