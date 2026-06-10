import 'package:dio/dio.dart';

import '../models/auth_models.dart';
import '../models/driving_route.dart';
import '../models/parking.dart';
import '../models/parking_traffic_estimate.dart';
import '../models/recommendation.dart';

/// Default search radius for [/recommendations/nearby] (km).
const double kDefaultRecommendationRadiusKm = 5;

/// Thin wrapper around Dio — keeps networking code out of widgets.
class ApiService {
  ApiService(this._dio);

  final Dio _dio;

  Future<AuthResponse> register({required String email, required String password}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(res.data!);
  }

  Future<AuthResponse> login({required String email, required String password}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(res.data!);
  }

  Future<UserProfile> me() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/me');
    return UserProfile.fromJson(res.data!);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch<void>(
      '/users/me/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<List<Parking>> listParkings() async {
    final res = await _dio.get<List<dynamic>>('/parking');
    return (res.data ?? []).map((e) => Parking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DrivingRoute> drivingRouteToParking({
    required String parkingId,
    required double originLatitude,
    required double originLongitude,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/parking/$parkingId/route',
      queryParameters: {
        'originLatitude': originLatitude,
        'originLongitude': originLongitude,
      },
    );
    return DrivingRoute.fromJson(res.data!);
  }

  Future<ParkingTrafficEstimate> trafficEstimate(String parkingId) async {
    final res = await _dio.get<Map<String, dynamic>>('/parking/$parkingId/traffic-estimate');
    return ParkingTrafficEstimate.fromJson(res.data!);
  }

  Future<List<RankedParking>> recommendationsNearby({
    required double latitude,
    required double longitude,
    double radiusKm = kDefaultRecommendationRadiusKm,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/recommendations/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
      },
    );
    return (res.data ?? []).map((e) => RankedParking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveRecommendation({required String parkingId, required double score}) async {
    await _dio.post<void>(
      '/recommendations',
      data: {'parkingId': parkingId, 'score': score},
    );
  }

  Future<List<String>> listFavoriteParkingIds() async {
    final res = await _dio.get<Map<String, dynamic>>('/users/me/favorites');
    final ids = res.data?['parkingIds'];
    if (ids is! List) {
      return [];
    }
    return ids.map((e) => e.toString()).toList();
  }

  Future<void> addFavorite(String parkingId) async {
    await _dio.post<void>('/users/me/favorites/$parkingId');
  }

  Future<void> removeFavorite(String parkingId) async {
    await _dio.delete<void>('/users/me/favorites/$parkingId');
  }

  /// Demonstrates authenticated POST — not required for the UI flow.
  Future<void> logTraffic({required String parkingId, required String trafficLevel}) async {
    await _dio.post<void>(
      '/traffic/logs',
      data: {'parkingId': parkingId, 'trafficLevel': trafficLevel},
    );
  }
}
