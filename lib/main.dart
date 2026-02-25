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
import 'presentation/widgets/graceful_error_widget.dart';

class InitializationResult {
  final bool success;
  final String? error;
  InitializationResult({required this.success, this.error});
}

Future<InitializationResult> performInitialization() async {
  try {
    // 1. Initialize Essential Local Storage (Hive) first
    await TripCacheService.init();
    await UserPreferenceService.init();

    // 2. Initialize Firebase (Increased timeout to 15 seconds)
    await Firebase.initializeApp().timeout(const Duration(seconds: 15));

    return InitializationResult(success: true);
  } catch (e) {
    debugPrint("Critical Init Error: $e");
    return InitializationResult(success: false, error: e.toString());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final initResult = await performInitialization();

  if (initResult.success) {
    _initializeOtherServices();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumService()..init()),
      ],
      child: AdvanceTravelApp(initResult: initResult),
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

class AdvanceTravelApp extends StatefulWidget {
  final InitializationResult initResult;
  const AdvanceTravelApp({super.key, required this.initResult});

  @override
  State<AdvanceTravelApp> createState() => _AdvanceTravelAppState();
}

class _AdvanceTravelAppState extends State<AdvanceTravelApp> {
  late InitializationResult _currentInitResult;

  @override
  void initState() {
    super.initState();
    _currentInitResult = widget.initResult;
  }

  Future<void> _retryInit() async {
    setState(() {
      // Temporary state to show loader during retry
      _currentInitResult = InitializationResult(success: true); 
    });
    
    final result = await performInitialization();
    
    if (result.success) {
      _initializeOtherServices();
    }
    
    setState(() {
      _currentInitResult = result;
    });
  }

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
    if (!_currentInitResult.success) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlue,
        body: GracefulErrorWidget(
          onRetry: _retryInit,
          errorMessage: "Unable to connect to the travel Oracle. Please check your internet and try again.",
        ),
      );
    }

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
