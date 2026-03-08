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

  // --- Deep Night (The "Sigiriya" Dark Palette) ---
  static const Color nightScaffold = Color(0xFF0F172A); // Near black navy
  static const Color nightSurface = Color(0xFF1E293B);  // Slate 800
  static const Color nightCard = Color(0xFF1E293B);     // Consistent surface
  static const Color nightAccentBlue = Color(0xFF38BDF8); // Sky 400
  static const Color nightAccentGreen = Color(0xFF34D399); // Emerald 400
  static const Color nightTextPrimary = Color(0xFFF1F5F9); // Slate 100
  static const Color nightTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color nightBorder = Color(0xFF334155);    // Slate 700

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
  static const Color modernGreen = AppPalette.modernGreen;
  static const Color modernBlue = AppPalette.modernBlue;
  static const Color ceylonBlue = AppPalette.ceylonBlue;
  static const Color sigiriyaOchre = AppPalette.sigiriyaOchre;
  static const Color accentOchre = AppPalette.sigiriyaOchre;
  
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
    colors: [AppPalette.modernGreen, AppPalette.modernBlue],
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
    colors: [Color(0xFF002035), Color(0xFF0D1117)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Glassmorphism Optimized ---
  /// Creates a premium glassmorphic effect that adapts to theme brightness.
  static BoxDecoration glassDecoration({
    double opacity = 0.12, 
    double blur = 25,
    BorderRadius? radius,
    Color? color,
    BoxShape shape = BoxShape.rectangle,
    bool isDark = false,
  }) {
    final bgColor = isDark 
        ? AppPalette.nightSurface.withValues(alpha: 0.6) 
        : (color ?? Colors.white.withValues(alpha: 0.4));
        
    return BoxDecoration(
      color: bgColor.withValues(alpha: opacity),
      borderRadius: shape == BoxShape.circle ? null : (radius ?? BorderRadius.circular(20)),
      shape: shape,
      border: Border.all(
        color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
          blurRadius: 15,
          spreadRadius: -2,
          offset: const Offset(0, 4),
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
  static TextStyle get budgetEmphasis => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppPalette.sigiriyaOchre,
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
      shadowColor: Colors.black.withValues(alpha: 0.05),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppPalette.zenGreen,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppPalette.zenGreen.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(fontSize: 12),
    ),
  );

  // --- ThemeData: Sigiriya Night (Premium Dark) ---
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppPalette.nightAccentBlue,
    scaffoldBackgroundColor: AppPalette.nightScaffold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.nightAccentBlue,
      brightness: Brightness.dark,
      primary: AppPalette.nightAccentBlue,
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
        backgroundColor: AppPalette.nightAccentBlue,
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
      selectedColor: AppPalette.nightAccentBlue.withValues(alpha: 0.2),
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


