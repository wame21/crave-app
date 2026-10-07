import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crave_app/di.dart';
import 'package:crave_app/models/restaurant_model.dart';
import 'package:crave_app/services/auth_service.dart';
import 'package:crave_app/services/favorites_service.dart';
import 'package:crave_app/services/restaurant_service.dart';
import 'package:crave_app/services/review_service.dart';
import 'package:crave_app/views/restaurant_detail_screen.dart';

import '../fakes/fake_services.dart';

void main() {
  late FakeRestaurantService restaurants;
  late FakeFavoritesService favorites;

  setUp(() async {
    await getIt.reset();
    restaurants = FakeRestaurantService([
      RestaurantModel(idRestaurant: 1, name: 'Taquería El Güero', foodType: 'Tacos', overallRating: 4.33),
    ]);
    favorites = FakeFavoritesService();
    getIt
      ..registerSingleton<RestaurantService>(restaurants)
      ..registerSingleton<FavoritesService>(favorites)
      ..registerSingleton<ReviewService>(FakeReviewService())
      ..registerSingleton<AuthService>(FakeAuthService(loggedIn: true, role: 'Client'));
  });

  Future<void> openDetail(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RestaurantDetailScreen(restaurantId: 1)));
    await tester.pump(); // termina la carga
  }

  testWidgets('muestra el restaurante y el favorito que devuelve el BFF', (tester) async {
    restaurants.screenIsFavorite = true;

    await openDetail(tester);

    expect(find.text('Taquería El Güero'), findsWidgets);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('si el BFF no trae el favorito, lo consulta en GET /favorites/{id}', (tester) async {
    restaurants.screenIsFavorite = null;
    favorites.restaurantIds.add(1);

    await openDetail(tester);

    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('marcar y desmarcar el favorito', (tester) async {
    restaurants.screenIsFavorite = false;
    await openDetail(tester);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(favorites.restaurantIds, {1});
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pump();
    expect(favorites.restaurantIds, isEmpty);
  });

  testWidgets('los avisos del BFF se muestran al usuario', (tester) async {
    restaurants.screenWarnings = ['No se pudieron cargar las reseñas'];

    await openDetail(tester);
    await tester.pump();

    expect(find.text('No se pudieron cargar las reseñas'), findsOneWidget);
  });
}
