import 'package:dio/dio.dart';

/// Turns Dio/network failures into short UI strings.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final url = error.requestOptions.uri.toString();
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Timed out talking to the API.\n$url\n\n'
            'On your Mac run:\n'
            '  curl http://127.0.0.1:3000/api/v1/health\n'
            'If curl fails, start the backend (docker compose up). '
            'iOS Simulator must use http://127.0.0.1:3000/api/v1 (not 10.0.2.2).';
      case DioExceptionType.connectionError:
        return 'Cannot reach API ($url). '
            'On iOS Simulator use http://127.0.0.1:3000/api/v1 — '
            'not 10.0.2.2 (Android only).';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          final msg = data['message'];
          if (msg is String) {
            return '$msg\n\n$url';
          }
          if (msg is List) {
            return '${msg.join(', ')}\n\n$url';
          }
        }
        return 'Server error${code != null ? ' ($code)' : ''}: ${data ?? ''}\n$url';
      default:
        break;
    }
    return error.message ?? error.toString();
  }
  return error.toString();
}
