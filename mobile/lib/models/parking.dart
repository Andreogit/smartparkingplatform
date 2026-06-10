class Parking {
  const Parking({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.zone,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int capacity;
  final String zone;

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      capacity: (json['capacity'] as num).toInt(),
      zone: json['zone'] as String,
    );
  }
}
