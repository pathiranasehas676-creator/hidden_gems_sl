import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform, File;
import 'core/theme/app_theme.dart';
import 'core/localization/locale_provider.dart';
import 'data/datasources/trip_cache_service.dart';
import 'data/datasources/user_preference_service.dart';
import 'data/datasources/monetization_service.dart';
import 'data/datasources/premium_service.dart';
import 'data/datasources/voice_service.dart';
import 'core/analytics/analytics_service.dart';
import 'core/notifications/notification_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/language_selection_screen.dart';
import 'presentation/widgets/graceful_error_widget.dart';
import 'firebase_options.dart';

class InitializationResult {
  final bool hiveSuccess;
  final bool firebaseSuccess;
  final String? error;

  InitializationResult({
    required this.hiveSuccess,
    required this.firebaseSuccess,
    this.error,
  });

  bool get canProceed => hiveSuccess;
}

Future<InitializationResult> performInitialization() async {
  bool hiveStatus = false;
  bool firebaseStatus = false;
  String? errorMessage;

  try {
    // 1. Initialize Essential Local Storage (Hive) - MANDATORY
    await TripCacheService.init();
    await UserPreferenceService.init();
    hiveStatus = true;
  } catch (e) {
    debugPrint("Critical Local Init Error: $e");
    errorMessage = "Local database failure: $e";
  }

  if (hiveStatus) {
    // Helpful Debug Check for Firebase Config
    if (Platform.isAndroid) {
      final configExists = await File('android/app/google-services.json').exists().catchError((_) => false);
      if (!configExists) {
        debugPrint("CRITICAL WARNING: android/app/google-services.json is MISSING. Firebase will not initialize.");
      }
    }

    try {
      // 2. Initialize Firebase (Optional/Timeout)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
      firebaseStatus = true;
    } catch (e) {
      debugPrint("Firebase optional init error: $e");
      // Not fatal if Hive is ready
    }
  }

  return InitializationResult(
    hiveSuccess: hiveStatus,
    firebaseSuccess: firebaseStatus,
    error: errorMessage,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final initResult = await performInitialization();

  if (initResult.firebaseSuccess) {
    _initializeOtherServices();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumService()..init()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: AdvanceTravelApp(initResult: initResult),
    ),
  );
}

void _initializeOtherServices() {
  // These don't need to block UI rendering
  try {
    MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("Ads Init Error: $e");
  }

  try {
    NotificationService().init();
  } catch (e) {
    debugPrint("Notify Init Error: $e");
  }

  try {
    AnalyticsService().logEvent('app_opened');
  } catch (_) {}
  
  // Ads & Voice Pre-load
  MonetizationService().loadInterstitialAd();
  MonetizationService().loadRewardedAd();
  
  try {
    VoiceService().init();
  } catch (e) {
    debugPrint("Voice Init Error: $e");
  }

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
      _currentInitResult = InitializationResult(
        hiveSuccess: true, 
        firebaseSuccess: true,
      ); 
    });
    
    final result = await performInitialization();
    
    if (result.firebaseSuccess) {
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
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('si'),
        Locale('ta'),
        Locale('ja'),
        Locale('ru'),
        Locale('ko'),
      ],
      locale: context.watch<LocaleProvider>().locale,
      home: _buildHomeModule(),
    );
  }

  Widget _buildHomeModule() {
    if (!_currentInitResult.canProceed) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlue,
        body: GracefulErrorWidget(
          onRetry: _retryInit,
          errorMessage: "Critical storage error. The Oracle cannot start.",
        ),
      );
    }

    final profile = UserPreferenceService.getProfile();
    if (profile.languageCode == null) {
      return const LanguageSelectionScreen();
    }

    // If Hive is ready but Firebase failed, go to Home in Offline Mode
    if (!_currentInitResult.firebaseSuccess) {
      return const HomeScreen(isOffline: true);
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
