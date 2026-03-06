import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Clean & Modern Palette (Eco-Friendly & Trustworthy) ---
  static const Color modernGreen = Color(0xFF2E7D32); // Primary Green
  static const Color modernBlue  = Color(0xFF1976D2); // Secondary Blue
  static const Color pureWhite   = Color(0xFFFFFFFF); // Clean Background
  static const Color softGray    = Color(0xFFF8FAFC); // Subtle Surface
  static const Color darkText    = Color(0xFF1E293B); // Dark Slate for readability

  // --- Dark Theme Palette ---
  static const Color deepSlate   = Color(0xFF0F172A);
  static const Color softSlate   = Color(0xFF1E293B);
  static const Color skyBlue     = Color(0xFF38BDF8);
  static const Color mintGreen   = Color(0xFF34D399);
  static const Color offWhite    = Color(0xFFF1F5F9);

  // --- Legacy Palette (for compatibility) ---
  static const Color ceylonBlue = Color(0xFF003B5C);
  static const Color sigiriyaOchre = Color(0xFFC19A6B);

  static const Color surfaceWhite = Color(0xFFFAFAFA);
  static const Color backgroundGray = Color(0xFFF2F3F5);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color silkPearl = Color(0xFFF8F9FA); // Background Accent

  // Semantic
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFDC2626);

  // Dark mode surfaces
  static const Color darkSurface = Color(0xFF1A1D1C);
  static const Color darkCard = Color(0xFF262B2A);
  static const Color darkBorder = Color(0xFF3A3F3E);

  // --- Aliases for compatibility ---
  static const Color primaryBlue = ceylonBlue;
  static const Color accentOchre = sigiriyaOchre;

  // --- Luxury Shadows ---
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // --- Premium Gradients ---
  static const LinearGradient modernGradient = LinearGradient(
    colors: [modernGreen, modernBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient oceanGradient = LinearGradient(
    colors: [ceylonBlue, Color(0xFF002844)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// The ONE background all screens should use — deep navy to near-black
  static const LinearGradient appBackground = LinearGradient(
    colors: [Color(0xFF002035), Color(0xFF0D1117)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Glassmorphism Utils ---
  static BoxDecoration glassDecoration({
    double opacity = 0.12, 
    double blur = 25,
    BorderRadius? radius,
    Color? color,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withValues(alpha: opacity),
      borderRadius: radius ?? BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      boxShadow: softShadow,
    );
  }

  // --- Dynamic Time-Aware Overlay ---
  static Color getDynamicOverlay() {
    final hour = DateTime.now().hour;
    if (hour >= 18 || hour < 6) {
      return Colors.black.withValues(alpha: 0.2);
    }
    return Colors.transparent;
  }

  static TextStyle get budgetEmphasis => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: sigiriyaOchre,
    letterSpacing: 1,
  );

  /// Consistent label style (section headers, tags)
  static TextStyle get labelStyle => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: Colors.white60,
  );

  /// Consistent body text style
  static TextStyle get bodyStyle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  /// Ochre-accented left-border for cards
  static BoxDecoration ochreCardDecoration({
    double borderRadius = 16,
    double opacity = 0.06,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: const Border(
        left: BorderSide(color: sigiriyaOchre, width: 3),
        top: BorderSide(color: Colors.white10),
        right: BorderSide(color: Colors.white10),
        bottom: BorderSide(color: Colors.white10),
      ),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: pureWhite,
    colorScheme: ColorScheme.fromSeed(
      seedColor: modernGreen,
      primary: modernGreen,
      secondary: modernBlue,
      surface: pureWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkText,
      error: errorRed,
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: darkText),
      displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w600, color: darkText),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: darkText),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: darkText),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: pureWhite,
      foregroundColor: modernGreen,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: modernGreen,
      ),
      iconTheme: const IconThemeData(color: modernGreen),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: modernGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.03)),
      ),
      color: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: modernGreen,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      selectedColor: modernGreen.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(fontSize: 12),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deepSlate,
    colorScheme: ColorScheme.fromSeed(
      seedColor: skyBlue,
      brightness: Brightness.dark,
      primary: skyBlue,
      secondary: mintGreen,
      surface: softSlate,
      onPrimary: deepSlate,
      onSecondary: deepSlate,
      onSurface: offWhite,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: offWhite),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: offWhite),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: offWhite.withValues(alpha: 0.9)),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: offWhite.withValues(alpha: 0.7)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: offWhite,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      color: softSlate,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: mintGreen,
      foregroundColor: deepSlate,
    ),
    chipTheme: ChipThemeData(
      selectedColor: skyBlue.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.inter(fontSize: 12, color: offWhite),
    ),
  );

  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: ceylonBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// VIBE THEMES — Sri Lanka Inspired
