import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:crave_app/services/api_client.dart';
import 'package:crave_app/services/auth_service.dart';
import 'package:crave_app/services/favorites_service.dart';
import 'package:crave_app/services/restaurant_service.dart';

import '../fakes/in_memory_token_store.dart';

http.Response _json(Object body, int status) {
  return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
}

void main() {
  late InMemoryTokenStore tokenStore;
  late List<http.Request> requests;
  late http.Response reply;

  ApiClient api() {
    return ApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: tokenStore,
      httpClient: MockClient((request) async {
        requests.add(request);
        return reply;
      }),
    );
  }

  setUp(() {
    tokenStore = InMemoryTokenStore();
    requests = [];
    reply = http.Response('{}', 200);
  });

  group('HttpAuthService', () {
    test('login guarda la sesión que devuelve el backend', () async {
      reply = _json({'access_token': 'abc', 'role': 'Owner', 'user_id': 3, 'profile_name': 'María'}, 200);
      final auth = HttpAuthService(api(), tokenStore);

      await auth.login('maria@example.com', '123456');

      expect(requests.single.url.path, '/api/auth/login');
      expect(await auth.isLoggedIn(), isTrue);
      expect(await auth.getRole(), 'Owner');
      expect(tokenStore.session!.profileName, 'María');
    });

    test('si el login falla no guarda ninguna sesión', () async {
      reply = _json({'detail': 'Correo o contraseña incorrectos'}, 401);
      final auth = HttpAuthService(api(), tokenStore);

      await expectLater(auth.login('ana@example.com', 'mala'), throwsA(isA<ApiException>()));

      expect(await auth.isLoggedIn(), isFalse);
    });

    test('logout borra la sesión', () async {
      reply = _json({'access_token': 'abc', 'role': 'Client', 'user_id': 1, 'profile_name': 'Ana'}, 200);
      final auth = HttpAuthService(api(), tokenStore);
      await auth.login('ana@example.com', '123456');

      await auth.logout();

      expect(await auth.isLoggedIn(), isFalse);
    });
  });

  group('HttpRestaurantService', () {
    test('listRestaurants envía la búsqueda codificada y lee la lista', () async {
      reply = _json({
        'restaurants': [
          {'id_restaurant': 5, 'name': 'Café Tostado', 'food_type': 'Café', 'overall_rating': 4.83},
        ],
      }, 200);

      final results = await HttpRestaurantService(api()).listRestaurants(query: 'café tostado', category: 'Café');

      expect(requests.single.url.queryParameters, {'q': 'café tostado', 'category': 'Café'});
      expect(results.single.name, 'Café Tostado');
      expect(results.single.overallRating, 4.83);
    });

    test('listRestaurants sin filtros no envía parámetros', () async {
      reply = _json({'restaurants': []}, 200);

      await HttpRestaurantService(api()).listRestaurants(query: '', category: null);

      expect(requests.single.url.query, isEmpty);
    });
  });

  group('HttpFavoritesService', () {
    test('removeFavorite propaga el error del backend', () async {
      reply = _json({'detail': 'No era favorito'}, 404);

      await expectLater(
        HttpFavoritesService(api()).removeFavorite(7),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/api/favorites/7');
    });
  });
}
