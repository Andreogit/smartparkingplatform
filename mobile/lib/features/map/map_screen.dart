import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/l10n.dart';
import '../../models/driving_route.dart';
import '../../models/parking.dart';
import '../../models/parking_traffic_estimate.dart';
import '../../models/recommendation.dart';
import '../../providers.dart';
import '../../providers/favorites_provider.dart';
import '../../services/api_error_message.dart';
import '../../services/api_service.dart';
import '../../utils/navigation_apps.dart';
import '../../utils/score_heatmap.dart';
import '../../widgets/map_dot_icon.dart';
import '../../widgets/parking_score_visual.dart';
import '../profile/profile_screen.dart';

/// Fallback map centre when GPS is unavailable (Lviv).
const double kDemoLatitude = 49.841439;
const double kDemoLongitude = 24.031955;

const double _parkingFocusZoom = 16;
const double _userLocationZoom = 15;
const int _nearbyParkingLimit = 10;
const List<double> _recommendationRadiusOptions = [2, 3, 4, 5];

ButtonStyle findParkingButtonStyle(ColorScheme scheme) {
  return FilledButton.styleFrom(
    elevation: 0,
    shadowColor: Colors.transparent,
    disabledBackgroundColor: scheme.surfaceContainerHighest,
    disabledForegroundColor: scheme.onSurfaceVariant,
    minimumSize: const Size(0, 45),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.1,
    ),
  ).copyWith(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.surfaceContainerHighest;
      }
      return Color.lerp(scheme.secondary, scheme.primary, 0.3) ?? scheme.secondary;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return scheme.onSurfaceVariant;
      }
      return scheme.onPrimary;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: scheme.outlineVariant, width: 2);
      }
      return BorderSide(color: scheme.primary.withOpacity(0.25), width: 2);
    }),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
  );
}

