class SafetyService {
  static Map<String, dynamic> getSafetyInfo(String district) {
    // Mock data for Sri Lankan districts
    final safetyData = {
      "Colombo": {
        "status": "Safe",
        "precautions": [
          "Be aware of heavy traffic and congestion.",
          "Use registered Taxis or Tuk-Tuks (PickMe/Uber).",
          "Stay hydrated during humid weather."
        ],
        "emergency": "119 (Police), 1990 (Ambulance)"
      },
      "Kandy": {
        "status": "Safe",
        "precautions": [
          "Roads can be slippery during rain.",
          "Beware of monkeys near temples.",
          "Dress modestly when visiting religious sites."
        ],
        "emergency": "119 (Police), 1990 (Ambulance)"
      },
      "Galle": {
        "status": "Caution - High Tide",
        "precautions": [
          "Avoid swimming in non-designated beach areas.",
          "Sunscreen is highly recommended.",
          "Keep an eye on weather warnings for coastal areas."
        ],
        "emergency": "119 (Police), 1990 (Ambulance)"
      },
      "Nuwara Eliya": {
        "status": "Safe - Cold Weather",
        "precautions": [
          "Carry warm clothing for the nights.",
          "Fog can reduce visibility on mountain roads.",
          "Check for landslide warnings during monsoon."
        ],
        "emergency": "119 (Police), 1990 (Ambulance)"
      },
      "Default": {
        "status": "Safe",
        "precautions": [
          "Follow local customs and traditions.",
          "Carry bottled water.",
          "Keep emergency contacts saved."
        ],
        "emergency": "119 (Police), 1990 (Ambulance)"
      }
    };

    return safetyData[district] ?? safetyData["Default"]!;
  }
}
