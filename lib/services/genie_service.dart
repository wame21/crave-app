import '../models/restaurant_model.dart';
import 'api_client.dart';

class GenieResponse {
  final String reply;
  final List<RestaurantModel>? restaurantSuggestions;

  GenieResponse({required this.reply, this.restaurantSuggestions});
}

abstract class GenieService {
  Future<GenieResponse> chat(String message);
}

class HttpGenieService implements GenieService {
  final ApiClient _api;

  HttpGenieService(this._api);

  @override
  Future<GenieResponse> chat(String message) async {
    final data = _api.decode(await _api.post(
      '/genie/chat',
      body: {'message': message},
    ));

    List<RestaurantModel>? suggestions;
    if (data['restaurant_suggestions'] != null) {
      suggestions = (data['restaurant_suggestions'] as List)
          .map((e) => RestaurantModel.fromJson(e))
          .toList();
    }

    return GenieResponse(
      reply: data['reply'],
      restaurantSuggestions: suggestions,
    );
  }
}
