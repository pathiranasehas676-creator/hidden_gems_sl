import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/vibe_theme_provider.dart';

class BatikBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  const BatikBackground({super.key, required this.child, this.opacity = 0.03});

  @override
  Widget build(BuildContext context) {
    // Read active vibe theme — rebuilds the whole bg when user changes theme
    final vibeTheme = context.watch<VibeThemeProvider>().current;

    return Container(
      decoration: BoxDecoration(gradient: vibeTheme.background),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: BatikPainter(
                  color: vibeTheme.accent.withValues(alpha: opacity),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class BatikPainter extends CustomPainter {
  final Color color;
  
  // Static cache so paths aren't rebuilt over and over
  static final List<Path> _cachedPaths = [];
  static final List<_Dot> _cachedDots = [];
  static Size? _cachedSize;

  BatikPainter({required this.color});


  @override
  void paint(Canvas canvas, Size size) {
    // Only generate paths if size changed or first run
    if (_cachedSize != size) {
      _generatePaths(size);
      _cachedSize = size;
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final path in _cachedPaths) {
      canvas.drawPath(path, paint);
    }

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final dot in _cachedDots) {
      canvas.drawCircle(dot.center, dot.radius, dotPaint);
    }
  }

  void _generatePaths(Size size) {
    _cachedPaths.clear();
    _cachedDots.clear();
    final random = math.Random(42);

    for (var i = 0; i < 15; i++) {
      final path = Path();
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      path.moveTo(x, y);

      for (var j = 0; j < 5; j++) {
        double nextX = x + (random.nextDouble() - 0.5) * 200;
        double nextY = y + (random.nextDouble() - 0.5) * 200;
        double cp1x = x + (random.nextDouble() - 0.5) * 100;
        double cp1y = y + (random.nextDouble() - 0.5) * 100;
        double cp2x = nextX - (random.nextDouble() - 0.5) * 100;
        double cp2y = nextY - (random.nextDouble() - 0.5) * 100;
        path.cubicTo(cp1x, cp1y, cp2x, cp2y, nextX, nextY);
        x = nextX;
        y = nextY;
      }
      _cachedPaths.add(path);
    }

    for (var i = 0; i < 30; i++) {
      _cachedDots.add(_Dot(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        random.nextDouble() * 4,
      ));
    }
  }

  @override
  bool shouldRepaint(covariant BatikPainter old) => old.color != color;
}

class _Dot {
  final Offset center;
  final double radius;
  _Dot(this.center, this.radius);
}

