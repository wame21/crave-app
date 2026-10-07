import '../models/favorite_model.dart';
import 'api_client.dart';

abstract class FavoritesService {
  Future<List<FavoriteModel>> getMyFavorites();
  Future<FavoriteModel> addFavorite(int restaurantId);
  Future<void> removeFavorite(int restaurantId);
}

class HttpFavoritesService implements FavoritesService {
  final ApiClient _api;

  HttpFavoritesService(this._api);

  @override
  Future<List<FavoriteModel>> getMyFavorites() async {
    final data = _api.decode(await _api.get('/favorites/'));
    return (data['favorites'] as List).map((e) => FavoriteModel.fromJson(e)).toList();
  }

  @override
  Future<FavoriteModel> addFavorite(int restaurantId) async {
    final data = _api.decode(await _api.post('/favorites/$restaurantId'));
    return FavoriteModel.fromJson(data['favorite']);
  }

  @override
  Future<void> removeFavorite(int restaurantId) async {
    _api.check(await _api.delete('/favorites/$restaurantId'));
  }
}
