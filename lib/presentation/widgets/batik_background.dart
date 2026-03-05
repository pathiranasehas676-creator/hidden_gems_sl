import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

class BatikBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  const BatikBackground({super.key, required this.child, this.opacity = 0.03});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: BatikPainter(
              color: AppTheme.sigiriyaOchre.withValues(alpha: opacity),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class BatikPainter extends CustomPainter {
  final Color color;
  BatikPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final random = math.Random(42); // Seeded for consistency

    // Draw some organic patterns
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
      canvas.drawPath(path, paint);
    }

    // Draw some circular "dots" (representative of some batik styles)
    for (var i = 0; i < 30; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        random.nextDouble() * 4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
