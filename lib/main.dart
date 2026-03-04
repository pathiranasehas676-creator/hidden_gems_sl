import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'dart:io' show HttpOverrides;
import 'core/theme/app_theme.dart';
import 'core/localization/locale_provider.dart';
import 'data/datasources/trip_cache_service.dart';
import 'data/datasources/user_preference_service.dart';
import 'data/datasources/monetization_service.dart';
import 'data/datasources/premium_service.dart';
import 'data/datasources/voice_service.dart';
import 'core/analytics/analytics_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/network/secure_network.dart';
import 'core/utils/secure_logger.dart';
import 'package:safe_device/safe_device.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/language_selection_screen.dart';
import 'presentation/widgets/graceful_error_widget.dart';
import 'firebase_options.dart';

class InitializationResult {
  final bool hiveSuccess;
  final bool firebaseSuccess;
  final bool isCompromised;
  final String? error;

  InitializationResult({
    required this.hiveSuccess,
    required this.firebaseSuccess,
    this.isCompromised = false,
    this.error,
  });

  bool get canProceed => hiveSuccess && !isCompromised;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint("Main Entry: Initializing core storage...");
  
  // 1. Initialize Essential Local Storage (Hive) - MUST be first
  try {
    await TripCacheService.init();
    await UserPreferenceService.init();
    debugPrint("Core storage ready.");
  } catch (e) {
    debugPrint("CRITICAL Hive Init Error: $e");
  }

  // Apply Strict HTTPS Security and SSL Pinning configuration globally
  HttpOverrides.global = SecureNetworkOverrides();

  // FLAG_SECURE is now handled directly in android/app/src/main/kotlin/com/hidden/gems/hidden_gems_sl/MainActivity.kt
  // for better compatibility and build reliability.

  // Kick off the rest of initialization in background — SplashScreen will wait for it.
  final initFuture = performInitialization();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumService()..init()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: TripMeApp(initFuture: initFuture),
    ),
  );
}

Future<InitializationResult> performInitialization() async {
  bool firebaseStatus = false;
  bool isCompromised = false;
  String? errorMessage;

  debugPrint("Background initialization started. Web mode: $kIsWeb");

  try {
    if (!kIsWeb) {
      bool jailbroken = await SafeDevice.isJailBroken;
      if (jailbroken) {
        isCompromised = true;
        errorMessage = "Compromised device detected. The Oracle cannot run in this environment.";
      }
    }
  } catch (e) {
    debugPrint("Jailbreak detection error: $e");
  }

  if (isCompromised) {
    return InitializationResult(
      hiveSuccess: true, // Hive was already opened in main
      firebaseSuccess: false,
      isCompromised: true,
      error: errorMessage,
    );
  }

  try {
    debugPrint("Initializing Firebase...");
    FirebaseOptions? options;
    try {
      options = DefaultFirebaseOptions.currentPlatform;
    } catch (e) {
      debugPrint("Firebase config not available for this platform: $e");
    }

    if (options != null) {
      await Firebase.initializeApp(
        options: options,
      ).timeout(const Duration(seconds: 15));
      firebaseStatus = true;
      debugPrint("Firebase initialized successfully.");
    } else {
      debugPrint("Skipping Firebase initialization due to missing config.");
    }
  } catch (e) {
    debugPrint("Firebase optional init error: $e");
  }

  debugPrint("Background initialization complete. Firebase: $firebaseStatus");
  return InitializationResult(
    hiveSuccess: true, // Core Hive is pre-initialized in main
    firebaseSuccess: firebaseStatus,
    isCompromised: isCompromised,
    error: errorMessage,
  );
}

void initializeOtherServices() {
  // These don't need to block UI rendering
  try {
    MobileAds.instance.initialize();
  } catch (e) {
    SecureLogger.error("Ads Init Error: $e");
  }

  try {
    NotificationService().init();
  } catch (e) {
    SecureLogger.error("Notify Init Error: $e");
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

// The thin root MaterialApp — just theming + localization, routes to Splash
class TripMeApp extends StatelessWidget {
  final Future<InitializationResult> initFuture;
  const TripMeApp({super.key, required this.initFuture});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripMe.ai',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
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
      home: SplashScreen(initFuture: initFuture),
    );
  }
}

// Keep AdvanceTravelApp for the post-splash routing logic
class AdvanceTravelApp extends StatefulWidget {
  final InitializationResult initResult;
  const AdvanceTravelApp({super.key, required this.initResult});

  @override
  State<AdvanceTravelApp> createState() => _AdvanceTravelAppState();
}

class _AdvanceTravelAppState extends State<AdvanceTravelApp> with WidgetsBindingObserver {
  late InitializationResult _currentInitResult;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _isSplashShowing = false;

  @override
  void initState() {
    super.initState();
    _currentInitResult = widget.initResult;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isSplashShowing) {
      _showSplashScreen();
    }
  }

  void _showSplashScreen() {
    if (navigatorKey.currentState == null) return;
    _isSplashShowing = true;
    navigatorKey.currentState!.push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => SplashScreen(
          initFuture: Future.value(_currentInitResult),
          isResume: true,
        ),
      ),
    ).then((_) {
      _isSplashShowing = false;
    });
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
      initializeOtherServices();
    }
    
    setState(() {
      _currentInitResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
          errorMessage: _currentInitResult.error ?? "Critical storage error. The Oracle cannot start.",
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
