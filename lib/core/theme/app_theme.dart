import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  // --- Modern & Eco (The "Zen" Light Palette) ---
  static const Color zenGreen = Color(0xFF2E7D32);
  static const Color zenBlue = Color(0xFF1976D2);
  static const Color zenSurface = Color(0xFFFCFDFF);
  static const Color zenCard = Color(0xFFFFFFFF);
  static const Color zenTextPrimary = Color(0xFF0F172A);
  static const Color zenTextSecondary = Color(0xFF64748B);
  static const Color zenBorder = Color(0xFFE2E8F0);

  // --- Deep Night (The "Figma" Dark Palette) ---
  static const Color nightScaffold = Color(0xFF0A0D11); // Deep Charcoal
  static const Color nightSurface = Color(0xFF141A21);  // Slightly lighter
  static const Color nightCard = Color(0xFF141A21);     
  static const Color nightAccentGold = Color(0xFFC19A6B); // Gold
  static const Color nightAccentGreen = Color(0xFF10B981); // Emerald
  static const Color nightTextPrimary = Color(0xFFFFFFFF); 
  static const Color nightTextSecondary = Color(0x99FFFFFF); // 60% White
  static const Color nightBorder = Color(0x1AFFFFFF);    // 10% White

  // --- Legacy & Brand Anchors ---
  static const Color ceylonBlue = Color(0xFF003B5C);
  static const Color sigiriyaOchre = Color(0xFFC19A6B);
  static const Color modernBlue = Color(0xFF1976D2);
  static const Color modernGreen = Color(0xFF2E7D32);

  // --- Semantic (Dynamic/Contextual) ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}

class AppTheme {
  // --- Standard Static Constants (For Backward Compatibility) ---
  static const Color modernGreen = AppPalette.nightAccentGreen;
  static const Color modernBlue = AppPalette.nightAccentGold;
  static const Color ceylonBlue = AppPalette.nightScaffold;
  static const Color sigiriyaOchre = AppPalette.nightAccentGold;
  static const Color accentOchre = AppPalette.nightAccentGold;
  
  // Missing Aliases found in audit
  static const Color primaryBlue = AppPalette.ceylonBlue;
  static const Color darkText = AppPalette.zenTextPrimary;
  static const Color deepSlate = AppPalette.nightScaffold;
  static const Color softSlate = AppPalette.nightSurface;
  static const Color pureWhite = AppPalette.zenCard;
  
  // Dark mode surfaces for compatibility
  static const Color darkSurface = AppPalette.nightSurface;
  static const Color darkCard = AppPalette.nightCard;
  static const Color darkBorder = AppPalette.nightBorder;
  static const Color silkPearl = AppPalette.zenSurface;
  static const Color textSecondary = AppPalette.zenTextSecondary;
  
  // Semantic Aliases
  static const Color successGreen = AppPalette.success;
  static const Color warningAmber = AppPalette.warning;
  static const Color errorRed = AppPalette.error;