List<Parking> _takeNearestParkings(
  List<Parking> parkings,
  double latitude,
  double longitude, {
  int limit = _nearbyParkingLimit,
}) {
  final sorted = List<Parking>.from(parkings)
    ..sort(
      (a, b) => Geolocator.distanceBetween(
            latitude,
            longitude,
            a.latitude,
            a.longitude,
          ).compareTo(
            Geolocator.distanceBetween(
              latitude,
              longitude,
              b.latitude,
              b.longitude,
            ),
          ),
    );
  return sorted.take(limit).toList();
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  static const route = '/map';

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  /// New platform view per [MapScreen] mount (fixes iOS `recreating_view` after hot restart).
  late final Key _mapInstanceKey = UniqueKey();

  /// Layout bounds only — do not attach to [GoogleMap] (GlobalKey + UiKitView breaks on restart).
  final GlobalKey _mapBoundsKey = GlobalKey();

  GoogleMapController? _mapController;
  BitmapDescriptor? _dotIcon;
  BitmapDescriptor? _dotIconSelected;

  bool _mapLayoutReady = false;

  bool _loading = true;
  bool _findingParking = false;
  bool _showAllParkings = false;
  bool _showFavoritesOnly = false;
  double _recommendationRadiusKm = kDefaultRecommendationRadiusKm;
  bool _showScoreHeatmap = false;
  String? _error;
  List<Parking> _allParkings = const [];
  List<Parking> _parkings = const [];
  List<RankedParking> _allRanked = const [];
  List<RankedParking> _ranked = const [];

  String? _selectedParkingId;
  Parking? _selectedParking;
  double? _selectedScore;
  ScoreComponents? _selectedComponents;
  List<LatLng> _routePoints = const [];
  int _routePolylineGeneration = 0;
  DrivingRoute? _routeInfo;
  ParkingTrafficEstimate? _trafficEstimate;
  LatLng? _routeOrigin;
  LatLng? _userOrigin;
  bool _routeLoading = false;

  /// Parkings the user skipped while searching for a better spot.
  final Set<String> _dismissedParkingIds = {};

  bool _markerIconsRequested = false;

  int _rankIndexForParkingId(String parkingId) {
    return _ranked.indexWhere((r) => r.parkingId == parkingId);
  }

  RankedParking? _rankedForParkingId(String parkingId) {
    for (final item in _ranked) {
      if (item.parkingId == parkingId) {
        return item;
      }
    }
    return null;
  }

  RankedParking? _nextAvailableRanked({String? excludeParkingId}) {
    for (final item in _ranked) {
      if (_dismissedParkingIds.contains(item.parkingId)) {
        continue;
      }
      if (excludeParkingId != null && item.parkingId == excludeParkingId) {
        continue;
      }
      return item;
    }
    return null;
  }

  Parking? _parkingForId(String parkingId) {
    for (final p in _parkings) {
      if (p.id == parkingId) {
        return p;
      }
    }
    for (final p in _allParkings) {
      if (p.id == parkingId) {
        return p;
      }
    }
    return null;
  }

  bool get _hasNextParkingOption {
    if (_showAllParkings || _selectedParkingId == null) {
      return false;
    }
    return _nextAvailableRanked(excludeParkingId: _selectedParkingId) != null;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(favoriteParkingIdsProvider.notifier).reload();
      await _load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_markerIconsRequested) {
      _markerIconsRequested = true;
      _loadMarkerIcons();
    }
  }

  @override
  void dispose() {
    // Platform view disposed in [_PersistentMapViewState.dispose].
    _mapController = null;
    super.dispose();
  }

  Size? _mapAreaSize() {
    final context = _mapBoundsKey.currentContext;
    if (context == null) {
      return null;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return null;
    }
    return box.size;
  }

  Future<void> _loadMarkerIcons() async {
    final scheme = Theme.of(context).colorScheme;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final normal = await buildMapDotIcon(
      fill: scheme.primary,
      imagePixelRatio: pixelRatio,
    );
    final selected = await buildMapDotIcon(
      fill: scheme.primary,
      size: 16,
      imagePixelRatio: pixelRatio,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _dotIcon = normal;
      _dotIconSelected = selected;
    });
  }

  void _applyParkingData({
    required List<Parking> allParkings,
    required List<RankedParking> allRanked,
    required double latitude,
    required double longitude,
    bool? showAllParkings,
    bool? showFavoritesOnly,
  }) {
    final favoriteIds = ref.read(favoriteParkingIdsProvider);
    final favoritesMode = showFavoritesOnly ?? _showFavoritesOnly;

    var scopedParkings = allParkings;
    var scopedRanked = allRanked;
    if (favoritesMode) {
      scopedParkings = allParkings.where((p) => favoriteIds.contains(p.id)).toList();
      scopedRanked = allRanked.where((r) => favoriteIds.contains(r.parkingId)).toList();
    }

    final nearest = _takeNearestParkings(scopedParkings, latitude, longitude);
    final nearestIds = nearest.map((p) => p.id).toSet();
    final showAll = showAllParkings ?? _showAllParkings;

    _allParkings = allParkings;
    _allRanked = allRanked;
    _showAllParkings = showAll;
    _showFavoritesOnly = favoritesMode;
    if (showAll) {
      _parkings = scopedParkings;
      _ranked = scopedRanked;
    } else {
      _parkings = nearest;
      _ranked = scopedRanked.where((r) => nearestIds.contains(r.parkingId)).toList();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final origin = await _resolveOrigin();
      final parkings = await api.listParkings();
      final ranked = await api.recommendationsNearby(
        latitude: origin.latitude,
        longitude: origin.longitude,
        radiusKm: _recommendationRadiusKm,
      );
      setState(() {
        _userOrigin = origin;
        _dismissedParkingIds.clear();
        _applyParkingData(
          allParkings: parkings,
          allRanked: ranked,
          latitude: origin.latitude,
          longitude: origin.longitude,
        );
      });
      if (_dotIcon == null && mounted) {
        await _loadMarkerIcons();
      }
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _findBestParking() async {
    if (_findingParking) {
      return;
    }

    final t = ref.l10n;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _findingParking = true;
      _showAllParkings = false;
      _showFavoritesOnly = false;
      _error = null;
      _dismissedParkingIds.clear();
    });

    try {
      final api = ref.read(apiServiceProvider);
      final origin = await _resolveOrigin();
      final parkings = await api.listParkings();
      final ranked = await api.recommendationsNearby(
        latitude: origin.latitude,
        longitude: origin.longitude,
        radiusKm: _recommendationRadiusKm,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _userOrigin = origin;
        _applyParkingData(
          allParkings: parkings,
          allRanked: ranked,
          latitude: origin.latitude,
          longitude: origin.longitude,
          showAllParkings: false,
        );
      });

      final best = _nextAvailableRanked();
      if (best == null) {
        messenger.showSnackBar(SnackBar(content: Text(t.noParkingFound)));
        return;
      }

      final parking = _parkingForId(best.parkingId);
      if (parking == null) {
        messenger.showSnackBar(SnackBar(content: Text(t.noParkingFound)));
        return;
      }

      await _selectParking(parking, score: best.score);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(t.loadFailed(e))));
      }
    } finally {
      if (mounted) {
        setState(() => _findingParking = false);
      }
    }
  }

  void _closeDrawerIfOpen() {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _findNextParking() async {
    if (_findingParking || _selectedParkingId == null) {
      return;
    }

    final t = ref.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final currentId = _selectedParkingId!;

    final next = _nextAvailableRanked(excludeParkingId: currentId);
    if (next == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.noMoreParkingOptions)));
      return;
    }

    final parking = _parkingForId(next.parkingId);
    if (parking == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.noMoreParkingOptions)));
      return;
    }

    setState(() {
      _dismissedParkingIds.add(currentId);
      _findingParking = true;
    });

    try {
      await _selectParking(parking, score: next.score);
    } finally {
      if (mounted) {
        setState(() => _findingParking = false);
      }
    }
  }

  Future<void> _enterAllParkingsMode() async {
    _closeDrawerIfOpen();

    if (_allParkings.isEmpty) {
      await _load();
      if (!mounted || _allParkings.isEmpty) {
        return;
      }
    }

    setState(() {
      _showAllParkings = true;
      _showFavoritesOnly = false;
      _parkings = _allParkings;
      _ranked = _allRanked;
    });
    _clearSelection();

    final origin = await _resolveOrigin();
    if (!mounted) {
      return;
    }
    setState(() => _userOrigin = origin);
    await _afterMapLayoutChanged();
    final points = [
      origin,
      ..._allParkings.map((p) => LatLng(p.latitude, p.longitude)),
    ];
    await _fitPointsOnMap(points, edgePadding: 56);
  }

  void _enterFavoritesMode() {
    _closeDrawerIfOpen();
    if (_allParkings.isEmpty) {
      _load();
      return;
    }

    final origin = _userOrigin ?? const LatLng(kDemoLatitude, kDemoLongitude);
    setState(() {
      _showFavoritesOnly = true;
      _showAllParkings = false;
      _applyParkingData(
        allParkings: _allParkings,
        allRanked: _allRanked,
        latitude: origin.latitude,
        longitude: origin.longitude,
        showAllParkings: false,
        showFavoritesOnly: true,
      );
    });
    _clearSelection();
  }

  Future<void> _toggleFavorite(String parkingId) async {
    final t = ref.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final added = await ref.read(favoriteParkingIdsProvider.notifier).toggle(parkingId);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(added ? t.addToFavorites : t.removeFromFavorites)),
      );
      if (_showFavoritesOnly) {
        final origin = _userOrigin ?? const LatLng(kDemoLatitude, kDemoLongitude);
        setState(() {
          _applyParkingData(
            allParkings: _allParkings,
            allRanked: _allRanked,
            latitude: origin.latitude,
            longitude: origin.longitude,
            showFavoritesOnly: true,
          );
        });
      } else {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      }
    }
  }

  Future<void> _setRecommendationRadius(double km) async {
    if (_recommendationRadiusKm == km) {
      return;
    }
    setState(() => _recommendationRadiusKm = km);
    await _load();
  }

  void _onRadiusSelectionChanged(Set<double> selected) {
    if (selected.isEmpty) {
      return;
    }
    _closeDrawerIfOpen();
    _setRecommendationRadius(selected.first);
  }

  Future<void> _enterNearbyMode() async {
    _closeDrawerIfOpen();

    final origin = await _resolveOrigin();
    if (!mounted) {
      return;
    }

    setState(() {
      _userOrigin = origin;
      _applyParkingData(
        allParkings: _allParkings,
        allRanked: _allRanked,
        latitude: origin.latitude,
        longitude: origin.longitude,
        showAllParkings: false,
        showFavoritesOnly: false,
      );
    });
    _clearSelection();
  }

  int _distanceMetersToParking(Parking parking) {
    final origin = _userOrigin ?? const LatLng(kDemoLatitude, kDemoLongitude);
    return Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      parking.latitude,
      parking.longitude,
    ).round();
  }

  void _onMapCreated(GoogleMapController controller) {
    if (_mapController != null) {
      return;
    }
    _mapController = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _mapLayoutReady = true);
        }
      });
    });
  }

  Future<void> _waitForNextFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  /// Waits until the platform map has a real size and projection (fixes first camera move).
  Future<void> _ensureMapReadyForCamera() async {
    for (var attempt = 0; attempt < 80 && mounted; attempt++) {
      final controller = _mapController;
      if (controller == null) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        continue;
      }

      final size = _mapAreaSize();
      if (size == null || size.width < 50 || size.height < 50) {
        await _waitForNextFrame();
        continue;
      }

      try {
        await controller.getLatLng(
          ScreenCoordinate(
            x: (size.width / 2).round(),
            y: (size.height / 2).round(),
          ),
        );
        return;
      } catch (_) {
        await _waitForNextFrame();
      }
    }
  }

  /// After [setState] changes map panel flex, layout must settle before [LatLngBounds] fit.
  Future<void> _afterMapLayoutChanged() async {
    await _waitForNextFrame();
    await _waitForNextFrame();
    await _ensureMapReadyForCamera();
  }

  Future<LatLng> _resolveOrigin() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LatLng(kDemoLatitude, kDemoLongitude);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const LatLng(kDemoLatitude, kDemoLongitude);
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return const LatLng(kDemoLatitude, kDemoLongitude);
    }
  }

  Future<void> _centerOn(LatLng target, {double zoom = _parkingFocusZoom}) async {
    await _ensureMapReadyForCamera();
    final controller = _mapController;
    if (!mounted || controller == null) {
      return;
    }

    for (var attempt = 0; attempt < 3 && mounted; attempt++) {
      if (attempt > 0) {
        await _waitForNextFrame();
        await _ensureMapReadyForCamera();
      }

      final size = _mapAreaSize();
      if (size == null || size.width < 50 || size.height < 50) {
        try {
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: target, zoom: zoom),
            ),
          );
        } catch (_) {}
        continue;
      }

      final centerX = (size.width / 2).round();
      final centerY = (size.height / 2).round();

      try {
        await controller.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: zoom),
          ),
        );

        var cameraTarget = target;
        final geoAtPanelCenter = await controller.getLatLng(
          ScreenCoordinate(x: centerX, y: centerY),
        );
        cameraTarget = LatLng(
          target.latitude + (target.latitude - geoAtPanelCenter.latitude),
          target.longitude + (target.longitude - geoAtPanelCenter.longitude),
        );

        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: cameraTarget, zoom: zoom),
          ),
        );
        return;
      } catch (_) {
        // Projection or camera not ready — retry after next frame.
      }
    }
  }

  /// Zooms the map so all [points] are visible (e.g. you + selected parking + route).
  Future<void> _fitPointsOnMap(
    Iterable<LatLng> points, {
    double edgePadding = 72,
  }) async {
    final list = points.toList();
    if (list.isEmpty) {
      return;
    }
    if (list.length == 1) {
      await _centerOn(list.first, zoom: _parkingFocusZoom);
      return;
    }

    await _ensureMapReadyForCamera();
    final controller = _mapController;
    if (!mounted || controller == null) {
      return;
    }

    var minLat = list.first.latitude;
    var maxLat = minLat;
    var minLng = list.first.longitude;
    var maxLng = minLng;

    for (final p in list) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // Avoid over-zoom when origin and parking are very close.
    const minSpan = 0.004;
    if (maxLat - minLat < minSpan) {
      final mid = (maxLat + minLat) / 2;
      minLat = mid - minSpan / 2;
      maxLat = mid + minSpan / 2;
    }
    if (maxLng - minLng < minSpan) {
      final mid = (maxLng + minLng) / 2;
      minLng = mid - minSpan / 2;
      maxLng = mid + minSpan / 2;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    for (var attempt = 0; attempt < 3 && mounted; attempt++) {
      if (attempt > 0) {
        await _waitForNextFrame();
        await _ensureMapReadyForCamera();
      }
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, edgePadding),
        );
        return;
      } catch (_) {
        // Common on first open when map size was still zero.
      }
    }
    await _centerOn(list.last, zoom: _parkingFocusZoom);
  }

  void _clearSelection() {
    setState(() {
      _selectedParkingId = null;
      _selectedParking = null;
      _selectedScore = null;
      _selectedComponents = null;
      _routePoints = const [];
      _routePolylineGeneration++;
      _routeInfo = null;
      _trafficEstimate = null;
      _routeOrigin = null;
      _routeLoading = false;
    });
  }

  Future<void> _selectParking(Parking parking, {double? score}) async {
    final t = ref.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ranked = _rankedForParkingId(parking.id);

    setState(() {
      _dismissedParkingIds.remove(parking.id);
      _selectedParkingId = parking.id;
      _selectedParking = parking;
      _selectedScore = score ?? ranked?.score;
      _selectedComponents = ranked?.components;
      _routePoints = const [];
      _routePolylineGeneration++;
      _routeInfo = null;
      _trafficEstimate = null;
      _routeOrigin = null;
      _routeLoading = true;
    });

    final originFuture = _resolveOrigin();
    // Panel flex changes (3→8); bounds must use the new map size, not the pre-panel layout.
    await _afterMapLayoutChanged();

    final origin = await originFuture;
    if (!mounted) {
      return;
    }

    setState(() => _routeOrigin = origin);

    final parkingLatLng = LatLng(parking.latitude, parking.longitude);

    await _fitPointsOnMap([origin, parkingLatLng]);

    final api = ref.read(apiServiceProvider);
    DrivingRoute? route;
    ParkingTrafficEstimate? trafficEstimate;
    Object? routeError;

    await Future.wait([
      () async {
        try {
          route = await api.drivingRouteToParking(
            parkingId: parking.id,
            originLatitude: origin.latitude,
            originLongitude: origin.longitude,
          );
        } catch (e) {
          routeError = e;
        }
      }(),
      () async {
        try {
          trafficEstimate = await api.trafficEstimate(parking.id);
        } catch (_) {
          // Traffic estimate is optional; panel falls back to recommendation data.
        }
      }(),
    ]);

    if (!mounted) {
      return;
    }

    if (route != null) {
      setState(() {
        _routePoints = route!.points;
        _routePolylineGeneration++;
        _routeInfo = route;
        _trafficEstimate = trafficEstimate;
        _routeLoading = false;
      });
      await _afterMapLayoutChanged();
      await _fitPointsOnMap([origin, parkingLatLng, ...route!.points]);
      await _nudgeMapRender();
    } else {
      setState(() {
        _trafficEstimate = trafficEstimate;
        _routeLoading = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('${t.routeUnavailable}\n${apiErrorMessage(routeError!)}')),
      );
      await _fitPointsOnMap([origin, parkingLatLng]);
    }

    final token = ref.read(authTokenProvider);
    final scoreToSave = score ?? ranked?.score;
    if (token != null && token.isNotEmpty && scoreToSave != null) {
      api.saveRecommendation(parkingId: parking.id, score: scoreToSave).ignore();
    }
  }

  Future<void> _goToMyLocation() async {
    final t = ref.l10n;
    final messenger = ScaffoldMessenger.of(context);

    if (!await Geolocator.isLocationServiceEnabled()) {
      messenger.showSnackBar(SnackBar(content: Text(t.locationServicesOff)));
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      messenger.showSnackBar(SnackBar(content: Text(t.locationPermissionRequired)));
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      messenger.showSnackBar(SnackBar(content: Text(t.locationSettingsRequired)));
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      await _centerOn(
        LatLng(position.latitude, position.longitude),
        zoom: _userLocationZoom,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(t.locationError(e))));
    }
  }

  Map<String, LatLng> _parkingCoordinatesById() {
    return {
      for (final p in _allParkings) p.id: LatLng(p.latitude, p.longitude),
    };
  }

  Set<Heatmap> _buildHeatmaps() {
    if (!_showScoreHeatmap || _allRanked.isEmpty) {
      return const {};
    }
    return buildScoreHeatmapSet(
      ranked: _allRanked,
      parkingCoordinates: _parkingCoordinatesById(),
    );
  }

  void _toggleScoreHeatmap() {
    final t = ref.l10n;
    if (_allRanked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.scoreHeatmapUnavailable)),
      );
      return;
    }
    setState(() => _showScoreHeatmap = !_showScoreHeatmap);
  }

  Widget _scoreHeatmapLegend(ColorScheme scheme) {
    final t = ref.l10n;
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
      color: scheme.surface.withValues(alpha: 0.94),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.scoreHeatmapLegend,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 80,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  colors: [
                    ScorePalette.orangeRed,
                    ScorePalette.goldenYellow,
                    ScorePalette.yellowGreen,
                    ScorePalette.vibrantGreen,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    if (_parkings.isEmpty) {
      return {};
    }

    final dot = _dotIcon;
    final dotSelected = _dotIconSelected;
    final useCustomIcons = dot != null && dotSelected != null;

    final visible = _selectedParkingId == null
        ? _parkings
        : _parkings.where((p) => p.id == _selectedParkingId);

    return visible
        .map(
          (p) {
            final isSelected = p.id == _selectedParkingId;
            final icon = useCustomIcons
                ? (isSelected ? dotSelected! : dot!)
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
            return Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.latitude, p.longitude),
              icon: icon,
              anchor: useCustomIcons ? const Offset(0.5, 0.5) : const Offset(0.5, 1.0),
              onTap: () => _selectParking(p),
            );
          },
        )
        .toSet();
  }

  Future<void> _nudgeMapRender() async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    try {
      final zoom = await controller.getZoomLevel();
      await controller.moveCamera(CameraUpdate.zoomTo(zoom));
    } catch (_) {
      // Ignore — polyline may still appear on next gesture.
    }
  }

  Set<Polyline> _polylines(Color routeColor) {
    if (_routePoints.length < 2) {
      return {};
    }
    return {
      Polyline(
        polylineId: PolylineId('route_$_routePolylineGeneration'),
        points: List<LatLng>.from(_routePoints),
        color: routeColor,
        width: 6,
        zIndex: 2,
        geodesic: false,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  Widget _buildAllParkingsList(L10n t, ColorScheme scheme) {
    final origin = _userOrigin ?? const LatLng(kDemoLatitude, kDemoLongitude);
    final sorted = List<Parking>.from(_allParkings)
      ..sort(
        (a, b) => Geolocator.distanceBetween(
              origin.latitude,
              origin.longitude,
              a.latitude,
              a.longitude,
            ).compareTo(
              Geolocator.distanceBetween(
                origin.latitude,
                origin.longitude,
                b.latitude,
                b.longitude,
              ),
            ),
      );

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final parking = sorted[index];
        final selected = parking.id == _selectedParkingId;
        final distanceM = _distanceMetersToParking(parking);
        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant.withOpacity(0.6),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.local_parking_rounded, color: scheme.primary),
            title: Text(
              parking.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              t.formatDistance(distanceM),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            onTap: () => _selectParking(parking),
          ),
        );
      },
    );
  }

  Widget _wrapRefresh({required Widget child}) {
    return RefreshIndicator(
      onRefresh: _load,
      child: child,
    );
  }

  Widget _buildRecommendationsList(L10n t, ColorScheme scheme) {
    final favoriteIds = ref.watch(favoriteParkingIdsProvider);

    if (_loading) {
      return _wrapRefresh(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
    if (_error != null) {
      return _wrapRefresh(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(child: Text(_error!, textAlign: TextAlign.center)),
          ],
        ),
      );
    }
    if (_showFavoritesOnly) {
      if (favoriteIds.isEmpty) {
        return _wrapRefresh(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t.noFavoriteParkings, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        );
      }
      if (_parkings.isEmpty) {
        return _wrapRefresh(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t.noParkingFound, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        );
      }
    }
    if (_showAllParkings) {
      if (_allParkings.isEmpty) {
        return _wrapRefresh(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t.noParkingsOnMap, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        );
      }
      return _wrapRefresh(child: _buildAllParkingsList(t, scheme));
    }
    if (_parkings.isEmpty) {
      return _wrapRefresh(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(t.noParkingsOnMap, textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      );
    }
    return _wrapRefresh(
      child: ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      itemCount: _ranked.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = _ranked[index];
        final parking = _parkings
            .where((p) => p.id == item.parkingId)
            .cast<Parking?>()
            .firstOrNull;
        final selected = item.parkingId == _selectedParkingId;
        final scoreVisual = resolveParkingScoreVisual(
          rankIndex: index,
          totalCount: _ranked.length,
          l10n: t,
          forList: true,
        );
        return Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: scoreVisual.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? scheme.primary : scoreVisual.borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(
              item.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: ParkingScoreRow(
                score: item.score,
                rankIndex: index,
                totalCount: _ranked.length,
                l10n: t,
                compact: true,
              ),
            ),
            onTap: () {
              if (parking != null) {
                _selectParking(parking, score: item.score);
              }
            },
            trailing: IconButton(
              icon: Icon(
                favoriteIds.contains(item.parkingId)
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: scheme.primary,
              ),
              onPressed: () => _toggleFavorite(item.parkingId),
              tooltip: favoriteIds.contains(item.parkingId)
                  ? t.removeFromFavorites
                  : t.addToFavorites,
            ),
          ),
        );
      },
    ),
    );
  }

  Widget _buildSelectedPanel(L10n t, ColorScheme scheme) {
    final favoriteIds = ref.watch(favoriteParkingIdsProvider);
    final parking = _selectedParking!;
    final route = _routeInfo;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  parking.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => _toggleFavorite(parking.id),
                icon: Icon(
                  favoriteIds.contains(parking.id)
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: scheme.primary,
                ),
                tooltip: favoriteIds.contains(parking.id)
                    ? t.removeFromFavorites
                    : t.addToFavorites,
              ),
              IconButton(
                onPressed: _clearSelection,
                icon: const Icon(Icons.close_rounded),
                tooltip: t.close,
              ),
            ],
          ),
          if (_selectedScore != null) ...[
            const SizedBox(height: 2),
            Builder(
              builder: (context) {
                final rankIndex = parking.id.isNotEmpty
                    ? _rankIndexForParkingId(parking.id)
                    : -1;
                final visual = resolveParkingScoreVisual(
                  rankIndex: rankIndex >= 0 ? rankIndex : _ranked.length,
                  totalCount: _ranked.length,
                  l10n: t,
                );
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: visual.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: visual.borderColor, width: 2),
                  ),
                  child: ParkingScoreRow(
                    score: _selectedScore!,
                    rankIndex: rankIndex >= 0 ? rankIndex : _ranked.length,
                    totalCount: _ranked.length,
                    l10n: t,
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 8),
          if (_routeLoading)
            Row(
              children: [
                Expanded(
                  child: _RouteStatCard.loading(
                    scheme: scheme,
                    label: t.distance,
                    icon: Icons.route_rounded,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RouteStatCard.loading(
                    scheme: scheme,
                    label: t.duration,
                    icon: Icons.schedule_rounded,
                    compact: true,
                  ),
                ),
              ],
            )
          else if (route != null)
            Row(
              children: [
                Expanded(
                  child: _RouteStatCard(
                    icon: Icons.route_rounded,
                    label: t.distance,
                    value: t.formatDistance(route.distanceMeters),
                    scheme: scheme,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RouteStatCard(
                    icon: Icons.schedule_rounded,
                    label: t.duration,
                    value: t.formatDuration(route.durationSeconds),
                    scheme: scheme,
                    compact: true,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          if (_routeLoading)
            _RouteStatCard.loading(
              scheme: scheme,
              label: t.nearbyTraffic,
              icon: Icons.traffic_rounded,
              compact: true,
            )
          else ...[
            Builder(
              builder: (context) {
                final estimate = _trafficEstimate;
                final ratio = estimate?.trafficDelayRatio ??
                    _selectedComponents?.trafficDelayRatio;
                if (ratio != null) {
                  return _RouteStatCard(
                    icon: Icons.traffic_rounded,
                    label: t.nearbyTraffic,
                    value: t.trafficStatusDescription(ratio),
                    scheme: scheme,
                    compact: true,
                  );
                }
                return _RouteStatCard(
                  icon: Icons.traffic_rounded,
                  label: t.nearbyTraffic,
                  value: t.trafficUnavailable,
                  scheme: scheme,
                  compact: true,
                );
              },
            ),
            const SizedBox(height: 8),
            NavigationAppsRow(
              l10n: t,
              destination: NavigationTarget(
                latitude: parking.latitude,
                longitude: parking.longitude,
              ),
              origin: _routeOrigin == null
                  ? null
                  : NavigationTarget(
                      latitude: _routeOrigin!.latitude,
                      longitude: _routeOrigin!.longitude,
                    ),
            ),
          ],
            ],
          ),
        ),
        if (_hasNextParkingOption)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 10 + bottomInset),
            child: FilledButton.icon(
              onPressed: _findingParking ? null : _findNextParking,
              style: findParkingButtonStyle(scheme),
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(t.findNextParking),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasSelection = _selectedParking != null;

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  t.map,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.searchRadius,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<double>(
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        minimumSize: const Size(0, 30),
                        textStyle: Theme.of(context).textTheme.labelSmall,
                      ),
                      showSelectedIcon: false,
                      segments: [
                        for (final km in _recommendationRadiusOptions)
                          ButtonSegment<double>(
                            value: km,
                            label: Text(
                              t.radiusKmLabel(km),
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    height: 1.1,
                                  ),
                            ),
                          ),
                      ],
                      selected: {_recommendationRadiusKm},
                      onSelectionChanged: _onRadiusSelectionChanged,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.map_rounded),
                title: Text(t.allParkingSpots),
                selected: _showAllParkings,
                onTap: _enterAllParkingsMode,
              ),
              ListTile(
                leading: const Icon(Icons.near_me_rounded),
                title: Text(t.nearbyRecommendations),
                selected: !_showAllParkings && !_showFavoritesOnly,
                onTap: _enterNearbyMode,
              ),
              ListTile(
                leading: const Icon(Icons.star_rounded),
                title: Text(t.favoriteParkings),
                selected: _showFavoritesOnly,
                onTap: _enterFavoritesMode,
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(t.map),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: t.map,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _toggleScoreHeatmap,
            icon: Icon(
              _showScoreHeatmap ? Icons.blur_on_rounded : Icons.blur_off_rounded,
              color: _showScoreHeatmap ? scheme.primary : null,
            ),
            tooltip: t.scoreHeatmap,
          ),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: t.refresh,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: t.profile,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pushNamed(ProfileScreen.route),
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 22,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: hasSelection ? 8 : 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  key: _mapBoundsKey,
                  child: _PersistentMapView(
                    key: _mapInstanceKey,
                    markers: _buildMarkers(),
                    polylines: _polylines(scheme.primary),
                    heatmaps: _buildHeatmaps(),
                    onMapCreated: _onMapCreated,
                    onMapDisposed: () {
                      _mapController = null;
                      _mapLayoutReady = false;
                    },
                  ),
                ),
                if (_showScoreHeatmap && _allRanked.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 12,
                    child: _scoreHeatmapLegend(scheme),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                            onPressed: _findingParking ? null : _findBestParking,
                            style: findParkingButtonStyle(scheme),
                            child: _findingParking
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(t.findParking),
                                    ],
                                  )
                                : Text(t.findParking),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _goToMyLocation,
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.surface,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(45, 45),
                          shape: CircleBorder(
                            side: BorderSide(
                              color: scheme.secondary,
                              width: 2,
                            ),
                          ),
                        ),
                        icon: Icon(Icons.my_location, color: scheme.primary),
                        tooltip: t.myLocation,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ColoredBox(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, hasSelection ? 8 : 10, 16, hasSelection ? 4 : 6),
              child: Row(
                children: [
                  Text(
                    hasSelection
                        ? t.parkingDetails
                        : (_showFavoritesOnly
                            ? t.favoriteParkings
                            : (_showAllParkings ? t.allParkingSpots : t.recommendations)),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: hasSelection ? 7 : 2,
            child: ColoredBox(
              color: Colors.white,
              child: hasSelection
                  ? _buildSelectedPanel(t, scheme)
                  : _buildRecommendationsList(t, scheme),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStatCard extends StatelessWidget {
  const _RouteStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
    this.compact = false,
  });

  const _RouteStatCard.loading({
    required this.scheme,
    required this.label,
    required this.icon,
    this.compact = false,
  }) : value = null;

  final IconData icon;
  final String label;
  final String? value;
  final ColorScheme scheme;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hPad = compact ? 10.0 : 12.0;
    final vPad = compact ? 8.0 : 12.0;
    final iconPad = compact ? 6.0 : 8.0;
    final iconSize = compact ? 18.0 : 20.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(iconPad),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: iconSize, color: scheme.primary),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                if (value != null)
                  Text(
                    value!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                  )
                else
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hosts one [GoogleMap] per [MapScreen] mount; marker/polyline sets update via [setState] on parent.
class _PersistentMapView extends StatefulWidget {
  const _PersistentMapView({
    super.key,
    required this.markers,
    required this.polylines,
    required this.heatmaps,
    required this.onMapCreated,
    required this.onMapDisposed,
  });

  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Set<Heatmap> heatmaps;
  final void Function(GoogleMapController controller) onMapCreated;
  final VoidCallback onMapDisposed;

  @override
  State<_PersistentMapView> createState() => _PersistentMapViewState();
}

class _PersistentMapViewState extends State<_PersistentMapView> {
  GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    widget.onMapDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      compassEnabled: true,
      initialCameraPosition: const CameraPosition(
        target: LatLng(kDemoLatitude, kDemoLongitude),
        zoom: 13,
      ),
      markers: widget.markers,
      polylines: widget.polylines,
      heatmaps: widget.heatmaps,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        if (_controller != null) {
          return;
        }
        _controller = controller;
        widget.onMapCreated(controller);
      },
    );
  }
}
