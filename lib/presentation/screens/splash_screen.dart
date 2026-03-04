import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  final Future<InitializationResult> initFuture;
  const SplashScreen({super.key, required this.initFuture});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 1. Cinematic Master Sequence (0.0s - 5.0s)
  late Animation<double> _islandReveal;
  late Animation<double> _motionActivation;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Fade in
    _islandReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.1, curve: Curves.easeIn),
      ),
    );

    // Motion layers blend in
    _motionActivation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.4, curve: Curves.linear),
      ),
    );

    // Fade out
    _fadeOut = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.9, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    try {
      final result = await widget.initFuture;
      await Future.delayed(const Duration(milliseconds: 5000));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AdvanceTravelApp(initResult: result),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    } catch (e) {
      debugPrint("Splash Error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Opacity(
            opacity: (_islandReveal.value - _fadeOut.value).clamp(0.0, 1.0),
            child: Container(
              color: const Color(0xFF1E3A8A), // Blue-900 background
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated background shimmer layer (Pulse)
                  _buildPulseBackground(progress),

                  // Background Clouds
                  _buildClouds(progress),

                  // Main Island Image + Cinematic Zoom
                  Transform.scale(
                    scale: 1.15 - (0.15 * progress), // 1.15 -> 1.0 cinematic zoom mapping
                    child: Transform.translate(
                      offset: Offset(-8 + (8 * progress), 0),
                      child: Image.asset(
                        'assets/images/splash_from_git.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Water shimmer and deep overlay
                  Opacity(
                    opacity: 0.8 * _motionActivation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            const Color(0xFF67E8F9).withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // All Dynamic Painters (Waves, Turtles, Boats, Sunflare, Sparkles)
                  Opacity(
                    opacity: _motionActivation.value,
                    child: CustomPaint(
                      painter: ReactUiTranslationPainter(progress: progress),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPulseBackground(double p) {
    // Similar to animate-pulse over bg-gradient-to-br from-sky-200/20 via-transparent to-blue-900/20
    double pulse = 0.5 + 0.5 * math.sin(p * math.pi * 8); 
    return Opacity(
      opacity: pulse,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFBAE6FD).withValues(alpha: 0.2), // Sky-200
              Colors.transparent,
              const Color(0xFF1E3A8A).withValues(alpha: 0.2), // Blue-900
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClouds(double p) {
    return Stack(
      children: [
        _buildSingleCloud(
            top: 0.05, left: -0.1, w: 288, h: 144, delay: 0, dur: 20, p: p),
        _buildSingleCloud(
            top: 0.15, right: -0.15, w: 256, h: 128, delay: 3, dur: 25, p: p),
        _buildSingleCloud(
            top: 0.30, left: 0.1, w: 224, h: 112, delay: 6, dur: 22, p: p),
        _buildSingleCloud(
            top: 0.50, right: 0.05, w: 192, h: 96, delay: 9, dur: 28, p: p),
      ],
    );
  }

  Widget _buildSingleCloud({
    double? top,
    double? left,
    double? right,
    required double w,
    required double h,
    required double delay,
    required double dur,
    required double p,
  }) {
    // Simulated keyframe drift logic converting real-world seconds
    // Since our app lives for 5s, we approximate the cloud loop linearly.
    double time = (p * 5) + delay;
    double loopProgress = (time / dur) % 1.0;
    
    // Simplistic translation mimicking CSS exactly:
    // 0%: 0, 50%: 30px, 100%: 60px -> Just a linear progression over dur
    // Actually the CSS was 0->30px->60px, so it's constantly translating.
    double transX = 60 * loopProgress; 
    double transY = 15 * math.sin(loopProgress * math.pi * 2);

    return Positioned(
      top: top != null ? MediaQuery.of(context).size.height * top + transY : null,
      left: left != null ? MediaQuery.of(context).size.width * left + transX : null,
      right: right != null ? MediaQuery.of(context).size.width * right - transX : null,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(200),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.6),
              blurRadius: 40,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class ReactUiTranslationPainter extends CustomPainter {
  final double progress;
  ReactUiTranslationPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    _drawOceanWaves(canvas, size);
    _drawTurtles(canvas, size);
    _drawBoats(canvas, size);
    _drawSunlares(canvas, size);
    _drawSparkles(canvas, size);
  }

  void _drawOceanWaves(Canvas canvas, Size size) {
    // 3 overlapping transparent gradients moving horizontally
    double h = size.height;
    double w = size.width;

    void drawWave(double heightOffset, Color color, double durationSec, double waveP) {
      double cycle = ((progress * 5) / durationSec) % 1.0;
      double dx = -w * cycle; // Translating left
      
      final rect = Rect.fromLTWH(dx, h - heightOffset, w * 2, heightOffset);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color, Colors.transparent],
        ).createShader(rect);
      
      // Draw first rect, then second rect to enforce tiling effect
      canvas.drawRect(Rect.fromLTWH(0, h - heightOffset, w, heightOffset), paint);
    }

    drawWave(96, const Color(0xFF60A5FA).withValues(alpha: 0.3), 8, progress); // Blue-400
    drawWave(80, const Color(0xFF67E8F9).withValues(alpha: 0.2), 6, progress); // Cyan-300
    drawWave(64, const Color(0xFF93C5FD).withValues(alpha: 0.15), 10, progress); // Blue-300
  }

  void _drawTurtles(Canvas canvas, Size size) {
    // Turtle 1
    double t1 = (progress * 5 / 25) % 1.0; 
    _drawSingleTurtle(canvas, size.width * 0.15 + (100 * t1), size.height * 0.65 - (10 * math.sin(t1 * math.pi)), 0.6, 0.9 + 0.1 * math.sin(t1));

    // Turtle 2
    double t2 = (progress * 5 / 30) % 1.0; 
    _drawSingleTurtle(canvas, size.width * 0.75 - (85 * t2), size.height * 0.58 + (8 * math.sin(t2 * math.pi)), 0.5, 0.85);

    // Turtle 3
    double t3 = (progress * 5 / 20) % 1.0; 
    _drawSingleTurtle(canvas, size.width * 0.60 + (55 * t3), size.height * 0.72 + (12 * math.sin(t3 * math.pi * 2)), 0.45, 0.88);
  }

  void _drawSingleTurtle(Canvas canvas, double cx, double cy, double baseOpac, double scale) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);

    final shellOutPaint = Paint()..color = const Color(0xFF2D5A3D).withValues(alpha: 0.8 * baseOpac);
    final shellInPaint = Paint()..color = const Color(0xFF3D7A4D).withValues(alpha: baseOpac);
    final flipperPaint = Paint()..color = const Color(0xFF2D5A3D).withValues(alpha: 0.7 * baseOpac);

    // Shell
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 16, height: 12), shellOutPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 10, height: 7), shellInPaint);
    
    // Flippers
    canvas.drawCircle(const Offset(-4, -2), 2, flipperPaint);
    canvas.drawCircle(const Offset(4, -2), 2, flipperPaint);
    canvas.drawCircle(const Offset(-4, 2), 2, flipperPaint);
    canvas.drawCircle(const Offset(4, 2), 2, flipperPaint);
    
    // Head
    canvas.drawCircle(const Offset(-2, -3), 1, Paint()..color = const Color(0xFF1A3D2A).withValues(alpha: baseOpac));

    canvas.restore();
  }

  void _drawBoats(Canvas canvas, Size size) {
    // Boat 1
    double b1 = (progress * 5 / 18) % 1.0;
    _drawSingleBoat(canvas, size.width * 0.20 + (50 * b1), size.height * 0.45 - (8 * math.sin(b1 * math.pi)), 0.7);

    // Boat 2
    double b2 = (progress * 5 / 22) % 1.0;
    _drawSingleBoat(canvas, size.width * 0.85 - (60 * b2), size.height * 0.52 + (10 * math.sin(b2 * math.pi)), 0.6);

    // Boat 3
    double b3 = (progress * 5 / 16) % 1.0;
    _drawSingleBoat(canvas, size.width * 0.70 + (40 * b3), size.height * 0.38 + (6 * math.sin(b3 * math.pi)), 0.5);
  }

  void _drawSingleBoat(Canvas canvas, double cx, double cy, double baseOpac) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(0.8);

    final hullPaint = Paint()..color = const Color(0xFF8B4513).withValues(alpha: baseOpac);
    final sailPaint = Paint()..color = Colors.white.withValues(alpha: 0.9 * baseOpac);
    final mastPaint = Paint()
      ..color = const Color(0xFF654321).withValues(alpha: baseOpac)
      ..strokeWidth = 1.0;

    // Hull (translated from SVG M8 20 L32 20 L30 28 L10 28 Z)
    Path hull = Path();
    hull.moveTo(-12, 0); hull.lineTo(12, 0); hull.lineTo(10, 8); hull.lineTo(-10, 8); hull.close();
    canvas.drawPath(hull, hullPaint);

    // Sail (M20 8 L20 20 L28 20 Z translated by center)
    Path sail = Path();
    sail.moveTo(0, -12); sail.lineTo(0, 0); sail.lineTo(8, 0); sail.close();
    canvas.drawPath(sail, sailPaint);

    // Mast
    canvas.drawLine(const Offset(0, -12), const Offset(0, 0), mastPaint);

    canvas.restore();
  }

  void _drawSunlares(Canvas canvas, Size size) {
    void drawFlare(double x, double y, double r, Color c, double pulseStrength, double baseOpac) {
      double dynamicOpac = baseOpac + pulseStrength * math.sin(progress * math.pi * 4);
      final rct = Rect.fromCircle(center: Offset(size.width * x, size.height * y), radius: r);
      final pnt = Paint()
        ..color = c.withValues(alpha: dynamicOpac.clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r / 2);
      canvas.drawCircle(rct.center, r, pnt);
    }

    drawFlare(0.15, 0.10, 80, const Color(0xFFFEF08A), 0.15, 0.25);
    drawFlare(0.13, 0.08, 48, const Color(0xFFFEF9C3), 0.1, 0.35);

    drawFlare(0.20, 0.15, 64, const Color(0xFFFEF08A), 0.2, 0.20);
    drawFlare(0.25, 0.12, 32, const Color(0xFFFED7AA), 0.1, 0.30);
    drawFlare(0.17, 0.18, 24, const Color(0xFFFEF9C3), 0.1, 0.25);
  }

  void _drawSparkles(Canvas canvas, Size size) {
    final pnt = Paint()..color = Colors.white;
    for (int i = 0; i < 15; i++) {
      // simulate exact animation using hash/predictable pseudorandom logic based on 'i'
      double offsetTop = (45 + (i * 7 % 30)) / 100.0;
      double offsetLeft = (i * 13 % 100) / 100.0;
      double animDelay = i * 0.4;
      double animDur = 2.0 + (i % 2);

      double time = (progress * 5) + animDelay;
      double cycle = (time / animDur) % 1.0;
      
      // Keyframe matching sparkle logic in React:
      // scale 0 -> 2 -> 0, opacity 0 -> 1 -> 0
      double power = math.sin(cycle * math.pi); // Smooth curve for 0->1->0

      if (power > 0) {
        pnt.color = Colors.white.withValues(alpha: power);
        canvas.drawCircle(Offset(size.width * offsetLeft, size.height * offsetTop), 0.5 + 2 * power, pnt);
      }
    }
  }

  @override
  bool shouldRepaint(ReactUiTranslationPainter oldDelegate) => true;
}