  // --- Luxury Shadows ---
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // --- Premium Gradients ---
  static const LinearGradient modernGradient = LinearGradient(
    colors: [AppPalette.nightAccentGold, AppPalette.nightAccentGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient oceanGradient = LinearGradient(
    colors: [AppPalette.ceylonBlue, Color(0xFF002844)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// The ONE background all screens should use — deep navy to near-black
  static const LinearGradient appBackground = LinearGradient(
    colors: [Color(0xFF0A0D11), Color(0xFF080A0E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Glassmorphism Optimized ---
  /// Creates a premium glassmorphic effect that adapts to theme brightness.
  static BoxDecoration glassDecoration({
    double opacity = 0.05, 
    double blur = 30,
    BorderRadius? radius,
    Color? color,
    BoxShape shape = BoxShape.rectangle,
    bool isDark = false,
  }) {
    final bgColor = isDark 
        ? (color ?? AppPalette.nightCard)
        : (color ?? Colors.white);
        
    return BoxDecoration(
      color: bgColor.withOpacity(opacity),
      borderRadius: shape == BoxShape.circle ? null : (radius ?? BorderRadius.circular(20)),
      shape: shape,
      border: Border.all(
        color: Colors.white.withOpacity(isDark ? 0.05 : 0.2),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
          blurRadius: 30, // matches blur
          spreadRadius: -5,
          offset: const Offset(0, 8),
        )
      ],
    );
  }

  // --- Dynamic Time-Aware Overlay ---
  static Color getDynamicOverlay() {
    final hour = DateTime.now().hour;
    return (hour >= 18 || hour < 6) ? Colors.black.withOpacity(0.2) : Colors.transparent;
  }

  // --- Advanced Text Styles ---
  static TextStyle get oracleBrandHeading => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppPalette.nightAccentGold,
    letterSpacing: 1.5,
  );

  static TextStyle get budgetEmphasis => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppPalette.sigiriyaOchre,
    letterSpacing: 1,
  );

  /// Consistent label style (section headers, tags)
  static TextStyle labelStyle(BuildContext context) => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
  );

  /// Consistent body text style
  static TextStyle bodyStyle(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
  );

  /// Ochre-accented left-border for cards
  static BoxDecoration ochreCardDecoration({
    double borderRadius = 16,
    double opacity = 0.06,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border(
        left: BorderSide(color: AppPalette.sigiriyaOchre, width: 3),
        top: const BorderSide(color: Colors.white10),
        right: const BorderSide(color: Colors.white10),
        bottom: const BorderSide(color: Colors.white10),
      ),
    );
  }

  // --- ThemeData: Zen Light ---
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppPalette.zenGreen,
    scaffoldBackgroundColor: AppPalette.zenSurface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.zenGreen,
      primary: AppPalette.zenGreen,
      secondary: AppPalette.zenBlue,
      surface: AppPalette.zenCard,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppPalette.zenTextPrimary,
      error: AppPalette.error,
    ),
    textTheme: GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppPalette.zenTextPrimary),
      displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: AppPalette.zenTextPrimary),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppPalette.zenTextPrimary),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.zenTextPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppPalette.zenTextPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppPalette.zenTextSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppPalette.zenGreen),
      iconTheme: const IconThemeData(color: AppPalette.zenGreen),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.zenGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.zenCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppPalette.zenBorder, width: 1),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppPalette.zenGreen,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppPalette.zenGreen.withOpacity(0.15),
      labelStyle: GoogleFonts.inter(fontSize: 12),
    ),
  );

  // --- ThemeData: Sigiriya Night (Premium Dark) ---
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppPalette.nightAccentGold,
    scaffoldBackgroundColor: AppPalette.nightScaffold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.nightAccentGold,
      brightness: Brightness.dark,
      primary: AppPalette.nightAccentGold,
      secondary: AppPalette.nightAccentGreen,
      surface: AppPalette.nightSurface,
      onPrimary: AppPalette.nightScaffold,
      onSecondary: AppPalette.nightScaffold,
      onSurface: AppPalette.nightTextPrimary,
      error: AppPalette.error,
    ),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppPalette.nightTextPrimary),
      displayMedium: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w700, color: AppPalette.nightTextPrimary),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppPalette.nightTextPrimary),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppPalette.nightTextPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppPalette.nightTextPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppPalette.nightTextSecondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppPalette.nightTextPrimary),
      iconTheme: IconThemeData(color: AppPalette.nightTextPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppPalette.nightAccentGold,
        foregroundColor: AppPalette.nightScaffold,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppPalette.nightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppPalette.nightBorder, width: 1),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppPalette.nightAccentGreen,
      foregroundColor: AppPalette.nightScaffold,
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppPalette.nightAccentGold.withOpacity(0.2),
      labelStyle: GoogleFonts.inter(fontSize: 12, color: AppPalette.nightTextPrimary),
    ),
  );

  static ButtonStyle primaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppPalette.ceylonBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
    );
  }
}


