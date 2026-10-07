class ReviewModel {
  final int idReview;
  final int? idClient;
  final int? idRestaurant;
  final int? ratingFood;
  final int? ratingService;
  final int? ratingAtmosphere;
  final String? comment;
  final List<String>? photoGallery;
  final String? status;
  final String? createdAt;
  final String? clientName;
  final String? clientPhoto;
  final String? restaurantName;

  ReviewModel({
    required this.idReview,
    this.idClient,
    this.idRestaurant,
    this.ratingFood,
    this.ratingService,
    this.ratingAtmosphere,
    this.comment,
    this.photoGallery,
    this.status,
    this.createdAt,
    this.clientName,
    this.clientPhoto,
    this.restaurantName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      idReview: json['id_review'],
      idClient: json['id_client'],
      idRestaurant: json['id_restaurant'],
      ratingFood: json['rating_food'],
      ratingService: json['rating_service'],
      ratingAtmosphere: json['rating_atmosphere'],
      comment: json['comment'],
      photoGallery: json['photo_gallery'] != null ? List<String>.from(json['photo_gallery']) : null,
      status: json['status'],
      createdAt: json['created_at'],
      clientName: json['client_name'],
      clientPhoto: json['client_photo'],
      restaurantName: json['restaurant_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_review': idReview,
      'id_client': idClient,
      'id_restaurant': idRestaurant,
      'rating_food': ratingFood,
      'rating_service': ratingService,
      'rating_atmosphere': ratingAtmosphere,
      'comment': comment,
      'photo_gallery': photoGallery,
      'status': status,
      'created_at': createdAt,
      'client_name': clientName,
      'client_photo': clientPhoto,
      'restaurant_name': restaurantName,
    };
  }
}
