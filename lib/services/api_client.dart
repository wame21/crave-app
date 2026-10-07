import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_store.dart';

/// Error de una llamada a la API: respuesta no exitosa o fallo de conexión.
class ApiException implements Exception {
  final String message;

  /// Código HTTP de la respuesta, o `null` si no se pudo conectar.
  final int? statusCode;

  /// Código del error de la API (p. ej. `invalid_credentials`), si lo hay.
  final String? code;

  const ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

/// Cliente HTTP de la API.
///
/// Construye las URLs a partir de [baseUrl] y agrega el token guardado en el
/// [TokenStore] como header `Authorization: Bearer <token>`. Si una petición
/// con token recibe 401 (sesión vencida o inválida), llama a [onUnauthorized].
class ApiClient {
  final Uri _baseUri;
  final http.Client _http;
  final TokenStore _tokenStore;
  final Future<void> Function()? _onUnauthorized;

  ApiClient({
    required String baseUrl,
    required http.Client httpClient,
    required TokenStore tokenStore,
    Future<void> Function()? onUnauthorized,
  })  : _baseUri = Uri.parse(baseUrl),
        _http = httpClient,
        _tokenStore = tokenStore,
        _onUnauthorized = onUnauthorized;

  /// URL de [path] (relativo a la URL base) con los parámetros [query] codificados.
  Uri uri(String path, [Map<String, String>? query]) {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    return _baseUri.replace(
      path: '$basePath$path',
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
  }

  Future<http.Response> get(String path, {Map<String, String>? query}) {
    return _send((headers) => _http.get(uri(path, query), headers: headers));
  }

  Future<http.Response> post(String path, {Map<String, dynamic>? body}) {
    return _send((headers) => _http.post(uri(path), headers: headers, body: _encode(body)));
  }

  Future<http.Response> put(String path, {Map<String, dynamic>? body}) {
    return _send((headers) => _http.put(uri(path), headers: headers, body: _encode(body)));
  }

  Future<http.Response> delete(String path) {
    return _send((headers) => _http.delete(uri(path), headers: headers));
  }

  /// Devuelve el JSON del cuerpo de [response] (o `null` si está vacío).
  /// Lanza [ApiException] si la respuesta no es 2xx.
  dynamic decode(http.Response response) {
    check(response);
    if (response.bodyBytes.isEmpty) return null;
    // El backend responde UTF-8 sin indicar el charset; decodificarlo a mano
    // evita que `response.body` lo lea como latin1 y rompa los acentos.
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// Lanza [ApiException] si [response] no es 2xx.
  void check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final (message, code) = _error(response);
    throw ApiException(message, statusCode: response.statusCode, code: code);
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    final headers = await _headers();
    final http.Response response;
    try {
      response = await request(headers);
    } catch (e) {
      throw ApiException('No se pudo conectar con el servidor: $e');
    }
    // Solo si se envió un token: un 401 en el login es un error de credenciales.
    if (response.statusCode == 401 && headers.containsKey('Authorization')) {
      await _onUnauthorized?.call();
    }
    return response;
  }

  Future<Map<String, String>> _headers() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _tokenStore.readToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String? _encode(Map<String, dynamic>? body) {
    return body == null ? null : jsonEncode(body);
  }

  /// Mensaje y código del error. La API responde
  /// `{"error": {"code", "message", "details": [{"field", "message"}]}}`;
  /// en los errores de validación se muestra el detalle del primer campo.
  static (String, String?) _error(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final error = data is Map ? data['error'] : null;
      if (error is Map && error['message'] is String) {
        final details = error['details'];
        if (details is List && details.isNotEmpty && details.first is Map && details.first['message'] is String) {
          final detail = (details.first['message'] as String).replaceFirst('Value error, ', '');
          return (detail, error['code'] as String?);
        }
        return (error['message'] as String, error['code'] as String?);
      }
    } catch (_) {
      // Cuerpo vacío o que no es JSON: se usa el mensaje genérico.
    }
    return ('Error ${response.statusCode}', null);
  }
}
