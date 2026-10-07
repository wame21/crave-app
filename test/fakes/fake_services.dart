// Servicios en memoria para las pruebas de widgets: se registran en `getIt`
// en lugar de las implementaciones HTTP.
import 'package:crave_app/models/favorite_model.dart';
import 'package:crave_app/models/restaurant_model.dart';
import 'package:crave_app/models/review_model.dart';
import 'package:crave_app/models/user_model.dart';
import 'package:crave_app/services/api_client.dart';
import 'package:crave_app/services/auth_service.dart';
import 'package:crave_app/services/favorites_service.dart';
import 'package:crave_app/services/genie_service.dart';
import 'package:crave_app/services/restaurant_service.dart';
import 'package:crave_app/services/review_service.dart';
import 'package:crave_app/services/user_service.dart';

ApiException _notFound(String what) => ApiException('$what no encontrado', statusCode: 404);

class FakeAuthService implements AuthService {
  bool loggedIn;
  String? role;
  final List<String> logins = [];

  FakeAuthService({this.loggedIn = false, this.role});

  @override
  Future<bool> isLoggedIn() async => loggedIn;

  @override
  Future<String?> getRole() async => role;

  @override
  Future<void> logout() async {
    loggedIn = false;
    role = null;
  }

  @override
  Future<void> login(String email, String password) async {
    logins.add(email);
    loggedIn = true;
    role ??= 'Client';
  }

  @override
  Future<void> registerClient(String name, String email, String password, String confirmPassword) async {
    loggedIn = true;
    role = 'Client';
  }

  @override
  Future<void> registerOwner(String name, String email, String password, String confirmPassword, String restaurantName, String foodType) async {
    loggedIn = true;
    role = 'Owner';
  }
}

class FakeRestaurantService implements RestaurantService {
  final List<RestaurantModel> restaurants;
  final List<Map<String, dynamic>> updates = [];

  FakeRestaurantService([List<RestaurantModel>? restaurants]) : restaurants = restaurants ?? [];

  @override
  Future<Map<String, List<RestaurantModel>>> getHomeData() async {
    final byRating = [...restaurants]
      ..sort((a, b) => (b.overallRating ?? 0).compareTo(a.overallRating ?? 0));
    return {
      'destacados': byRating.take(5).toList(),
      'mejor_valorados': byRating.take(10).toList(),
      'novedades': restaurants.reversed.take(10).toList(),
    };
  }

  @override
  Future<List<RestaurantModel>> listRestaurants({String? query, String? category}) async {
    return restaurants.where((r) {
      final matchesQuery = query == null || r.name.toLowerCase().contains(query.toLowerCase());
      final matchesCategory = category == null || r.foodType == category;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Future<RestaurantModel> getRestaurant(int id) async {
    return restaurants.firstWhere((r) => r.idRestaurant == id, orElse: () => throw _notFound('Restaurante'));
  }

  @override
  Future<RestaurantModel> getMyRestaurant() async {
    if (restaurants.isEmpty) throw _notFound('Restaurante');
    return restaurants.first;
  }

  @override
  Future<RestaurantModel> updateRestaurant(int id, Map<String, dynamic> data) async {
    updates.add({'id': id, ...data});
    return getRestaurant(id);
  }

  @override
  Future<List<String>> getCategories() async {
    return restaurants.map((r) => r.foodType).whereType<String>().toSet().toList();
  }
}

class FakeReviewService implements ReviewService {
  final List<ReviewModel> reviews;

  FakeReviewService([List<ReviewModel>? reviews]) : reviews = reviews ?? [];

  @override
  Future<List<ReviewModel>> getRestaurantReviews(int restaurantId) async {
    return reviews.where((r) => r.idRestaurant == restaurantId).toList();
  }

  @override
  Future<List<ReviewModel>> getMyReviews() async => List.of(reviews);

  @override
  Future<ReviewModel> createReview(int restaurantId, int food, int service, int atmosphere, String? comment) async {
    final review = ReviewModel(
      idReview: reviews.length + 1,
      idRestaurant: restaurantId,
      ratingFood: food,
      ratingService: service,
      ratingAtmosphere: atmosphere,
      comment: comment,
    );
    reviews.add(review);
    return review;
  }

  @override
  Future<void> deleteReview(int reviewId) async {
    reviews.removeWhere((r) => r.idReview == reviewId);
  }
}

class FakeFavoritesService implements FavoritesService {
  final Set<int> restaurantIds;

  FakeFavoritesService([Set<int>? restaurantIds]) : restaurantIds = restaurantIds ?? {};

  @override
  Future<List<FavoriteModel>> getMyFavorites() async {
    return restaurantIds.map(_favorite).toList();
  }

  @override
  Future<FavoriteModel> addFavorite(int restaurantId) async {
    restaurantIds.add(restaurantId);
    return _favorite(restaurantId);
  }

  @override
  Future<void> removeFavorite(int restaurantId) async {
    if (!restaurantIds.remove(restaurantId)) throw _notFound('Favorito');
  }

  FavoriteModel _favorite(int restaurantId) {
    return FavoriteModel(idFavorite: restaurantId, idClient: 1, idRestaurant: restaurantId);
  }
}

class FakeUserService implements UserService {
  UserModel profile;

  FakeUserService(this.profile);

  @override
  Future<UserModel> getMyProfile() async => profile;

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    profile = UserModel(
      idUser: profile.idUser,
      profileName: data['profile_name'] ?? profile.profileName,
      email: profile.email,
      role: profile.role,
      photoUrl: data['photo_url'] ?? profile.photoUrl,
    );
    return profile;
  }
}

class FakeGenieService implements GenieService {
  final List<String> messages = [];

  @override
  Future<GenieResponse> chat(String message) async {
    messages.add(message);
    return GenieResponse(reply: 'Te recomiendo probar algo nuevo.');
  }
}
