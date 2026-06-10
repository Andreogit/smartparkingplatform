import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/api_config.dart';
import 'services/api_service.dart';

const defaultLocaleCode = 'uk';
const _localeStorageKey = 'app_locale';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences not initialized — call main() first');
});

final localeCodeProvider =
    StateNotifierProvider<LocaleController, String>((ref) {
  return LocaleController(ref.read(sharedPreferencesProvider));
});

class LocaleController extends StateNotifier<String> {
  LocaleController(this._prefs) : super(defaultLocaleCode) {
    final saved = _prefs.getString(_localeStorageKey);
    if (saved == 'uk' || saved == 'en') {
      state = saved!;
    }
  }

  final SharedPreferences _prefs;

  Future<void> setLocale(String code) async {
    if (code != 'uk' && code != 'en') {
      return;
    }
    state = code;
    await _prefs.setString(_localeStorageKey, code);
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((_) => const FlutterSecureStorage());

final authTokenProvider = StateProvider<String?>((_) => null);

/// Incremented when API returns 401 — [BkrApp] navigates to login.
final sessionExpiredTickProvider = StateProvider<int>((_) => 0);

final dioProvider = Provider<Dio>((ref) {
  final token = ref.watch(authTokenProvider);
  final baseUrl = resolveApiBaseUrl();

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = token;
        if (t != null && t.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $t';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;
        final isAuthRoute = path.contains('/auth/login') || path.contains('/auth/register');
        if (status == 401 && !isAuthRoute) {
          await ref.read(secureStorageProvider).delete(key: 'access_token');
          ref.read(authTokenProvider.notifier).state = null;
          ref.read(sessionExpiredTickProvider.notifier).state++;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService(ref.watch(dioProvider)));
