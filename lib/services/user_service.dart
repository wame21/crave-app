import 'dart:convert';
import '../models/user_model.dart';
import 'api_client.dart';

class UserService {
  static Future<UserModel> getMyProfile() async {
    final response = await ApiClient.get('/users/me');
    ApiClient.handleResponse(response);
    return UserModel.fromJson(jsonDecode(response.body));
  }

  static Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiClient.put('/users/me', body: data);
    ApiClient.handleResponse(response);
    return UserModel.fromJson(jsonDecode(response.body));
  }
}
