import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crave_app/di.dart';
import 'package:crave_app/models/restaurant_model.dart';
import 'package:crave_app/services/restaurant_service.dart';
import 'package:crave_app/services/review_service.dart';
import 'package:crave_app/views/create_review_screen.dart';

import '../fakes/fake_services.dart';

void main() {
  late FakeReviewService reviews;

  setUp(() async {
    await getIt.reset();
    reviews = FakeReviewService();
    getIt
      ..registerSingleton<RestaurantService>(FakeRestaurantService([
        RestaurantModel(idRestaurant: 3, name: 'Sushi Koi', foodType: 'Sushi', overallRating: 5.0),
      ]))
      ..registerSingleton<ReviewService>(reviews);
  });

  /// Abre la pantalla encima de otra, como lo hace la app (al publicar hace `pop`).
  Future<void> openScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(2400, 4800); // 800 x 1600 lógicos (devicePixelRatio 3)
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateReviewScreen(restaurantId: 3)),
          ),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('cada calificación llega a su campo (comida, servicio, ambiente)', (tester) async {
    await openScreen(tester);

    await tester.tap(find.byKey(const ValueKey('rating-Comida-4')));
    await tester.tap(find.byKey(const ValueKey('rating-Servicio-5')));
    await tester.tap(find.byKey(const ValueKey('rating-Ambiente-3')));
    await tester.enterText(find.byType(TextField), 'Muy fresco');
    await tester.tap(find.text('Publicar reseña'));
    await tester.pumpAndSettle();

    final review = reviews.reviews.single;
    expect(
      (review.idRestaurant, review.ratingFood, review.ratingService, review.ratingAtmosphere, review.comment),
      (3, 4, 5, 3, 'Muy fresco'),
    );
  });

  testWidgets('las estrellas son enteras: no hay medias estrellas', (tester) async {
    await openScreen(tester);

    await tester.tap(find.byKey(const ValueKey('rating-Comida-2')));
    await tester.pump();

    expect(find.byIcon(Icons.star_half), findsNothing);
    final comida = find.descendant(of: find.byKey(const ValueKey('rating-Comida-2')), matching: find.byIcon(Icons.star));
    expect(comida, findsOneWidget);
  });

  testWidgets('sin calificar todo no se publica', (tester) async {
    await openScreen(tester);

    await tester.tap(find.byKey(const ValueKey('rating-Comida-5')));
    await tester.tap(find.text('Publicar reseña'));
    await tester.pump();

    expect(find.text('Por favor, califica todos los aspectos'), findsOneWidget);
    expect(reviews.reviews, isEmpty);
  });
}
