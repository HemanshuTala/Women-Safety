class LocationPoint {
  final double latitude;
  final double longitude;
  final String? address;

  LocationPoint({required this.latitude, required this.longitude, this.address});

  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude, 'address': address};

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
    latitude: json['latitude'] as double,
    longitude: json['longitude'] as double,
    address: json['address'] as String?,
  );
}

class Journey {
  final String id;
  final String userId;
  final LocationPoint startLocation;
  final LocationPoint endLocation;
  final String status;
  final double distanceTraveled;

  Journey({
    required this.id,
    required this.userId,
    required this.startLocation,
    required this.endLocation,
    required this.status,
    this.distanceTraveled = 0.0,
  });

  factory Journey.fromJson(Map<String, dynamic> json) => Journey(
    id: json['_id'] as String,
    userId: json['userId'] as String,
    startLocation: LocationPoint.fromJson(json['startLocation']),
    endLocation: LocationPoint.fromJson(json['endLocation']),
    status: json['status'] as String,
    distanceTraveled: (json['distanceTraveled'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'userId': userId,
    'startLocation': startLocation.toJson(),
    'endLocation': endLocation.toJson(),
    'status': status,
    'distanceTraveled': distanceTraveled,
  };
}