import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/trip_cache_service.dart';
import 'data/datasources/user_preference_service.dart';
import 'data/datasources/monetization_service.dart';
import 'data/datasources/premium_service.dart';
import 'data/datasources/voice_service.dart';
import 'core/analytics/analytics_service.dart';
import 'core/notifications/notification_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Essential Local Storage (Hive) first
  try {
    await TripCacheService.init();
    await UserPreferenceService.init();
  } catch (e) {
    debugPrint("Critical Init Error (Local DB): $e");
  }

  // 2. Initialize Firebase (Wait up to 8 seconds)
  // This is required before accessing FirebaseAuth or Firestore.
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint("Firebase Core Init Error: $e");
  }

  // 3. Fire and Forget non-blocking services AFTER running the app
  _initializeOtherServices();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumService()..init()),
      ],
      child: const AdvanceTravelApp(),
    ),
  );
}

void _initializeOtherServices() {
  // These don't need to block UI rendering
  MobileAds.instance.initialize().catchError((e) => debugPrint("Ads Init Error: $e"));
  NotificationService().init().catchError((e) => debugPrint("Notify Init Error: $e"));
  AnalyticsService().logEvent('app_opened').catchError((e) => null);
  
  // Ads & Voice Pre-load
  MonetizationService().loadInterstitialAd();
  MonetizationService().loadRewardedAd();
  VoiceService().init().catchError((e) => debugPrint("Voice Init Error: $e"));

  // Global Error Boundary
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    try {
      AnalyticsService().logEvent('runtime_error', parameters: {
        'exception': details.exceptionAsString(),
      });
    } catch (_) {}
  };
}

class AdvanceTravelApp extends StatelessWidget {
  const AdvanceTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripMe.ai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _buildHomeModule(),
    );
  }

  Widget _buildHomeModule() {
    // Basic check: If Firebase is not initialized, FirebaseAuth.instance might fail.
    // However, most plugins now handle this better or throw specific errors.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              color: AppTheme.silkPearl,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Connection Error: ${snapshot.error}"),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
