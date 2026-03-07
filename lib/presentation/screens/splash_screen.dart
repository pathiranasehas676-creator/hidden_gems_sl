import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../core/theme/app_theme.dart';
class SplashScreen extends StatefulWidget {
  final Future<InitializationResult>? initFuture;
  final bool isResume;

  const SplashScreen({
    super.key,
    this.initFuture,
    this.isResume = false,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // Cinematic Full Screen (Hiding status bar and nav bar)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Hide Global Screenshot button while on splash
    GlobalScreenshotWrapper.setVisible(false);

    _controller = VideoPlayerController.asset("assets/videos/splash.mp4")
      ..initialize().then((_) {
        if (mounted) setState(() {});
        _controller.play();
      });

    _controller.setLooping(false);

    _controller.addListener(() {
      // Check if video is finished
      if (!_isNavigating && 
          _controller.value.isInitialized && 
          _controller.value.position >= _controller.value.duration) {
        _handleNavigation();
      }
    });
  }

  Future<void> _handleNavigation() async {
    _isNavigating = true; 
    
    InitializationResult? result;
    if (widget.initFuture != null) {
        result = await widget.initFuture;
    }

    if (!mounted) return;

    if (widget.isResume) {
      Navigator.of(context).pop();
    } else {
      if (result != null) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AdvanceTravelApp(initResult: result!),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Restore system UI and global UI elements
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    GlobalScreenshotWrapper.setVisible(true);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _controller.value.isInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Background Video
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
                
                // Subtle Overlay for White Theme
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.2),
                      ],
                      stops: const [0.0, 0.2, 0.7, 1.0],
                    ),
                  ),
                ),
                // Bottom Loading UI
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Premium Progress Indicator
                      ValueListenableBuilder(
                        valueListenable: _controller,
                          builder: (context, VideoPlayerValue value, child) {
                            final progress = value.isInitialized
                                ? value.position.inMilliseconds / value.duration.inMilliseconds
                                : 0.0;
                            return Container(
                              width: 280,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: Stack(
                                  children: [
                                    // Animated Progress
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 280 * progress,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        gradient: AppTheme.modernGradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.modernGreen.withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            spreadRadius: 1,
                                          )
                                        ],
                                      ),
                                    ),
                                    // Glint Effect Tracking
                                    Positioned(
                                      left: (280 * progress) - 60,
                                      child: Container(
                                        width: 120,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withValues(alpha: 0.3),
                                              Colors.white.withValues(alpha: 0.7),
                                              Colors.white.withValues(alpha: 0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "ESTABLISHING SECURE CONNECTION...",
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.modernGreen.withValues(alpha: 0.5),
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
    : Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.modernGreen),
                    SizedBox(height: 24),
                    Text(
                      "PREPARING YOUR JOURNEY...",
                      style: TextStyle(
                        color: AppTheme.modernGreen,
                        letterSpacing: 4,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class FadeInText extends StatefulWidget {
  final Widget child;
  const FadeInText({super.key, required this.child});

  @override
  State<FadeInText> createState() => _FadeInTextState();
}

class _FadeInTextState extends State<FadeInText> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}