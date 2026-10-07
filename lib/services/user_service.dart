import '../models/user_model.dart';
import 'api_client.dart';

abstract class UserService {
  Future<UserModel> getMyProfile();
  Future<UserModel> updateProfile(Map<String, dynamic> data);
}

class HttpUserService implements UserService {
  final ApiClient _api;

  HttpUserService(this._api);

  @override
  Future<UserModel> getMyProfile() async {
    return UserModel.fromJson(_api.decode(await _api.get('/users/me')));
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    return UserModel.fromJson(_api.decode(await _api.put('/users/me', body: data)));
  }
}
