import 'dart:convert';
import '../models/restaurant_model.dart';
import 'api_client.dart';

class GenieResponse {
  final String reply;
  final List<RestaurantModel>? restaurantSuggestions;

  GenieResponse({required this.reply, this.restaurantSuggestions});
}

class GenieService {
  static Future<GenieResponse> chat(String message) async {
    final response = await ApiClient.post(
      '/genie/chat',
      body: {'message': message},
    );
    ApiClient.handleResponse(response);
    final data = jsonDecode(response.body);
    
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
