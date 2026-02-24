import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip_plan_model.dart';
import '../datasources/user_preference_service.dart';

class AiTripService {
  static const String _baseUrl = "http://192.168.8.168:8000/api";
  /// Toggle to false to disable RAG and use keyword-only KB on the server.
  static const bool ragEnabled = true;
  /// Dev key — in production, load from flutter_dotenv or equivalent.
  static const String _apiKey = "dev-key-local";

  static Future<TripPlan> generateTrip({
    required String origin,
    required double fromLat,
    required double fromLng,
    required String destination,
    required int days,
    required String startDate, // YYYY-MM-DD
    required String groupType, // solo/couple/family/friends
    required String pace, // relaxed/balanced/packed
    required int budgetLkr,
    required String style, // budget/comfort/luxury
    required List<String> interests,
    required String transportPreference, // train/bus/car/tuk/any
    required List<String> constraints,
    required List<String> mustInclude,
    required List<String> avoid,
  }) async {
    final url = Uri.parse("$_baseUrl/trip/plan");
    final userProfile = UserPreferenceService.getProfile();
    
    final body = {
      "origin": origin,
      "destination": destination,
      "days": days,
      "start_date": startDate,
      "group_type": groupType,
      "pace": pace,
      "budget_lkr": budgetLkr,
      "style": style,
      "transport_preference": transportPreference,
      "interests": interests,
      "constraints": constraints,
      "must_include": mustInclude,
      "avoid": avoid,
      "user_context": userProfile.toJson(),
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-TripMe-Key": _apiKey,
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TripPlan.fromJson(data);
      } else if (response.statusCode == 429) {
        throw Exception(
            "You've planned a lot today! TripMe.ai allows a few plans per hour. Try again soon. 🕐");
      } else if (response.statusCode >= 500) {
        throw Exception(
            "TripMe.ai is taking a break. Your cached plan is ready — tap the bookmark icon.");
      } else {
        String errorMessage = "Unknown API error (${response.statusCode})";
        try {
          final errorData = json.decode(response.body) as Map<String, dynamic>;
          errorMessage = errorData['detail']?['message'] as String? ?? errorMessage;
        } catch (_) {}
        throw Exception("TripMe.ai: $errorMessage");
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception("Could not connect to TripMe.ai Backend. Ensure the server is running at $_baseUrl");
      }
      rethrow;
    }
  }

  // Local extraction logic no longer needed as backend returns clean JSON
  // static String _extractJson(String text) { ... }
}


