class UserProfile {
  List<String> preferredStyles;
  double avgBudgetLkr;
  List<String> visitedPlaces;
  String vibe; // "luxury", "explorer", "photographer", "budget"
  int totalTripsGenerated;
  String? languageCode;
  String? profileImagePath;

  UserProfile({
    required this.preferredStyles,
    required this.avgBudgetLkr,
    required this.visitedPlaces,
    required this.vibe,
    this.totalTripsGenerated = 0,
    this.languageCode,
    this.profileImagePath,
  });

  factory UserProfile.defaultProfile() {
    return UserProfile(
      preferredStyles: ['Adventure', 'Nature'],
      avgBudgetLkr: 50000,
      visitedPlaces: [],
      vibe: 'explorer',
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
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        preferredStyles: List<String>.from(json['preferredStyles'] ?? []),
        avgBudgetLkr: (json['avgBudgetLkr'] ?? 50000).toDouble(),
        visitedPlaces: List<String>.from(json['visitedPlaces'] ?? []),
        vibe: json['vibe'] ?? 'explorer',
        totalTripsGenerated: json['totalTripsGenerated'] ?? 0,
        languageCode: json['languageCode'],
        profileImagePath: json['profileImagePath'],
      );
}
