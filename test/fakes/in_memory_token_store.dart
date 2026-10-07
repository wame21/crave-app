import 'package:crave_app/services/token_store.dart';

/// [TokenStore] en memoria, para pruebas sin SharedPreferences.
class InMemoryTokenStore implements TokenStore {
  AuthSession? session;

  InMemoryTokenStore([this.session]);

  @override
  Future<String?> readToken() async => session?.token;

  @override
  Future<String?> readRole() async => session?.role;

  @override
  Future<void> save(AuthSession session) async => this.session = session;

  @override
  Future<void> clear() async => session = null;
}
