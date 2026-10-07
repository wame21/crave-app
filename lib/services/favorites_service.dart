import '../models/favorite_model.dart';
import '../models/page_model.dart';
import 'api_client.dart';

abstract class FavoritesService {
  Future<PageModel<FavoriteModel>> getMyFavorites({int limit = 100});

  /// Si el restaurante es favorito, sin descargar la lista completa.
  Future<bool> isFavorite(int restaurantId);
  Future<FavoriteModel> addFavorite(int restaurantId);
  Future<void> removeFavorite(int restaurantId);
}

class HttpFavoritesService implements FavoritesService {
  final ApiClient _api;

  HttpFavoritesService(this._api);

  @override
  Future<PageModel<FavoriteModel>> getMyFavorites({int limit = 100}) async {
    final response = await _api.get('/favorites', query: {'limit': '$limit'});
    return PageModel.fromJson(_api.decode(response), FavoriteModel.fromJson);
  }

  @override
  Future<bool> isFavorite(int restaurantId) async {
    final data = _api.decode(await _api.get('/favorites/$restaurantId'));
    return data['is_favorite'] as bool;
  }

  @override
  Future<FavoriteModel> addFavorite(int restaurantId) async {
    return FavoriteModel.fromJson(_api.decode(await _api.post('/favorites/$restaurantId')));
  }

  @override
  Future<void> removeFavorite(int restaurantId) async {
    _api.check(await _api.delete('/favorites/$restaurantId'));
  }
}
