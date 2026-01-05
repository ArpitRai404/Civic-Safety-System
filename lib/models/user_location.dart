class UserLocation {
  final String id;
  final double lat;
  final double lon;
  final double? distance;

  UserLocation({
    required this.id,
    required this.lat,
    required this.lon,
    this.distance,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      id: json['id']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      distance: json['distance'] != null 
          ? (json['distance'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': lat,
    'lon': lon,
    if (distance != null) 'distance': distance,
  };
}