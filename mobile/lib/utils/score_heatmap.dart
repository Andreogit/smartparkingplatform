import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/recommendation.dart';
import '../widgets/parking_score_visual.dart';

const HeatmapId kScoreHeatmapId = HeatmapId('score_heatmap');

/// Green = lower score (better); red = higher score (worse).
const HeatmapGradient kScoreHeatmapGradient = HeatmapGradient(<HeatmapGradientColor>[
  HeatmapGradientColor(ScorePalette.orangeRed, 0.2),
  HeatmapGradientColor(ScorePalette.goldenYellow, 0.45),
  HeatmapGradientColor(ScorePalette.yellowGreen, 0.7),
  HeatmapGradientColor(ScorePalette.vibrantGreen, 1),
]);

int scoreHeatmapRadiusPixels() {
  if (kIsWeb) {
    return 12;
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 28,
    TargetPlatform.iOS => 48,
    _ => 28,
  };
}

/// Builds weighted map points from ranked scores (higher weight = better / lower score).
List<WeightedLatLng> buildScoreHeatmapPoints({
  required List<RankedParking> ranked,
  required Map<String, LatLng> parkingCoordinates,
}) {
  if (ranked.isEmpty) {
    return const [];
  }

  var minScore = ranked.first.score;
  var maxScore = ranked.first.score;
  for (final item in ranked) {
    if (item.score < minScore) {
      minScore = item.score;
    }
    if (item.score > maxScore) {
      maxScore = item.score;
    }
  }

  final span = maxScore - minScore;
  final points = <WeightedLatLng>[];

  for (final item in ranked) {
    final coord = parkingCoordinates[item.parkingId];
    if (coord == null) {
      continue;
    }

    final weight = span <= 1e-9
        ? 1.0
        : (1.0 - (item.score - minScore) / span).clamp(0.15, 1.0);

    points.add(WeightedLatLng(coord, weight: weight));
  }

  return points;
}

Set<Heatmap> buildScoreHeatmapSet({
  required List<RankedParking> ranked,
  required Map<String, LatLng> parkingCoordinates,
}) {
  final data = buildScoreHeatmapPoints(
    ranked: ranked,
    parkingCoordinates: parkingCoordinates,
  );
  if (data.isEmpty) {
    return const {};
  }

  return {
    Heatmap(
      heatmapId: kScoreHeatmapId,
      data: data,
      gradient: kScoreHeatmapGradient,
      maxIntensity: 1,
      opacity: 0.72,
      radius: HeatmapRadius.fromPixels(scoreHeatmapRadiusPixels()),
    ),
  };
}
