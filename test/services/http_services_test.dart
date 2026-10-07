import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:crave_app/services/api_client.dart';
import 'package:crave_app/services/auth_service.dart';
import 'package:crave_app/services/favorites_service.dart';
import 'package:crave_app/services/restaurant_service.dart';
import 'package:crave_app/services/review_service.dart';

import '../fakes/in_memory_token_store.dart';

http.Response _json(Object body, int status) {
  return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
}

Map<String, dynamic> _page(List<Object> items, {int? total}) {
  return {'items': items, 'total': total ?? items.length, 'limit': 20, 'offset': 0};
}

Map<String, dynamic> _card(int id, String name, {double rating = 4.5}) {
  return {'id_restaurant': id, 'name': name, 'food_type': 'Tacos', 'overall_rating': rating};
}

void main() {
  late InMemoryTokenStore tokenStore;
  late List<http.Request> requests;
  late http.Response reply;

  ApiClient api() {
    return ApiClient(
      baseUrl: 'http://api.test/api/v1',
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

      expect(requests.single.url.path, '/api/v1/auth/login');
      expect(await auth.isLoggedIn(), isTrue);
      expect(await auth.getRole(), 'Owner');
      expect(tokenStore.session!.profileName, 'María');
    });

    test('si el login falla muestra el mensaje de la API y no guarda sesión', () async {
      reply = _json({'error': {'code': 'invalid_credentials', 'message': 'Correo o contraseña incorrectos'}}, 401);
      final auth = HttpAuthService(api(), tokenStore);

      await expectLater(
        auth.login('ana@example.com', 'mala'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Correo o contraseña incorrectos')),
      );
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
    test('getHomeData usa el BFF', () async {
      reply = _json({
        'featured': [_card(3, 'Sushi Koi', rating: 5.0)],
        'top_rated': [_card(3, 'Sushi Koi', rating: 5.0), _card(5, 'Café Tostado')],
        'recommended': [_card(5, 'Café Tostado')],
        'newest': [_card(10, 'Mariscos La Ola', rating: 0)],
        'warnings': [],
      }, 200);

      final home = await HttpRestaurantService(api()).getHomeData();

      expect(requests.single.url.path, '/api/v1/bff/home');
      expect(home.featured.single.name, 'Sushi Koi');
      expect(home.topRated.length, 2);
      expect(home.newest.single.overallRating, 0.0);
      expect(home.warnings, isEmpty);
    });

    test('getRestaurantScreen trae restaurante, reseñas y favorito en una llamada', () async {
      reply = _json({
        'restaurant': {..._card(1, 'Taquería El Güero'), 'phone': '55 5264 1180', 'social_media': {'instagram': '@taqueria'}},
        'reviews': _page([
          {
            'id_review': 7,
            'author_name': 'Ana López',
            'author_photo': null,
            'rating_food': 5,
            'rating_service': 4,
            'rating_atmosphere': 4,
            'rating_average': 4.33,
            'comment': 'Muy ricos',
            'photo_gallery': [],
            'created_at': '2026-10-01T12:00:00Z',
          },
        ]),
        'is_favorite': true,
        'warnings': [],
      }, 200);

      final screen = await HttpRestaurantService(api()).getRestaurantScreen(1, reviewsLimit: 5);

      expect(requests.single.url.path, '/api/v1/bff/restaurants/1');
      expect(requests.single.url.queryParameters, {'limit': '5'});
      expect(screen.restaurant.phone, '55 5264 1180');
      expect(screen.reviews!.items.single.clientName, 'Ana López');
      expect(screen.isFavorite, isTrue);
    });

    test('getRestaurantScreen tolera las partes que el BFF no pudo cargar', () async {
      reply = _json({
        'restaurant': _card(1, 'Taquería El Güero'),
        'reviews': null,
        'is_favorite': null,
        'warnings': ['No se pudieron cargar las reseñas'],
      }, 200);

      final screen = await HttpRestaurantService(api()).getRestaurantScreen(1);

      expect(screen.reviews, isNull);
      expect(screen.isFavorite, isNull);
      expect(screen.warnings, ['No se pudieron cargar las reseñas']);
    });

    test('listRestaurants envía la búsqueda codificada y lee la página', () async {
      reply = _json(_page([_card(5, 'Café Tostado', rating: 4.83)], total: 1), 200);

      final page = await HttpRestaurantService(api()).listRestaurants(query: 'café tostado', category: 'Café');

      expect(requests.single.url.path, '/api/v1/restaurants');
      expect(requests.single.url.queryParameters, {'q': 'café tostado', 'category': 'Café', 'limit': '50'});
      expect(page.items.single.name, 'Café Tostado');
      expect((page.total, page.hasMore), (1, false));
    });

    test('listRestaurants sin filtros solo envía el límite', () async {
      reply = _json(_page([]), 200);

      await HttpRestaurantService(api()).listRestaurants(query: '', category: null);

      expect(requests.single.url.queryParameters, {'limit': '50'});
    });
  });

  group('HttpReviewService', () {
    Map<String, dynamic> review(int id) => {
          'id_review': id,
          'id_client': 1,
          'id_restaurant': 3,
          'rating_food': 5,
          'rating_service': 5,
          'rating_atmosphere': 4,
          'comment': 'Excelente',
          'photo_gallery': [],
          'status': 'Approved',
          'created_at': '2026-10-01T12:00:00Z',
          'restaurant_name': 'Sushi Koi',
        };

    test('createReview publica en /reviews y lee la reseña creada', () async {
      reply = _json(review(9), 201);

      final created = await HttpReviewService(api()).createReview(3, 5, 5, 4, 'Excelente');

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/v1/reviews');
      expect(jsonDecode(requests.single.body)['id_restaurant'], 3);
      expect((created.idReview, created.status), (9, 'Approved'));
    });

    test('getMyReviews lee la página con el nombre del restaurante', () async {
      reply = _json(_page([review(1), review(2)], total: 5), 200);

      final page = await HttpReviewService(api()).getMyReviews();

      expect(page.items.map((r) => r.restaurantName), ['Sushi Koi', 'Sushi Koi']);
      expect((page.total, page.hasMore), (5, true));
    });
  });

  group('HttpFavoritesService', () {
    test('isFavorite consulta GET /favorites/{id}', () async {
      reply = _json({'is_favorite': true}, 200);

      expect(await HttpFavoritesService(api()).isFavorite(4), isTrue);
      expect(requests.single.url.path, '/api/v1/favorites/4');
    });

    test('addFavorite lee el favorito creado', () async {
      reply = _json({
        'id_favorite': 1, 'id_client': 2, 'id_restaurant': 4, 'created_at': '2026-10-01T12:00:00Z',
        'restaurant_name': 'Burger Barrio', 'food_type': 'Hamburguesas', 'overall_rating': 3.67, 'address': null,
      }, 201);

      final favorite = await HttpFavoritesService(api()).addFavorite(4);

      expect((favorite.idRestaurant, favorite.restaurantName), (4, 'Burger Barrio'));
    });

    test('removeFavorite propaga el error del backend', () async {
      reply = _json({'error': {'code': 'not_favorite', 'message': 'El restaurante no estaba en tus favoritos'}}, 404);

      await expectLater(
        HttpFavoritesService(api()).removeFavorite(7),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.code, 'code', 'not_favorite')),
      );
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/api/v1/favorites/7');
    });
  });
}
