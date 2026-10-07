// Respuestas del BFF: los datos de una pantalla en una sola llamada.
import 'page_model.dart';
import 'restaurant_model.dart';
import 'review_model.dart';

List<RestaurantModel> _restaurants(dynamic list) =>
    (list as List).map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>)).toList();

List<String> _warnings(dynamic list) => list == null ? [] : List<String>.from(list);

/// `GET /bff/home`.
class HomeData {
  final List<RestaurantModel> featured;
  final List<RestaurantModel> topRated;
  final List<RestaurantModel> recommended;
  final List<RestaurantModel> newest;
  final List<String> warnings;

  const HomeData({
    required this.featured,
    required this.topRated,
    required this.recommended,
    required this.newest,
    this.warnings = const [],
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      featured: _restaurants(json['featured']),
      topRated: _restaurants(json['top_rated']),
      recommended: _restaurants(json['recommended']),
      newest: _restaurants(json['newest']),
      warnings: _warnings(json['warnings']),
    );
  }
}

/// `GET /bff/restaurants/{id}`.
class RestaurantScreenData {
  final RestaurantModel restaurant;

  /// `null` si el servicio de reseñas no respondió.
  final PageModel<ReviewModel>? reviews;

  /// `null` sin sesión o si el servicio de favoritos no respondió.
  final bool? isFavorite;
  final List<String> warnings;

  const RestaurantScreenData({
    required this.restaurant,
    this.reviews,
    this.isFavorite,
    this.warnings = const [],
  });

  factory RestaurantScreenData.fromJson(Map<String, dynamic> json) {
    return RestaurantScreenData(
      restaurant: RestaurantModel.fromJson(json['restaurant']),
      reviews: json['reviews'] == null
          ? null
          : PageModel.fromJson(json['reviews'], (item) => ReviewModel.fromJson({
                ...item,
                // El BFF llama "author" a quien la app llama "client".
                'client_name': item['author_name'],
                'client_photo': item['author_photo'],
              })),
      isFavorite: json['is_favorite'],
      warnings: _warnings(json['warnings']),
    );
  }
}
