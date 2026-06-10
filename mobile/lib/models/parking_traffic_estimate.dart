class ParkingTrafficEstimate {
  const ParkingTrafficEstimate({
    required this.parkingId,
    required this.trafficDelayRatio,
    required this.baseDurationSeconds,
    required this.trafficDurationSeconds,
  });

  final String parkingId;
  final double trafficDelayRatio;
  final int baseDurationSeconds;
  final int trafficDurationSeconds;

  factory ParkingTrafficEstimate.fromJson(Map<String, dynamic> json) {
    return ParkingTrafficEstimate(
      parkingId: json['parkingId'] as String,
      trafficDelayRatio: (json['trafficDelayRatio'] as num).toDouble(),
      baseDurationSeconds: json['baseDurationSeconds'] as int,
      trafficDurationSeconds: json['trafficDurationSeconds'] as int,
    );
  }
}
