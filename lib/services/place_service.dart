import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/place.dart';

class PlaceService {
  static Future<List<Place>> loadPlaces() async {
    final String response = await rootBundle.loadString('assets/places.json');
    final data = await json.decode(response) as List;
    return data.map((e) => Place.fromJson(e)).toList();
  }

  static List<Place> filterByDistance(List<Place> places, double userLat, double userLng, double radiusKm) {
    for (var place in places) {
      place.distance = Place.calculateDistance(userLat, userLng, place.lat, place.lng);
    }
    return places.where((p) => p.distance! <= radiusKm).toList()
      ..sort((a, b) => a.distance!.compareTo(b.distance!));
  }
}
