import 'package:uuid/uuid.dart';

class EmergencyAlert {
  final String alertId;
  final String victimId;
  final String victimName;
  final double lat;
  final double lon;
  final DateTime timestamp;
  final double distance;

  EmergencyAlert({
    String? alertId,
    required this.victimId,
    this.victimName = 'Someone nearby',
    required this.lat,
    required this.lon,
    required this.timestamp,
    required this.distance,
  }) : alertId = alertId ?? const Uuid().v4();

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      victimId: json['victimId'] ?? '',
      victimName: json['victimName'] ?? 'Someone nearby',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'alertId': alertId,
    'victimId': victimId,
    'victimName': victimName,
    'lat': lat,
    'lon': lon,
    'timestamp': timestamp.toIso8601String(),
    'distance': distance,
  };
}