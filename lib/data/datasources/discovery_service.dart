import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/config/app_config.dart';
import 'user_preference_service.dart';

class DiscoveryPlace {
  final String id;
  final String name;
  final String district;
  final String category;
  final double lat;
  final double lng;
  final double rating;
  final String ticketRange;
  
  final String roadType;
  final String vehicleAccess;
  final List<String> riskTags;
  final String parkingRange;
  final String bestTime;
  final List<String> facilities;
  
  double distanceKm;
  String aiReason;

  DiscoveryPlace({
    required this.id,
    required this.name,
    required this.district,
    required this.category,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.ticketRange,
    required this.roadType,
    required this.vehicleAccess,
    required this.riskTags,
    required this.parkingRange,
    required this.bestTime,
    required this.facilities,
    this.distanceKm = 0.0,
    this.aiReason = '',
  });

  factory DiscoveryPlace.fromJson(Map<String, dynamic> json) {
    return DiscoveryPlace(
      id: json['id'].toString(),
      name: json['name'] as String,
      district: json['district'] as String,
      category: json['category'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      ticketRange: json['ticketRange'] as String,
      roadType: json['roadType'] as String? ?? '',
      vehicleAccess: json['vehicleAccess'] as String? ?? '',
      riskTags: List<String>.from(json['riskTags'] ?? []),
      parkingRange: json['parkingRange'] as String? ?? '',
      bestTime: json['bestTime'] as String? ?? '',
      facilities: List<String>.from(json['facilities'] ?? []),
    );
  }
}

class DiscoveryService {
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  static Future<List<DiscoveryPlace>> loadAndSortPlaces({
    double? userLat,
    double? userLng,
    String? filterCategory,
  }) async {
    final String response = await rootBundle.loadString('assets/places.json');
    final List<dynamic> data = json.decode(response);
    
    List<DiscoveryPlace> places = data.map((json) => DiscoveryPlace.fromJson(json)).toList();

    if (filterCategory != null && filterCategory != "All") {
      places = places.where((p) => p.category.toLowerCase().contains(filterCategory.toLowerCase())).toList();
    }

    if (userLat != null && userLng != null) {
      for (var place in places) {
        final distanceMeters = Geolocator.distanceBetween(
          userLat, userLng, place.lat, place.lng,
        );
        place.distanceKm = distanceMeters / 1000.0;
      }
      places.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    return places;
  }

  static Future<List<DiscoveryPlace>> getAiRecommendations(List<DiscoveryPlace> nearbyPlaces) async {
    if (nearbyPlaces.isEmpty) return [];
    
    final topNearest = nearbyPlaces.take(10).toList();
    final profile = UserPreferenceService.getProfile();
    
    final prompt = '''
Here are some places near the user:
\${topNearest.map((p) => "- [\${p.id}] \${p.name} (\${p.category}, \${p.distanceKm.toStringAsFixed(1)}km away)").join("\\n")}

The user's vibe is "\${profile.vibe}".
Rank exactly the top 3 places that best match their vibe and provide a short, enticing 1-sentence reason why they should visit.
Return ONLY valid JSON in this exact format, with no markdown formatting or other text:
[
  {"id": "place_id", "reason": "reason here"}
]
''';

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: AppConfig.apiKey,
      );
      
      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? "[]";
      
      final cleanJson = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> aiResults = json.decode(cleanJson);
      
      final resultPlaces = <DiscoveryPlace>[];
      for (var aiItem in aiResults) {
        final placeId = aiItem['id'].toString();
        try {
          final place = topNearest.firstWhere((p) => p.id == placeId);
          place.aiReason = aiItem['reason'].toString();
          if (!resultPlaces.contains(place)) {
            resultPlaces.add(place);
          }
        } catch (_) {}
      }
      
      return resultPlaces.isEmpty ? topNearest.take(3).toList() : resultPlaces;

    } catch (e) {
      return topNearest.take(3).toList();
    }
  }
}
