import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class GoldenTracerIndicator extends StatefulWidget {
  const GoldenTracerIndicator({super.key});

  @override
  State<GoldenTracerIndicator> createState() => _GoldenTracerIndicatorState();
}

class _GoldenTracerIndicatorState extends State<GoldenTracerIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassDecoration(opacity: 0.1, radius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          const SizedBox(width: 8),
          _buildDot(0.2),
          const SizedBox(width: 8),
          _buildDot(0.4),
        ],
      ),
    );
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = (_controller.value + delay) % 1.0;
        final scale = 0.8 + (0.4 * (1.0 - (progress - 0.5).abs() * 2));
        final opacity = 0.4 + (0.6 * (1.0 - (progress - 0.5).abs() * 2));
        
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.accentOchre.withValues(alpha: opacity),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentOchre.withValues(alpha: opacity * 0.5),
                  blurRadius: 8,
                  spreadRadius: progress * 2,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
