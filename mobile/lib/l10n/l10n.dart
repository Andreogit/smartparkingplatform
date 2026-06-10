import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// In-app strings for Ukrainian (default) and English.
class L10n {
  L10n(this.code);

  final String code;

  bool get isUk => code == 'uk';

  Locale get locale => Locale(code);

  String get appTitle => isUk ? 'Smart Parking Platform' : 'Smart Parking Platform';

  String get signInToContinue => isUk ? 'Увійдіть, щоб продовжити' : 'Sign in to continue';
  String get email => isUk ? 'Електронна пошта' : 'Email';
  String get password => isUk ? 'Пароль' : 'Password';
  String get signIn => isUk ? 'Увійти' : 'Sign in';
  String get signingIn => isUk ? 'Вхід…' : 'Signing in…';
  String get createAccount => isUk ? 'Створити обліковий запис' : 'Create an account';
  String get register => isUk ? 'Реєстрація' : 'Register';
  String get passwordHint => isUk ? 'Щонайменше 8 символів' : 'At least 8 characters';
  String get creatingAccount => isUk ? 'Створення…' : 'Creating account…';

  String get map => isUk ? 'Карта' : 'Map';
  String get profile => isUk ? 'Профіль' : 'Profile';
  String get logout => isUk ? 'Вийти' : 'Log out';
  String get myLocation => isUk ? 'Моє місцезнаходження' : 'My location';
  String get refresh => isUk ? 'Оновити' : 'Refresh';
  String get scoreHeatmap => isUk ? 'Теплова карта score' : 'Score heatmap';
  String get scoreHeatmapLegend =>
      isUk ? 'Зелений — кращий score' : 'Green — better score';
  String get scoreHeatmapUnavailable => isUk
      ? 'Немає даних score — оновіть рекомендації'
      : 'No score data — refresh recommendations';
  String get searchRadius => isUk ? 'Радіус рекомендацій' : 'Recommendation radius';
  String radiusKmLabel(double km) =>
      isUk ? '${km.toInt()}км' : '${km.toInt()}km';
  String get favoriteParkings => isUk ? 'Обрані паркомісця' : 'Favorite spots';
  String get addToFavorites => isUk ? 'Додати в обране' : 'Add to favorites';
  String get removeFromFavorites => isUk ? 'Прибрати з обраного' : 'Remove from favorites';
  String get noFavoriteParkings =>
      isUk ? 'Немає обраних паркомісць' : 'No favorite parking spots';
  String get sessionExpired =>
      isUk ? 'Сесію завершено. Увійдіть знову.' : 'Session expired. Please sign in again.';
  String get findParking => isUk ? 'Знайти парковку' : 'Find parking';
  String get findNextParking => isUk ? 'Наступне паркомісце' : 'Next parking';
  String get noMoreParkingOptions => isUk
      ? 'Більше немає інших варіантів поруч'
      : 'No more nearby options';
  String get allParkingSpots => isUk ? 'Всі паркомісця' : 'All parking spots';
  String get nearbyRecommendations => isUk ? 'Рекомендації поруч' : 'Nearby picks';
  String get noParkingFound =>
      isUk ? 'Поруч не знайдено паркомісць' : 'No parking spots found nearby';
  String get recommendations => isUk ? 'Рекомендації' : 'Recommendations';
  String scoreLabel(double value) =>
      isUk ? 'Оцінка ${value.toStringAsFixed(3)}' : 'Score ${value.toStringAsFixed(3)}';

  String get scoreBest => isUk ? 'Найкраще' : 'Best';
  String get scoreGood => isUk ? 'Добре' : 'Good';
  String get scoreWorse => isUk ? 'Гірше' : 'Worse';
  String get scoreWorst => isUk ? 'Найгірше' : 'Worst';

  String get parkingDetails => isUk ? 'Паркування' : 'Parking';
  String get zone => isUk ? 'Зона' : 'Zone';
  String get capacity => isUk ? 'Місткість' : 'Capacity';
  String get route => isUk ? 'Маршрут' : 'Route';
  String get distance => isUk ? 'Відстань' : 'Distance';
  String get duration => isUk ? 'Час у дорозі' : 'Duration';
  String get nearbyTraffic => isUk ? 'Трафік поруч' : 'Nearby traffic';
  String get trafficUnavailable =>
      isUk ? 'Дані про трафік недоступні' : 'Traffic data unavailable';

