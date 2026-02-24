import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Serendib Oracle Luxury Palette ---
  static const Color primaryBlue = Color(0xFF0B1C2D); // Deep Space Navy
  static const Color accentOchre = Color(0xFFC89B3C); // Sri Lankan Ochre Gold
  static const Color silkPearl = Color(0xFFF8F6F1);   // Silk Pearl
  static const Color softBlue = Color(0xFFD9E9F2);
  static const Color successGreen = Color(0xFF2E7D5B); // Tropical Leaf Green
  static const Color warningOrange = Color(0xFFE2725B); // Sunset Coral
  static const Color backgroundGray = Color(0xFFF1F0EA);

  // --- Luxury Concierge Shadows ---
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: primaryBlue.withOpacity(0.05),
          blurRadius: 30,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  // --- Glassmorphism Utils ---
  static BoxDecoration glassDecoration({
    double opacity = 0.6, 
    double blur = 15,
    BorderRadius? radius,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: radius ?? BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: silkPearl,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: accentOchre,
      surface: silkPearl,
      onPrimary: Colors.white,
    ),
    // Premium Typography: Outfit for Headings, Inter for Body
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      bodyLarge: GoogleFonts.inter(color: Colors.black87, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: Colors.black87, fontSize: 14),
      displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 32),
      displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 24),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: primaryBlue, fontSize: 18),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: primaryBlue,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryBlue,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
    ),
  );

  // --- Specialized Text Styles ---
  static TextStyle get budgetEmphasis => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: accentOchre,
      );

  // --- Ultra-Cinematic Time-Aware Logic ---
  static Color getDynamicOverlay() {
    final hour = DateTime.now().hour;
    if (hour >= 17 && hour <= 19) {
      // Golden Hour: Subtle amber warmth
      return Colors.orangeAccent.withOpacity(0.03);
    } else if (hour >= 20 || hour <= 5) {
      // Night Mode: Subtle cool indigo
      return Colors.indigoAccent.withOpacity(0.05);
    }
    return Colors.transparent;
  }

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF030C16), // Deeper space
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: primaryBlue,
      secondary: accentOchre,
      surface: const Color(0xFF0B1C2D),
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9)),
      bodyMedium: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9)),
    ),
  );

  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
