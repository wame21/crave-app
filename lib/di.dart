import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/favorites_service.dart';
import 'services/genie_service.dart';
import 'services/restaurant_service.dart';
import 'services/review_service.dart';
import 'services/token_store.dart';
import 'services/user_service.dart';

/// URL base de la API (versión 1). Se elige al compilar, por ejemplo:
///
///     flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
///
/// Por defecto es el `localhost` de la máquina visto desde el emulador de Android.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

/// Contenedor de dependencias. Las vistas obtienen los servicios con
/// `getIt<RestaurantService>()`; las pruebas registran aquí sus fakes.
final GetIt getIt = GetIt.instance;

/// Registra el cliente de la API y los servicios HTTP. Se llama una vez en `main`.
///
/// Si la API rechaza el token guardado (401), se borra la sesión y se llama a
/// [onSessionExpired] (la app lleva al login).
void setupDependencies({String baseUrl = apiBaseUrl, Future<void> Function()? onSessionExpired}) {
  final tokenStore = SharedPrefsTokenStore();
  final api = ApiClient(
    baseUrl: baseUrl,
    httpClient: http.Client(),
    tokenStore: tokenStore,
    onUnauthorized: () async {
      await tokenStore.clear();
      await onSessionExpired?.call();
    },
  );

  getIt
    ..registerSingleton<TokenStore>(tokenStore)
    ..registerSingleton<ApiClient>(api)
    ..registerLazySingleton<AuthService>(() => HttpAuthService(api, tokenStore))
    ..registerLazySingleton<RestaurantService>(() => HttpRestaurantService(api))
    ..registerLazySingleton<ReviewService>(() => HttpReviewService(api))
    ..registerLazySingleton<FavoritesService>(() => HttpFavoritesService(api))
    ..registerLazySingleton<UserService>(() => HttpUserService(api))
    ..registerLazySingleton<GenieService>(() => HttpGenieService(api));
}
