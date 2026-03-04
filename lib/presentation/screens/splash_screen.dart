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
    // Restore system UI when leaving splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                
                // Dark Gradient Overlays for Cinematic Feel
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                      stops: const [0.0, 0.2, 0.7, 1.0],
                    ),
                  ),
                ),

                // Cinematic Overlay Text
                Positioned(
                  bottom: 100,
                  left: 32,
                  right: 32,
                  child: FadeInText(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // Centered for more impact
                      children: [
                        Text(
                          "ශ්‍රී ලංකා",
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 72, 
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: AppTheme.accentOchre.withOpacity(0.5),
                                blurRadius: 40,
                                offset: const Offset(0, 0),
                              )
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, AppTheme.accentOchre, Colors.transparent],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "සැඟවුණු සුන්දরත්වය සොයා යන්න",
                          style: GoogleFonts.notoSansSinhala(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 60),
                        // Loading Progress Indicator
                        ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (context, VideoPlayerValue value, child) {
                            final progress = value.isInitialized
                                ? value.position.inMilliseconds / value.duration.inMilliseconds
                                : 0.0;
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: SizedBox(
                                width: 200,
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentOchre),
                                  minHeight: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Container(
              decoration: const BoxDecoration(gradient: AppTheme.oceanGradient),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.accentOchre),
                    SizedBox(height: 24),
                    Text(
                      "PREPARING YOUR JOURNEY...",
                      style: TextStyle(
                        color: Colors.white70,
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