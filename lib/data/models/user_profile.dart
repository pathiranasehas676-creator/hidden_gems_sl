class UserProfile {
  List<String> preferredStyles;
  double avgBudgetLkr;
  List<String> visitedPlaces;
  String vibe; // "luxury", "explorer", "photographer", "budget"
  int totalTripsGenerated;
  String? languageCode;
  String? profileImagePath;
  List<String> sosContacts;
  String vibeTheme; // "ceylon_blue" | "jungle_green" | "sunset_red" | "lotus_pink" | "midnight_gold"
  List<String> tripHistory; // past destinations for AI memory

  UserProfile({
    required this.preferredStyles,
    required this.avgBudgetLkr,
    required this.visitedPlaces,
    required this.vibe,
    this.totalTripsGenerated = 0,
    this.languageCode,
    this.profileImagePath,
    List<String>? sosContacts,
    this.vibeTheme = 'ceylon_blue',
    List<String>? tripHistory,
  })  : sosContacts = sosContacts ?? [],
        tripHistory = tripHistory ?? [];

  factory UserProfile.defaultProfile() {
    return UserProfile(
      preferredStyles: ['Adventure', 'Nature'],
      avgBudgetLkr: 50000,
      visitedPlaces: [],
      vibe: 'explorer',
      vibeTheme: 'ceylon_blue',
    );
  }

  Map<String, dynamic> toJson() => {
        'preferredStyles': preferredStyles,
        'avgBudgetLkr': avgBudgetLkr,
        'visitedPlaces': visitedPlaces,
        'vibe': vibe,
        'totalTripsGenerated': totalTripsGenerated,
        'languageCode': languageCode,
        'profileImagePath': profileImagePath,
        'sosContacts': sosContacts,
        'vibeTheme': vibeTheme,
        'tripHistory': tripHistory,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        preferredStyles: List<String>.from(json['preferredStyles'] ?? []),
        avgBudgetLkr: (json['avgBudgetLkr'] ?? 50000).toDouble(),
        visitedPlaces: List<String>.from(json['visitedPlaces'] ?? []),
        vibe: json['vibe'] ?? 'explorer',
        totalTripsGenerated: json['totalTripsGenerated'] ?? 0,
        languageCode: json['languageCode'],
        profileImagePath: json['profileImagePath'],
        sosContacts: List<String>.from(json['sosContacts'] ?? []),
        vibeTheme: json['vibeTheme'] ?? 'ceylon_blue',
        tripHistory: List<String>.from(json['tripHistory'] ?? []),
      );
}
