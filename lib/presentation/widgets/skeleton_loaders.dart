import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

class ModernTracerShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const ModernTracerShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF262B2A) : Colors.grey[200]!,
      highlightColor: AppTheme.modernGreen.withOpacity(0.2),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }

  /// A standard rectangular skeleton box
  static Widget box(
    BuildContext context, {
    double? width,
    double height = 20,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// A circular skeleton (e.g. for profile pics)
  static Widget circle(BuildContext context, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
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
    return ModernTracerShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ModernTracerShimmer.box(context, width: 150, height: 24),
              const SizedBox(height: 8),
              ModernTracerShimmer.box(context, width: 100, height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
