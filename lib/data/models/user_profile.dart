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
  String themeMode; // "system", "light", "dark"
  List<String> tripHistory; // past destinations for AI memory
  bool showScreenshotButton; // Whether to show the floating camera button
  bool hasAgreedToTerms; // Whether the user accepted Privacy Policy & Terms

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
    this.themeMode = 'system',
    List<String>? tripHistory,
    this.showScreenshotButton = true,
    this.hasAgreedToTerms = false,
  })  : sosContacts = sosContacts ?? [],
        tripHistory = tripHistory ?? [];

  factory UserProfile.defaultProfile() {
    return UserProfile(
      preferredStyles: ['Adventure', 'Nature'],
      avgBudgetLkr: 50000,
      visitedPlaces: [],
      vibe: 'explorer',
      vibeTheme: 'ceylon_blue',
      themeMode: 'system',
      showScreenshotButton: true,
      hasAgreedToTerms: false,
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
        'themeMode': themeMode,
        'tripHistory': tripHistory,
        'showScreenshotButton': showScreenshotButton,
        'hasAgreedToTerms': hasAgreedToTerms,
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
        themeMode: json['themeMode'] ?? 'system',
        tripHistory: List<String>.from(json['tripHistory'] ?? []),
        showScreenshotButton: json['showScreenshotButton'] ?? true,
        hasAgreedToTerms: json['hasAgreedToTerms'] ?? false,
      );
}
