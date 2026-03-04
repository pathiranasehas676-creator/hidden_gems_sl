import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Serendib Oracle Luxury Palette ---
  static const Color primaryBlue = Color(0xFF091F2C); // Deep Ocean Blue
  static const Color accentOchre = Color(0xFFD4AF37); // Sigiriya Gold
  static const Color silkPearl = Color(0xFFF8F6F1);   // Silk Pearl
  static const Color softBlue = Color(0xFFD9E9F2);
  static const Color successGreen = Color(0xFF1B4332); // Tropical Jungle Green
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

  // --- Premium Gradients ---
  static const LinearGradient oceanGradient = LinearGradient(
    colors: [primaryBlue, Color(0xFF0F2B3D)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient jungleGradient = LinearGradient(
    colors: [successGreen, Color(0xFF143324)],
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
      borderRadius: radius ?? BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      boxShadow: softShadow,
    );
  }

  // --- Dynamic Time-Aware Overlay ---
  static Color getDynamicOverlay() {
    final hour = DateTime.now().hour;
    if (hour >= 18 || hour < 6) {
      return Colors.black.withValues(alpha: 0.2); // Night mode tint
    }
    return Colors.transparent;
  }

  // --- Premium Component Styles ---
  static TextStyle get budgetEmphasis => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: accentOchre,
    letterSpacing: 1,
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: primaryBlue, // Base background is now Ocean Blue
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: accentOchre,
      surface: const Color(0xFF0F2B3D), // Slightly lighter blue for surfaces
      onPrimary: Colors.white,
      onSurface: Colors.white,
      error: warningOrange,
    ),
    // Premium Typography
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      bodyLarge: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
      displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 32),
      displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 18),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentOchre, // Buttons pop with Gold
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        shadowColor: accentOchre.withValues(alpha: 0.3),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      color: Colors.white.withValues(alpha: 0.05), // Glassy cards
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryBlue,
      selectedItemColor: accentOchre,
      unselectedItemColor: Colors.white54,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF020810), // Ultra-deep space
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: primaryBlue,
      secondary: accentOchre,
      surface: const Color(0xFF030C16),
      onSurface: Colors.white,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.9)),
      bodyMedium: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8)),
      displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
      ),
      color: Colors.white.withValues(alpha: 0.03),
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
