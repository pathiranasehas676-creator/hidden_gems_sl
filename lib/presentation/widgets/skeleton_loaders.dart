import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

class GoldenTracerShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const GoldenTracerShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF262B2A) : Colors.grey[300]!,
      highlightColor: AppTheme.sigiriyaOchre.withValues(alpha: 0.3),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }

  /// A standard rectangular skeleton box
  static Widget box({
    double? width,
    double height = 20,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// A circular skeleton (e.g. for profile pics)
  static Widget circle({double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// A premium skeleton for discovery cards
class DiscoveryCardSkeleton extends StatelessWidget {
  const DiscoveryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GoldenTracerShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GoldenTracerShimmer.box(width: 150, height: 24),
              const SizedBox(height: 8),
              GoldenTracerShimmer.box(width: 100, height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
