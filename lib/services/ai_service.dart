import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/place.dart';

class AiService {
  static const String _apiKey = "AIzaSyCsB2FtWMkfAEA21lB_7IzLc3b01fSgyMw";

  static Map<String, dynamic> buildContext({
    required double userLat,
    required double userLng,
    required double radius,
    required List<Place> nearbyPlaces,
    required String transportMode,
    required String budgetLevel,
  }) {
    return {
      "userLocation": {"lat": userLat, "lng": userLng},
      "radius": radius,
      "transportMode": transportMode,
      "budgetLevel": budgetLevel,
      "nearbyPlaces": nearbyPlaces.take(5).map((p) => {
        "name": p.name,
        "district": p.district,
        "category": p.category,
        "riskTags": p.riskTags,
        "roadType": p.roadType,
        "rating": p.rating,
        "distance": p.distance,
      }).toList(),
    };
  }

  static Future<String> getAiRecommendation(String userPrompt, Map<String, dynamic> context) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: _apiKey,
      );

      final nearbyText = (context['nearbyPlaces'] as List).map((p) => 
        "- ${p['name']} (${p['category']}) in ${p['district']}. Road: ${p['roadType']}. Risks: ${p['riskTags']?.join(', ')}"
      ).join("\n");

      final fullPrompt = """
You are "LankaGem AI", an elite, local explorer and deep-knowledge guide for hidden gems in Sri Lanka. 
Your goal is to help users find places that aren't on standard tourist maps.

PERSONALITY:
- Enthusiastic, respectful, and deeply knowledgeable about Sri Lankan culture and geography.
- You use local greetings like "Ayubowan".
- You focus heavily on SAFETY and SUSTAINABILITY (protecting the gems).

User Location: ${context['userLocation']['lat']}, ${context['userLocation']['lng']}
Transport: ${context['transportMode']}
Budget Preference: ${context['budgetLevel']}

Nearby Hidden Gems:
$nearbyText

User Question: $userPrompt

Please provide a helpful, concise response in English. If they ask for a plan, use the names of the gems provided. If they ask about safety, refer to the road types and risks listed. Make it feel friendly and local (mentioning 'Ayubowan' is good!).
""";

      final content = [Content.text(fullPrompt)];
      final response = await model.generateContent(content);
      
      return response.text ?? "I'm sorry, I couldn't generate a response. Please try again.";
    } catch (e) {
      if (e.toString().contains("API_KEY_INVALID")) {
        return "Error: The API key provided seems invalid. Please check your Google AI Studio settings.";
      }
      return "Connect error: $e. Please check your internet connection.";
    }
  }
}
