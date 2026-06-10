import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/api_config.dart';
import 'navigation/app_navigator.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/map/map_screen.dart';
import 'features/profile/profile_screen.dart';
import 'l10n/l10n.dart';
import 'providers.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/env/.env');
  } catch (_) {
    await dotenv.load(fileName: 'assets/env/env.sample');
  }
  debugPrint('BKR API_BASE_URL → ${resolveApiBaseUrl()}');

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BkrApp(),
    ),
  );
}

class BkrApp extends ConsumerWidget {
  const BkrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<int>(sessionExpiredTickProvider, (previous, next) {
      if (next > (previous ?? 0)) {
        final navContext = rootNavigatorKey.currentContext;
        if (navContext != null) {
          final expiredText = L10n(ref.read(localeCodeProvider)).sessionExpired;
          ScaffoldMessenger.of(navContext).showSnackBar(
            SnackBar(content: Text(expiredText)),
          );
        }
        rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
          LoginScreen.route,
          (_) => false,
        );
      }
    });

    final localeCode = ref.watch(localeCodeProvider);
    final l10n = L10n(localeCode);

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: l10n.locale,
      supportedLocales: const [Locale('uk'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: SplashScreen.route,
      routes: {
        SplashScreen.route: (_) => const SplashScreen(),
        LoginScreen.route: (_) => const LoginScreen(),
        RegisterScreen.route: (_) => const RegisterScreen(),
        MapScreen.route: (_) => const MapScreen(),
        ProfileScreen.route: (_) => const ProfileScreen(),
      },
    );
  }
}