  String trafficLevelLabel(double ratio) {
    if (ratio <= 1.1) {
      return isUk ? 'Легкий' : 'Light';
    }
    if (ratio <= 1.35) {
      return isUk ? 'Помірний' : 'Moderate';
    }
    if (ratio <= 1.7) {
      return isUk ? 'Щільний' : 'Heavy';
    }
    return isUk ? 'Дуже щільний' : 'Severe';
  }

  /// Short status line for the selected parking panel (no delay percentage).
  String trafficStatusDescription(double ratio) {
    if (ratio <= 1.1) {
      return isUk ? 'Рух поруч вільний' : 'Light traffic nearby';
    }
    if (ratio <= 1.35) {
      return isUk ? 'Помірне завантаження доріг' : 'Moderate road traffic';
    }
    if (ratio <= 1.7) {
      return isUk ? 'Щільний рух біля парковки' : 'Heavy traffic near parking';
    }
    return isUk ? 'Дуже щільний рух на під\'їздах' : 'Very heavy traffic on approach roads';
  }

  String get openRouteIn => isUk ? 'Маршрут у навігаторі' : 'Open route in';
  String get couldNotOpenNavigationApp => isUk
      ? 'Не вдалося відкрити навігаційний застосунок'
      : 'Could not open navigation app';

  String formatTrafficDelay(double ratio) {
    if (ratio <= 1.001) {
      return isUk ? 'Без затримки' : 'No delay';
    }
    final pct = ((ratio - 1) * 100).round();
    return isUk ? '+$pct% затримка' : '+$pct% delay';
  }

  String get close => isUk ? 'Закрити' : 'Close';
  String get loadingRoute => isUk ? 'Побудова маршруту…' : 'Loading route…';
  String get routeUnavailable =>
      isUk ? 'Маршрут недоступний (перевірте Directions API)' : 'Route unavailable (check Directions API)';
  String get noParkingsOnMap => isUk
      ? 'Немає паркувань на карті. Запустіть backend і імпортуйте дані (npm run import-parkings).'
      : 'No parkings on the map. Start the backend and import data (npm run import-parkings).';

