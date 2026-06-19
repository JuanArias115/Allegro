import 'package:dio/dio.dart';

/// Excepción tipada que la UI puede mostrar con un mensaje claro.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;

  /// Traduce un error de Dio a un mensaje legible, usando el detalle que
  /// devuelve el backend (problem+json) cuando está disponible.
  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response != null) {
      final data = response.data;
      String? detail;
      if (data is Map) {
        detail = (data['detail'] ?? data['title'])?.toString();
        // Errores de validación: { errors: { campo: [..] } }
        if (detail == null && data['errors'] is Map) {
          final errors = (data['errors'] as Map).values
              .expand((v) => v is List ? v : [v])
              .map((v) => v.toString());
          detail = errors.join('\n');
        }
      }
      return ApiException(
        detail ?? 'Error del servidor (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Tiempo de espera agotado. Revisa tu conexión.',
      DioExceptionType.connectionError =>
        'No se pudo conectar con el servidor. ¿Está el backend en ejecución?',
      _ => 'Ocurrió un error inesperado.',
    };
    return ApiException(message);
  }
}
