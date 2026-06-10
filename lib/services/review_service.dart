import 'dart:convert';
import '../models/review_model.dart';
import 'api_client.dart';

class ReviewService {
  static Future<List<ReviewModel>> getRestaurantReviews(int restaurantId) async {
    final response = await ApiClient.get('/reviews/restaurant/$restaurantId');
    ApiClient.handleResponse(response);
    final data = jsonDecode(response.body);
    return (data['reviews'] as List).map((e) => ReviewModel.fromJson(e)).toList();
  }

  static Future<List<ReviewModel>> getMyReviews() async {
    final response = await ApiClient.get('/reviews/me');
    ApiClient.handleResponse(response);
    final data = jsonDecode(response.body);
    return (data['reviews'] as List).map((e) => ReviewModel.fromJson(e)).toList();
  }

  static Future<ReviewModel> createReview(int restaurantId, int food, int service, int atmosphere, String? comment) async {
    final response = await ApiClient.post(
      '/reviews/',
      body: {
        'id_restaurant': restaurantId,
        'rating_food': food,
        'rating_service': service,
        'rating_atmosphere': atmosphere,
        'comment': comment,
      },
    );
    ApiClient.handleResponse(response);
    final data = jsonDecode(response.body);
    return ReviewModel.fromJson(data['review']);
  }

  static Future<void> deleteReview(int reviewId) async {
    final response = await ApiClient.delete('/reviews/$reviewId');
    ApiClient.handleResponse(response);
  }
}
