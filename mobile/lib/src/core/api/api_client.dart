import 'package:dio/dio.dart';

import '../auth/auth_service.dart';
import '../config.dart';
import 'api_exception.dart';

/// Cliente HTTP tipado sobre Dio. Inyecta el token de autenticación en cada
/// petición y normaliza los errores a [ApiException].
class ApiClient {
  final Dio _dio;

  ApiClient(AuthService auth) : _dio = _build(auth);

  static Dio _build(AuthService auth) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // getToken() (Firebase) entrega un ID token vigente y lo refresca
          // automáticamente cuando está por expirar.
          final token = await auth.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (e, handler) {
          // 401: el token no es válido. Cerramos la sesión para que el router
          // redirija al flujo de autenticación (login).
          if (e.response?.statusCode == 401 && auth.isAuthenticated) {
            auth.signOut();
          }
          handler.next(e);
        },
      ),
    );

    return dio;
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _run(() => _dio.get(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? body}) =>
      _run(() => _dio.post(path, data: body));

  Future<T> put<T>(String path, {Object? body}) =>
      _run(() => _dio.put(path, data: body));

  Future<T> patch<T>(String path, {Object? body}) =>
      _run(() => _dio.patch(path, data: body));

  Future<T> delete<T>(String path) => _run(() => _dio.delete(path));

  Future<T> _run<T>(Future<Response> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
