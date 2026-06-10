import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves API origin + `/api/v1` prefix for Dio [BaseOptions.baseUrl].
String resolveApiBaseUrl() {
  final raw = dotenv.env['API_BASE_URL']?.trim();
  if (raw == null || raw.isEmpty) {
    return _defaultApiBaseUrl();
  }
  return raw;
}

String _defaultApiBaseUrl() {
  if (kIsWeb) {
    return 'http://127.0.0.1:3000/api/v1';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api/v1';
  }
  return 'http://127.0.0.1:3000/api/v1';
}