  String formatDistance(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return isUk ? '${km.toStringAsFixed(1)} км' : '${km.toStringAsFixed(1)} km';
    }
    return isUk ? '$meters м' : '$meters m';
  }

  String formatDuration(int seconds) {
    if (seconds < 60) {
      return isUk ? '$seconds с' : '$seconds sec';
    }
    final minutes = (seconds / 60).round();
    return isUk ? '$minutes хв' : '$minutes min';
  }
  String get latitude => isUk ? 'Широта' : 'Latitude';
  String get longitude => isUk ? 'Довгота' : 'Longitude';

  String get language => isUk ? 'Мова' : 'Language';
  String get ukrainian => isUk ? 'Українська' : 'Ukrainian';
  String get english => isUk ? 'English' : 'English';
  String get userId => isUk ? 'Ідентифікатор' : 'User ID';
  String get joinedAt => isUk ? 'Дата реєстрації' : 'Joined';
  String get account => isUk ? 'Обліковий запис' : 'Account';
  String get changePassword => isUk ? 'Змінити пароль' : 'Change password';
  String get currentPassword => isUk ? 'Поточний пароль' : 'Current password';
  String get newPassword => isUk ? 'Новий пароль' : 'New password';
  String get confirmNewPassword => isUk ? 'Підтвердіть новий пароль' : 'Confirm new password';
  String get savePassword => isUk ? 'Зберегти пароль' : 'Save password';
  String get savingPassword => isUk ? 'Збереження…' : 'Saving…';
  String get passwordChanged =>
      isUk ? 'Пароль успішно змінено' : 'Password changed successfully';
  String get passwordsDoNotMatch =>
      isUk ? 'Нові паролі не збігаються' : 'New passwords do not match';

  String get locationServicesOff =>
      isUk ? 'Увімкніть служби геолокації на пристрої' : 'Turn on location services on your device';
  String get locationPermissionRequired =>
      isUk ? 'Потрібен дозвіл на геолокацію' : 'Location permission is required';
  String get locationSettingsRequired =>
      isUk ? 'Увімкніть геолокацію в налаштуваннях системи' : 'Enable location in system settings';
  String locationError(Object e) =>
      isUk ? 'Не вдалося отримати координати: $e' : 'Could not get location: $e';

  String profileLoadError(Object e) =>
      isUk ? 'Не вдалося завантажити профіль: $e' : 'Could not load profile: $e';
  String loadFailed(Object e) => isUk ? 'Помилка завантаження: $e' : 'Failed to load: $e';

  String get privacyPolicy =>
      isUk ? 'Політика конфіденційності' : 'Privacy policy';
  String get privacyPolicyTitle =>
      isUk ? 'Політика конфіденційності' : 'Privacy policy';
  String get privacyPolicyIntro => isUk
      ? 'Smart Parking Platform — навчальний мобільний застосунок для інформаційної підтримки водія при пошуку паркування в м. Львів. Застосунок не є офіційним сервісом оплати чи муніципальним оператором паркування.'
      : 'Smart Parking Platform is an educational mobile app that helps drivers find parking in Lviv. It is not an official payment service or municipal parking operator.';
  String get privacyPolicyDataHeading =>
      isUk ? 'Які дані обробляються' : 'What data we process';
  String get privacyPolicyDataBody => isUk
      ? '• облікові дані: електронна пошта; пароль зберігається на сервері у вигляді хеша (bcrypt);\n'
        '• геолокація пристрою — для рекомендацій поблизу та маршруту (за вашою згодою в ОС);\n'
        '• історія збережених рекомендацій та список обраних паркомісць — у вашому обліковому записі на сервері;\n'
        '• технічні запити до REST API (авторизація JWT, координати запитів nearby).'
      : '• account data: email; password stored on the server as a bcrypt hash;\n'
        '• device location — for nearby recommendations and routes (with your OS permission);\n'
        '• saved recommendations and favorite parking spots in your server account;\n'
        '• technical REST API requests (JWT auth, coordinates for nearby queries).';
  String get privacyPolicyGoogleHeading =>
      isUk ? 'Сервіси Google' : 'Google services';
  String get privacyPolicyGoogleBody => isUk
      ? '• Google Maps SDK на пристрої відображає карту, маркери та маршрут; Google може отримувати дані про використання карти згідно з їхньою політикою.\n'
        '• Оцінка трафіку та побудова маршруту виконуються на сервері через Google Directions API; до Google передаються координати маршруту/майданчиків, необхідні для відповіді API.\n'
        '• Ключі доступу до Google налаштовуються розробником; не передавайте їх третім особам.'
      : '• Google Maps SDK on your device shows the map, markers, and route; Google may process map usage data under its policies.\n'
        '• Traffic estimates and routing run on our server via Google Directions API; coordinates needed for the API response are sent to Google.\n'
        '• API keys are configured by the developer; do not share them with third parties.';
  String get privacyPolicyDisclaimer => isUk
      ? 'Застосунок надає інформаційні рекомендації (score), а не гарантію вільного паркомісця. Використовуйте на свій розсуд і дотримуйтесь ПДР. Для питань щодо обробки даних звертайтесь до оператора навчального прототипу.'
      : 'The app provides informational recommendations (score), not a guarantee of an available space. Use at your own judgment and follow traffic rules. For data processing questions, contact the operator of this educational prototype.';
  String get privacyPolicyLinkGooglePrivacy =>
      isUk ? 'Політика конфіденційності Google' : 'Google Privacy Policy';
  String get privacyPolicyLinkGoogleMapsTerms =>
      isUk ? 'Умови Google Maps Platform' : 'Google Maps Platform Terms';
  String get couldNotOpenLink =>
      isUk ? 'Не вдалося відкрити посилання' : 'Could not open link';
}

final l10nProvider = Provider<L10n>((ref) => L10n(ref.watch(localeCodeProvider)));

extension L10nRef on WidgetRef {
  L10n get l10n => watch(l10nProvider);
}
