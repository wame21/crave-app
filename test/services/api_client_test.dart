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

void main() {
  late InMemoryTokenStore tokenStore;
  late List<http.Request> requests;

  ApiClient client({http.Response? reply, String baseUrl = 'http://api.test/api'}) {
    return ApiClient(
      baseUrl: baseUrl,
      tokenStore: tokenStore,
      httpClient: MockClient((request) async {
        requests.add(request);
        return reply ?? http.Response('{}', 200);
      }),
    );
  }

  setUp(() {
    tokenStore = InMemoryTokenStore();
    requests = [];
  });

  group('headers', () {
    test('envía el token guardado como Bearer', () async {
      tokenStore.session = _session;

      await client().get('/users/me');

      expect(requests.single.headers['Authorization'], 'Bearer token-de-prueba');
    });

    test('sin sesión no envía Authorization', () async {
      await client().get('/restaurants/');

      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('envía el cuerpo como JSON', () async {
      await client().post('/auth/login', body: {'email': 'ana@example.com'});

      expect(requests.single.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(requests.single.body), {'email': 'ana@example.com'});
    });
  });

  group('URLs', () {
    test('agrega la ruta a la URL base', () async {
      await client().get('/users/me');

      expect(requests.single.url.toString(), 'http://api.test/api/users/me');
    });

    test('tolera una barra final en la URL base', () async {
      await client(baseUrl: 'http://api.test/api/').get('/users/me');

      expect(requests.single.url.toString(), 'http://api.test/api/users/me');
    });

    test('codifica los parámetros de búsqueda', () async {
      await client().get('/restaurants/', query: {'q': 'café & tacos', 'category': 'Café'});

      final url = requests.single.url;
      expect(url.path, '/api/restaurants/');
      expect(url.queryParameters, {'q': 'café & tacos', 'category': 'Café'});
      expect(url.query, isNot(contains(' ')));
    });

    test('sin parámetros no agrega "?"', () async {
      await client().get('/restaurants/', query: {});

      expect(requests.single.url.toString(), 'http://api.test/api/restaurants/');
    });
  });

  group('respuestas', () {
    test('decode devuelve el JSON y respeta los acentos aunque no venga el charset', () {
      final data = client().decode(_json({'name': 'Taquería El Güero'}, 200));

      expect(data, {'name': 'Taquería El Güero'});
    });

    test('decode de un cuerpo vacío devuelve null', () {
      expect(client().decode(http.Response('', 204)), isNull);
    });

    test('una respuesta no 2xx lanza ApiException con el detail y el código', () {
      final api = client();

      expect(
        () => api.decode(_json({'detail': 'Correo o contraseña incorrectos'}, 401)),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Correo o contraseña incorrectos')
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('sin detail usa un mensaje genérico con el código', () {
      expect(
        () => client().check(http.Response('<html>', 502)),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Error 502')),
      );
    });

    test('un fallo de conexión lanza ApiException sin código', () async {
      final api = ApiClient(
        baseUrl: 'http://api.test/api',
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
}
