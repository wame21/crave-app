import '../models/review_model.dart';
import 'api_client.dart';

abstract class ReviewService {
  Future<List<ReviewModel>> getRestaurantReviews(int restaurantId);
  Future<List<ReviewModel>> getMyReviews();
  Future<ReviewModel> createReview(int restaurantId, int food, int service, int atmosphere, String? comment);
  Future<void> deleteReview(int reviewId);
}

class HttpReviewService implements ReviewService {
  final ApiClient _api;

  HttpReviewService(this._api);

  @override
  Future<List<ReviewModel>> getRestaurantReviews(int restaurantId) async {
    final data = _api.decode(await _api.get('/reviews/restaurant/$restaurantId'));
    return (data['reviews'] as List).map((e) => ReviewModel.fromJson(e)).toList();
  }

  @override
  Future<List<ReviewModel>> getMyReviews() async {
    final data = _api.decode(await _api.get('/reviews/me'));
    return (data['reviews'] as List).map((e) => ReviewModel.fromJson(e)).toList();
  }

  @override
  Future<ReviewModel> createReview(int restaurantId, int food, int service, int atmosphere, String? comment) async {
    final data = _api.decode(await _api.post(
      '/reviews/',
      body: {
        'id_restaurant': restaurantId,
        'rating_food': food,
        'rating_service': service,
        'rating_atmosphere': atmosphere,
        'comment': comment,
      },
    ));
    return ReviewModel.fromJson(data['review']);
  }

  @override
  Future<void> deleteReview(int reviewId) async {
    _api.check(await _api.delete('/reviews/$reviewId'));
  }
}
