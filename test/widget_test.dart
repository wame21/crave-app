import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:crave_app/di.dart';
import 'package:crave_app/main.dart';
import 'package:crave_app/services/api_client.dart';
import 'package:crave_app/services/auth_service.dart';
import 'package:crave_app/services/restaurant_service.dart';
import 'package:crave_app/services/token_store.dart';
import 'package:crave_app/views/home_screen.dart';
import 'package:crave_app/views/login_screen.dart';

import 'fakes/fake_services.dart';
import 'fakes/in_memory_token_store.dart';

const _session = AuthSession(token: 'token-de-prueba', role: 'Client', userId: 1, profileName: 'Ana');

/// Registra el [HttpAuthService] real sobre un [TokenStore] en memoria, para
/// que `createApp()` decida la pantalla inicial según el token guardado.
void _registerServices(InMemoryTokenStore tokenStore) {
  final api = ApiClient(
    baseUrl: 'http://api.test/api',
    httpClient: MockClient((_) async => http.Response('', 500)),
    tokenStore: tokenStore,
  );
  getIt
    ..registerSingleton<AuthService>(HttpAuthService(api, tokenStore))
    ..registerSingleton<RestaurantService>(FakeRestaurantService());
}

void main() {
  setUp(() => getIt.reset());

  testWidgets('Sin token guardado, la app abre en LoginScreen', (WidgetTester tester) async {
    _registerServices(InMemoryTokenStore());

    await tester.pumpWidget(await createApp());

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('Con token guardado, la app abre en HomeScreen', (WidgetTester tester) async {
    _registerServices(InMemoryTokenStore(_session));

    await tester.pumpWidget(await createApp());
    await tester.pump(); // termina la carga de getHomeData

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
