import 'dart:math';

class Place {
  final String id;
  final String name;
  final String district;
  final String category;
  final double lat;
  final double lng;
  final double rating;
  final String roadType;
  final String vehicleAccess;
  final List<String> riskTags;
  final String ticketRange;
  final String parkingRange;
  final String bestTime;
  final List<String> facilities;
  double? distance;

  Place({
    required this.id,
    required this.name,
    required this.district,
    required this.category,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.roadType,
    required this.vehicleAccess,
    required this.riskTags,
    required this.ticketRange,
    required this.parkingRange,
    required this.bestTime,
    required this.facilities,
    this.distance,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'],
      district: json['district'],
      category: json['category'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      roadType: json['roadType'],
      vehicleAccess: json['vehicleAccess'],
      riskTags: List<String>.from(json['riskTags']),
      ticketRange: json['ticketRange'],
      parkingRange: json['parkingRange'],
      bestTime: json['bestTime'],
      facilities: List<String>.from(json['facilities']),
    );
  }

  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(endLat - startLat);
    double dLon = _toRadians(endLng - startLng);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(startLat)) * cos(_toRadians(endLat)) * 
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
