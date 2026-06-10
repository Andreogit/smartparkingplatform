import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

final favoriteParkingIdsProvider =
    StateNotifierProvider<FavoriteParkingIdsNotifier, Set<String>>((ref) {
  return FavoriteParkingIdsNotifier(ref);
});

class FavoriteParkingIdsNotifier extends StateNotifier<Set<String>> {
  FavoriteParkingIdsNotifier(this._ref) : super({});

  final Ref _ref;

  Future<void> reload() async {
    final token = _ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      state = {};
      return;
    }
    try {
      final ids = await _ref.read(apiServiceProvider).listFavoriteParkingIds();
      state = ids.toSet();
    } catch (_) {
      // Keep previous favorites on transient errors.
    }
  }

  Future<bool> toggle(String parkingId) async {
    final token = _ref.read(authTokenProvider);
    if (token == null || token.isEmpty) {
      return false;
    }

    final api = _ref.read(apiServiceProvider);
    if (state.contains(parkingId)) {
      await api.removeFavorite(parkingId);
      state = Set<String>.from(state)..remove(parkingId);
      return false;
    }

    await api.addFavorite(parkingId);
    state = Set<String>.from(state)..add(parkingId);
    return true;
  }

  bool isFavorite(String parkingId) => state.contains(parkingId);
}
