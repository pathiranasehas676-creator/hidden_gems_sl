import '../models/place.dart';

class BudgetService {
  static Map<String, dynamic> calculateEstimate({
    required double totalDistance,
    required String transportMode,
    required List<Place> targetPlaces,
  }) {
    double fuelPrice = 350.0; // LKR/Liter roughly
    double efficiency = transportMode == "Car" ? 12 : transportMode == "Bike" ? 40 : 1; // km/L
    
    double fuelCost = (totalDistance / efficiency) * fuelPrice;
    
    double ticketCost = 0;
    double parkingCost = 0;
    
    for (var p in targetPlaces) {
      // Crude parsing of ticketRange/parkingRange strings
      if (p.ticketRange.contains("LKR")) {
        ticketCost += 500; // Average if specified
      }
      if (p.parkingRange.contains("LKR")) {
        parkingCost += 150;
      }
    }

    return {
      "fuelCost": fuelCost.toStringAsFixed(0),
      "ticketCost": ticketCost.toStringAsFixed(0),
      "parkingCost": parkingCost.toStringAsFixed(0),
      "total": (fuelCost + ticketCost + parkingCost).toStringAsFixed(0),
    };
  }
}