// ───────────────────────────────────────────────────────────────────────────

class VibeTheme {
  final String id;
  final String name;
  final String emoji;
  final Color primary;
  final Color accent;
  final LinearGradient background;
  final LinearGradient cardGradient;

  const VibeTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primary,
    required this.accent,
    required this.background,
    required this.cardGradient,
  });
}

class VibeThemes {
  static const VibeTheme ceylonBlue = VibeTheme(
    id: 'ceylon_blue',
    name: 'Ceylon Blue',
    emoji: '🌊',
    primary: Color(0xFF003B5C),
    accent: Color(0xFFC19A6B),
    background: LinearGradient(
      colors: [Color(0xFF002035), Color(0xFF0D1117)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF003B5C), Color(0xFF001A2E)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
  );

  static const VibeTheme jungleGreen = VibeTheme(
    id: 'jungle_green',
    name: 'Sinharaja Jungle',
    emoji: '🌿',
    primary: Color(0xFF1B4332),
    accent: Color(0xFFD4A853),
    background: LinearGradient(
      colors: [Color(0xFF0A2A1A), Color(0xFF0D1A0D)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF1B4332), Color(0xFF0A2A1A)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
  );

  static const VibeTheme sunsetRed = VibeTheme(
    id: 'sunset_red',
    name: 'Galle Sunset',
    emoji: '🌅',
    primary: Color(0xFF7B2D00),
    accent: Color(0xFFFFB347),
    background: LinearGradient(
      colors: [Color(0xFF3D0C00), Color(0xFF1A0A00)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF7B2D00), Color(0xFF3D1500)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
  );

  static const VibeTheme lotusPink = VibeTheme(
    id: 'lotus_pink',
    name: 'Lotus Blossom',
    emoji: '🌸',
    primary: Color(0xFF6B1A3A),
    accent: Color(0xFFE8A0B4),
    background: LinearGradient(
      colors: [Color(0xFF2D0A1C), Color(0xFF110610)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF6B1A3A), Color(0xFF2D0A1C)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
  );

  static const VibeTheme midnightGold = VibeTheme(
    id: 'midnight_gold',
    name: 'Sigiriya Gold',
    emoji: '✨',
    primary: Color(0xFF2C1A00),
    accent: Color(0xFFFFD700),
    background: LinearGradient(
      colors: [Color(0xFF1A1000), Color(0xFF0D0A00)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF3D2800), Color(0xFF1A1000)],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
  );

  // 6th Vibe: Ocean & Nature (Green + Blue + White palette)
  static const VibeTheme oceanNature = VibeTheme(
    id: 'ocean_nature',
    name: 'Ocean & Nature',
    emoji: '🌿',
    primary: AppTheme.modernGreen,   
    accent: AppTheme.modernBlue,    
    background: LinearGradient(
      colors: [Color(0xFFE8F5E9), Color(0xFFE3F2FD)], // Very light green to light blue
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [AppTheme.modernGreen, AppTheme.modernBlue],
      begin: Alignment.topLeft, end: Alignment.bottomRight,
    ),
  );

  static const List<VibeTheme> all = [
    ceylonBlue,
    jungleGreen,
    sunsetRed,
    lotusPink,
    midnightGold,
    oceanNature,
  ];

  static VibeTheme fromId(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => ceylonBlue);
  }
}

