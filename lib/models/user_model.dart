class UserModel {
  final int idUser;
  final String profileName;
  final String email;
  final String role;
  final String? photoUrl;
  final String? createdAt;

  UserModel({
    required this.idUser,
    required this.profileName,
    required this.email,
    required this.role,
    this.photoUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: json['id_user'],
      profileName: json['profile_name'],
      email: json['email'],
      role: json['role'],
      photoUrl: json['photo_url'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'profile_name': profileName,
      'email': email,
      'role': role,
      'photo_url': photoUrl,
      'created_at': createdAt,
    };
  }
}
