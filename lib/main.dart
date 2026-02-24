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
  
  // Initialize Services
  await TripCacheService.init();
  await UserPreferenceService.init();
  
  // Initialize Firebase, Ads, Analytics, Notifications
  try {
    await Firebase.initializeApp();
    await MobileAds.instance.initialize();
    await NotificationService().init();
    await AnalyticsService().logEvent('app_opened');
  } catch (e) {
    debugPrint("Firebase/Init failed: $e. Non-fatal but features restricted.");
  }

  // Pre-load ads & Voice
  MonetizationService().loadInterstitialAd();
  MonetizationService().loadRewardedAd();
  await VoiceService().init();

  // Global Error Boundary
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AnalyticsService().logEvent('runtime_error', parameters: {
      'exception': details.exceptionAsString(),
    });
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumService()..init()),
      ],
      child: const AdvanceTravelApp(),
    ),
  );
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
