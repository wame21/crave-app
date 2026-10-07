import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:crave_app/services/api_client.dart';
import 'package:crave_app/services/token_store.dart';

import '../fakes/in_memory_token_store.dart';

const _session = AuthSession(token: 'token-de-prueba', role: 'Client', userId: 1, profileName: 'Ana');

http.Response _json(Object body, int status) {
  return http.Response.bytes(utf8.encode(jsonEncode(body)), status);
}

http.Response _error(int status, String code, String message, {List<Map<String, String>>? details}) {
  return _json({
    'error': {'code': code, 'message': message, 'details': ?details},
  }, status);
}

void main() {
  late InMemoryTokenStore tokenStore;
  late List<http.Request> requests;
  late int sessionExpirations;

  ApiClient client({http.Response? reply, String baseUrl = 'http://api.test/api/v1'}) {
    return ApiClient(
      baseUrl: baseUrl,
      tokenStore: tokenStore,
      httpClient: MockClient((request) async {
        requests.add(request);
        return reply ?? http.Response('{}', 200);
      }),
      onUnauthorized: () async => sessionExpirations++,
    );
  }

  setUp(() {
    tokenStore = InMemoryTokenStore();
    requests = [];
    sessionExpirations = 0;
  });

  group('headers', () {
    test('envía el token guardado como Bearer', () async {
      tokenStore.session = _session;

      await client().get('/users/me');

      expect(requests.single.headers['Authorization'], 'Bearer token-de-prueba');
    });

    test('sin sesión no envía Authorization', () async {
      await client().get('/restaurants');

      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('envía el cuerpo como JSON', () async {
      await client().post('/auth/login', body: {'email': 'ana@example.com'});

      expect(requests.single.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(requests.single.body), {'email': 'ana@example.com'});
    });
  });

  group('URLs', () {
    test('agrega la ruta a la URL base de /api/v1', () async {
      await client().get('/users/me');

      expect(requests.single.url.toString(), 'http://api.test/api/v1/users/me');
    });

    test('tolera una barra final en la URL base', () async {
      await client(baseUrl: 'http://api.test/api/v1/').get('/users/me');

      expect(requests.single.url.toString(), 'http://api.test/api/v1/users/me');
    });

    test('codifica los parámetros de búsqueda', () async {
      await client().get('/restaurants', query: {'q': 'café & tacos', 'category': 'Café'});

      final url = requests.single.url;
      expect(url.path, '/api/v1/restaurants');
      expect(url.queryParameters, {'q': 'café & tacos', 'category': 'Café'});
      expect(url.query, isNot(contains(' ')));
    });

    test('sin parámetros no agrega "?"', () async {
      await client().get('/restaurants', query: {});

      expect(requests.single.url.toString(), 'http://api.test/api/v1/restaurants');
    });
  });

  group('respuestas y errores', () {
    test('decode devuelve el JSON y respeta los acentos aunque no venga el charset', () {
      final data = client().decode(_json({'name': 'Taquería El Güero'}, 200));

      expect(data, {'name': 'Taquería El Güero'});
    });

    test('decode de un cuerpo vacío (204) devuelve null', () {
      expect(client().decode(http.Response('', 204)), isNull);
    });

    test('lee error.message y error.code del formato de la API', () {
      final api = client();

      expect(
        () => api.decode(_error(401, 'invalid_credentials', 'Correo o contraseña incorrectos')),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Correo o contraseña incorrectos')
            .having((e) => e.code, 'code', 'invalid_credentials')
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('en un error de validación muestra el detalle del campo', () {
      final response = _error(422, 'validation_error', 'Los datos enviados no son válidos', details: [
        {'field': 'body.confirm_password', 'message': 'Value error, Las contraseñas no coinciden'},
      ]);

      expect(
        () => client().check(response),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Las contraseñas no coinciden')),
      );
    });

    test('un cuerpo que no es del formato de la API usa un mensaje genérico con el código', () {
      expect(
        () => client().check(http.Response('<html>Bad gateway</html>', 502)),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Error 502')),
      );
    });

    test('un fallo de conexión lanza ApiException sin código', () async {
      final api = ApiClient(
        baseUrl: 'http://api.test/api/v1',
        tokenStore: tokenStore,
        httpClient: MockClient((_) async => throw http.ClientException('Connection refused')),
      );

      await expectLater(
        api.get('/users/me'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', isNull)
            .having((e) => e.message, 'message', startsWith('No se pudo conectar con el servidor'))),
      );
    });

    test('toString de ApiException es solo el mensaje, para mostrarlo en pantalla', () {
      expect(const ApiException('Sin conexión').toString(), 'Sin conexión');
    });
  });

  group('sesión vencida (401)', () {
    test('un 401 de una petición con token cierra la sesión', () async {
      tokenStore.session = _session;

      await client(reply: _error(401, 'invalid_token', 'Token inválido o expirado')).get('/users/me');

      expect(sessionExpirations, 1);
    });

    test('un 401 sin token (credenciales incorrectas en el login) no cierra nada', () async {
      await client(reply: _error(401, 'invalid_credentials', 'Correo o contraseña incorrectos')).post('/auth/login');

      expect(sessionExpirations, 0);
    });

    test('un 403 con token no cierra la sesión', () async {
      tokenStore.session = _session;

      await client(reply: _error(403, 'forbidden', 'Prohibido')).put('/restaurants/3');

      expect(sessionExpirations, 0);
    });
  });
}
