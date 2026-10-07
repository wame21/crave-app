class RestaurantModel {
  final int idRestaurant;
  final String name;
  final String? description;
  final String? foodType;
  final String? priceRange;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final dynamic socialMedia; // JSON
  final String? openingHours;
  final double? overallRating;
  final bool? isActive;
  final int? idOwner;

  RestaurantModel({
    required this.idRestaurant,
    required this.name,
    this.description,
    this.foodType,
    this.priceRange,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.socialMedia,
    this.openingHours,
    this.overallRating,
    this.isActive,
    this.idOwner,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      idRestaurant: json['id_restaurant'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      foodType: json['food_type'],
      priceRange: json['price_range'],
      address: json['address'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      phone: json['phone'],
      socialMedia: json['social_media'],
      openingHours: json['opening_hours'],
      overallRating: json['overall_rating'] != null ? (json['overall_rating'] as num).toDouble() : 0.0,
      isActive: json['is_active'],
      idOwner: json['id_owner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_restaurant': idRestaurant,
      'name': name,
      'description': description,
      'food_type': foodType,
      'price_range': priceRange,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'social_media': socialMedia,
      'opening_hours': openingHours,
      'overall_rating': overallRating,
      'is_active': isActive,
      'id_owner': idOwner,
    };
  }
}
