import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

class BatikBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const BatikBackground({
    super.key,
    required this.child,
    this.opacity = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: BatikPainter(opacity: opacity),
          ),
        ),
        child,
      ],
    );
  }
}

class BatikPainter extends CustomPainter {
  final double opacity;

  BatikPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw repeating stylized lotus or geometric floral patterns
    const double spacing = 120;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawBloom(canvas, Offset(x, y), 30, paint);
      }
    }
  }

  void _drawBloom(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (math.pi / 180);
      final outerX = center.dx + math.cos(angle) * radius;
      final outerY = center.dy + math.sin(angle) * radius;
      
      final cp1Angle = (i * 45 - 20) * (math.pi / 180);
      final cp1X = center.dx + math.cos(cp1Angle) * radius * 1.5;
      final cp1Y = center.dy + math.sin(cp1Angle) * radius * 1.5;

      final cp2Angle = (i * 45 + 20) * (math.pi / 180);
      final cp2X = center.dx + math.cos(cp2Angle) * radius * 1.5;
      final cp2Y = center.dy + math.sin(cp2Angle) * radius * 1.5;

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.quadraticBezierTo(cp1X, cp1Y, outerX, outerY);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    
    // Tiny center circle
    canvas.drawCircle(center, 4, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
