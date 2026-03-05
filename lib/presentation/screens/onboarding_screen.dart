import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/batik_background.dart';
import '../widgets/golden_tracer_indicator.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.appBackground),
        child: BatikBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text("Skip", style: TextStyle(color: Colors.white38)),
                  ),
                ),
                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildSlide1(),
                      _buildSlide2(),
                      _buildSlide3(),
                    ],
                  ),
                ),
                // Dots + Button
                _buildBottomControls(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Slide 1: AI Planning ──────────────────────────────────
  Widget _buildSlide1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.sigiriyaOchre.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppTheme.sigiriyaOchre.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.auto_awesome, size: 60, color: AppTheme.sigiriyaOchre),
            ),
          ),
          const SizedBox(height: 24),
          const GoldenTracerIndicator(),
          const SizedBox(height: 32),
          Text(
            "Plan Smarter with AI",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Tell the Oracle where you want to go.\nGet a full personalized itinerary for Sri Lanka in seconds.",
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle,
          ),
        ],
      ),
    );
  }

  // ── Slide 2: Hidden Gems ──────────────────────────────────
  Widget _buildSlide2() {
    final gems = [
      (Icons.park_outlined, "Nature Trails"),
      (Icons.temple_buddhist_outlined, "Ancient Temples"),
      (Icons.waves_outlined, "Pristine Beaches"),
      (Icons.landscape_outlined, "Hill Country"),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: gems.map((gem) => _gemBubble(gem.$1, gem.$2)).toList(),
          ),
          const SizedBox(height: 40),
          Text(
            "Discover Hidden Gems",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Explore over 150 off-the-beaten-path locations curated by locals and AI — places you won't find in any guidebook.",
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle,
          ),
        ],
      ),
    );
  }

  Widget _gemBubble(IconData icon, String label) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: AppTheme.glassDecoration(opacity: 0.08),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.sigiriyaOchre, size: 28),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Slide 3: Your Journey ─────────────────────────────────
  Widget _buildSlide3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.ceylonBlue.withValues(alpha: 0.3),
              border: Border.all(color: AppTheme.sigiriyaOchre.withValues(alpha: 0.3)),
            ),
            child: const Text("🇱🇰", style: TextStyle(fontSize: 60)),
          ),
          const SizedBox(height: 32),
          Text(
            "Your Journey,\nYour Way",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Sinhala, English, Tamil and more.\nOffline maps, emergency SOS, budget tracking — everything you need for the perfect Sri Lankan adventure.",
            textAlign: TextAlign.center,
            style: AppTheme.bodyStyle,
          ),
        ],
      ),
    );
  }

  // ── Bottom Controls ───────────────────────────────────────
  Widget _buildBottomControls() {
    return Column(
      children: [
        // Page dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => _dot(i)),
        ),
        const SizedBox(height: 32),
        // CTA button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sigiriyaOchre,
                foregroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: AppTheme.sigiriyaOchre.withValues(alpha: 0.4),
              ),
              child: Text(
                _currentPage == 2 ? "Start Exploring 🚀" : "Continue",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(int index) {
    final active = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppTheme.sigiriyaOchre : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
