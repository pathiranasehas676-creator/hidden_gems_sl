import '../models/place.dart';

class ItineraryService {
  static List<Map<String, dynamic>> generateItinerary({
    required List<Place> places,
    required double hoursAvailable,
    required String transportMode,
  }) {
    List<Map<String, dynamic>> itinerary = [];
    double currentTimeUsed = 0;
    
    // Sort by distance (optimization: greedy nearest neighbor would be better for TSP, but this works for basic)
    places.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

    for (var place in places) {
      double travelTime = (place.distance ?? 0) / 25; // Estimate 25km/h in SL backroads
      double spendTime = 1.5; // Average 1.5 hours per place
      
      if (currentTimeUsed + travelTime + spendTime <= hoursAvailable) {
        itinerary.add({
          "place": place.name,
          "placeObj": place,
          "travelTime": "${travelTime.toStringAsFixed(1)}h",
          "travelHours": travelTime,
          "spendTime": "1.5h",
          "totalCost": "LKR 500-1500", // Placeholder
        });
        currentTimeUsed += travelTime + spendTime;
      }
    }

    return itinerary;
  }
}
