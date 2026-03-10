import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'dart:io';
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
import 'core/config/remote_config_service.dart';
import 'core/providers/app_mode_provider.dart';
import 'core/providers/screenshot_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'core/utils/screenshot_service.dart';
import 'presentation/widgets/golden_tracer_indicator.dart';

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

// SecureNetwork from core/network/secure_network.dart is used instead.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint("Main Entry: Initializing core storage...");
  
  // 1. Initialize Essential Local Storage (Hive) - MUST be first
  try {
    await TripCacheService.init();
    await UserPreferenceService.init();
    await UserPreferenceService.ensureProfileLoaded();
    debugPrint("Core storage ready.");
  } catch (e) {
    debugPrint("CRITICAL Hive Init Error: $e");
  }

  // Apply Strict HTTPS Security and SSL Pinning configuration globally
  if (!kIsWeb) {
    HttpOverrides.global = SecureNetworkOverrides();
  }

  // FLAG_SECURE is now handled directly in android/app/src/main/kotlin/com/hidden/gems/hidden_gems_sl/MainActivity.kt
  // for better compatibility and build reliability.

  // Kick off the rest of initialization in background — SplashScreen will wait for it.
  final initFuture = performInitialization();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PremiumService()..init()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AppModeProvider()),
        ChangeNotifierProvider(create: (_) => ScreenshotProvider()),
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
    if (firebaseStatus) {
      final remoteConfig = await RemoteConfigService.getInstance();
      await remoteConfig.initialize();
      debugPrint("Remote Config initialized.");
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
class TripMeApp extends StatefulWidget {
  final Future<InitializationResult> initFuture;
  const TripMeApp({super.key, required this.initFuture});

  @override
  State<TripMeApp> createState() => _TripMeAppState();
}

class _TripMeAppState extends State<TripMeApp> with WidgetsBindingObserver {
  late InitializationResult _currentInitResult = InitializationResult(hiveSuccess: false, firebaseSuccess: false);
  bool _isInitDone = false;
  bool _showMainApp = false;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _startInitialization();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _startInitialization() async {
    final result = await widget.initFuture;
    if (result.firebaseSuccess) {
      initializeOtherServices();
    }
    setState(() {
      _currentInitResult = result;
      _isInitDone = true;
    });
  }

  Future<void> _retryInit() async {
    setState(() => _isInitDone = false);
    final result = await performInitialization();
    if (result.firebaseSuccess) {
      initializeOtherServices();
    }
    setState(() {
      _currentInitResult = result;
      _isInitDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'TripMe.ai',
      debugShowCheckedModeBanner: false,
      themeMode: context.watch<AppModeProvider>().currentMode,
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
      home: _showMainApp && _isInitDone
          ? _buildHomeModule()
          : SplashScreen(
              initFuture: widget.initFuture,
              onComplete: (result) {
                setState(() {
                  _currentInitResult = result;
                  _isInitDone = true;
                  _showMainApp = true;
                });
              },
            ),
      builder: (context, child) => GlobalScreenshotWrapper(child: child!),
    );
  }

  Widget _buildHomeModule() {
    if (!_currentInitResult.canProceed) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBlue,
        body: GracefulErrorWidget(
          icon: Icons.storage_rounded,
          title: "Oracle Cannot Start",
          subtitle: _currentInitResult.error ?? "Critical storage error. The Oracle cannot start.",
          buttonLabel: "Retry",
          onRetry: _retryInit,
        ),
      );
    }

    final profile = UserPreferenceService.getProfile();
    if (profile.languageCode == null) {
      return const LanguageSelectionScreen();
    }

    if (!_currentInitResult.firebaseSuccess) {
      return const HomeScreen(isOffline: true);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.primaryBlue,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ModernTracerIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "ORACLE IS THINKING...",
                    style: GoogleFonts.inter(
                      color: AppTheme.modernGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Connection Error: ${snapshot.error}")),
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


class GlobalScreenshotWrapper extends StatefulWidget {
  final Widget child;
  const GlobalScreenshotWrapper({super.key, required this.child});

  @override
  State<GlobalScreenshotWrapper> createState() => _GlobalScreenshotWrapperState();
}

class _GlobalScreenshotWrapperState extends State<GlobalScreenshotWrapper> with SingleTickerProviderStateMixin {
  final ScreenshotService _screenshotService = ScreenshotService();
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _handleCapture() async {
    HapticFeedback.heavyImpact();
    // Trigger Flash
    _flashController.forward(from: 0.0);
    await _screenshotService.captureAndShare(context);
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = context.watch<ScreenshotProvider>().isVisible;

    return Screenshot(
      controller: _screenshotService.controller,
      child: Stack(
        children: [
          widget.child,
          if (isVisible)
            Positioned(
              right: 16,
              bottom: 110,
              child: SafeArea(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleCapture,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: AppTheme.glassDecoration(
                          opacity: 0.2, 
                          blur: 30,
                          shape: BoxShape.circle,
                        ).copyWith(
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.5), 
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Flash Effect Overlay
          AnimatedBuilder(
            animation: _flashController,
            builder: (context, child) {
              if (_flashController.value == 0) return const SizedBox.shrink();
              return IgnorePointer(
                child: Opacity(
                  opacity: _flashController.value < 0.5 
                      ? _flashController.value * 2 
                      : (1.0 - _flashController.value) * 2,
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
