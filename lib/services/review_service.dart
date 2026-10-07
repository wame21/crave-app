import '../models/page_model.dart';
import '../models/review_model.dart';
import 'api_client.dart';

abstract class ReviewService {
  Future<PageModel<ReviewModel>> getRestaurantReviews(int restaurantId, {int limit = 100});
  Future<PageModel<ReviewModel>> getMyReviews({int limit = 100});
  Future<ReviewModel> createReview(int restaurantId, int food, int service, int atmosphere, String? comment);
  Future<void> deleteReview(int reviewId);
}

class HttpReviewService implements ReviewService {
  final ApiClient _api;

  HttpReviewService(this._api);

  @override
  Future<PageModel<ReviewModel>> getRestaurantReviews(int restaurantId, {int limit = 100}) async {
    final response = await _api.get('/reviews/restaurant/$restaurantId', query: {'limit': '$limit'});
    return PageModel.fromJson(_api.decode(response), ReviewModel.fromJson);
  }

  @override
  Future<PageModel<ReviewModel>> getMyReviews({int limit = 100}) async {
    final response = await _api.get('/reviews/me', query: {'limit': '$limit'});
    return PageModel.fromJson(_api.decode(response), ReviewModel.fromJson);
  }

  @override
  Future<ReviewModel> createReview(int restaurantId, int food, int service, int atmosphere, String? comment) async {
    final data = _api.decode(await _api.post(
      '/reviews',
      body: {
        'id_restaurant': restaurantId,
        'rating_food': food,
        'rating_service': service,
        'rating_atmosphere': atmosphere,
        'comment': comment,
      },
    ));
    return ReviewModel.fromJson(data);
  }

  @override
  Future<void> deleteReview(int reviewId) async {
    _api.check(await _api.delete('/reviews/$reviewId'));
  }
}
