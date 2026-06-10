class RankedParking {
  const RankedParking({
    required this.parkingId,
    required this.name,
    required this.score,
    required this.components,
  });

  final String parkingId;
  final String name;
  final double score;
  final ScoreComponents components;

  factory RankedParking.fromJson(Map<String, dynamic> json) {
    return RankedParking(
      parkingId: json['parkingId'] as String,
      name: json['name'] as String,
      score: (json['score'] as num).toDouble(),
      components: ScoreComponents.fromJson(json['components'] as Map<String, dynamic>),
    );
  }
}

class ScoreComponents {
  const ScoreComponents({
    required this.trafficLevel,
    required this.trafficSource,
    this.trafficDelayRatio,
    required this.distance,
  });

  final double trafficLevel;
  final String trafficSource;
  final double? trafficDelayRatio;
  final double distance;

  bool get usesGoogleTraffic => trafficSource == 'google';

  factory ScoreComponents.fromJson(Map<String, dynamic> json) {
    return ScoreComponents(
      trafficLevel: (json['trafficLevel'] as num).toDouble(),
      trafficSource: json['trafficSource'] as String? ?? 'default',
      trafficDelayRatio: json['trafficDelayRatio'] == null
          ? null
          : (json['trafficDelayRatio'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
    );
  }
}
