class FavoriteModel {
  final int idFavorite;
  final int idClient;
  final int idRestaurant;
  final String? createdAt;
  final String? restaurantName;
  final String? foodType;
  final double? overallRating;
  final String? address;

  FavoriteModel({
    required this.idFavorite,
    required this.idClient,
    required this.idRestaurant,
    this.createdAt,
    this.restaurantName,
    this.foodType,
    this.overallRating,
    this.address,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      idFavorite: json['id_favorite'],
      idClient: json['id_client'],
      idRestaurant: json['id_restaurant'],
      createdAt: json['created_at'],
      restaurantName: json['restaurant_name'],
      foodType: json['food_type'],
      overallRating: json['overall_rating'] != null ? (json['overall_rating'] as num).toDouble() : null,
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_favorite': idFavorite,
      'id_client': idClient,
      'id_restaurant': idRestaurant,
      'created_at': createdAt,
      'restaurant_name': restaurantName,
      'food_type': foodType,
      'overall_rating': overallRating,
      'address': address,
    };
  }
}
