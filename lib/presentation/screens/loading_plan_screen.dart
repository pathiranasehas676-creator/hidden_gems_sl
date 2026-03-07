import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/ai_trip_service.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/models/trip_plan_model.dart';
import '../widgets/batik_background.dart';
import '../widgets/golden_tracer_indicator.dart';
import 'results_screen.dart';

class LoadingPlanScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final int days;
  final String startDate;
  final String groupType;
  final String pace;
  final int budgetLkr;
  final String style;
  final String transport;
  final List<String> interests;
  final List<String> mustInclude;
  final List<String> avoid;
  final List<String> constraints;

  const LoadingPlanScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.days,
    required this.startDate,
    required this.groupType,
    required this.pace,
    required this.budgetLkr,
    required this.style,
    required this.transport,
    required this.interests,
    required this.mustInclude,
    required this.avoid,
    required this.constraints,
  });

  @override
  State<LoadingPlanScreen> createState() => _LoadingPlanScreenState();
}

class _LoadingPlanScreenState extends State<LoadingPlanScreen>
    with TickerProviderStateMixin {
  String _statusText = "Consulting TripMe.ai Brain...";
  bool _hasError = false;
  bool _isOfflineMode = false;
  String _errorMessage = "";
  
  late AnimationController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  final List<String> _progressMessages = [
    "Analyzing Sri Lanka train schedules...",
    "Checking seasonal weather patterns...",
    "Clustering the best hidden gems nearby...",
    "Calculating budget with 10% safety buffer...",
    "Crafting your personalised day plan...",
    "Adding rain-day alternatives (Plan B)...",
    "Finalising tips from local experts...",
  ];

  int _msgIndex = 0;

  @override
  void initState() {
    super.initState();
    _mapController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _generate();
    _animateMessages();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _animateMessages() async {
    while (_msgIndex < _progressMessages.length - 1 && mounted) {
      await Future.delayed(const Duration(milliseconds: 2800));
      if (mounted) {
        setState(() {
          _msgIndex = (_msgIndex + 1) % _progressMessages.length;
          _statusText = _progressMessages[_msgIndex];
        });
      }
    }
  }

  void _generate() async {
    // Build the deterministic cache key from all request params
    final cacheKey = TripCacheService.buildCacheKey(
      origin: widget.origin,
      destination: widget.destination,
      days: widget.days,
      budgetLkr: widget.budgetLkr,
      style: widget.style,
      interests: widget.interests,
      transport: widget.transport,
      startDate: widget.startDate,
    );

    try {
      final TripPlan plan = await AiTripService.generateTrip(
        origin: widget.origin,
        fromLat: 6.9271,
        fromLng: 79.8612,
        destination: widget.destination,
        days: widget.days,
        startDate: widget.startDate,
        groupType: widget.groupType,
        pace: widget.pace,
        budgetLkr: widget.budgetLkr,
        style: widget.style,
        interests: widget.interests,
        transportPreference: widget.transport,
        constraints: widget.constraints,
        mustInclude: widget.mustInclude,
        avoid: widget.avoid,
      );

      // ✅ Cache the freshly generated plan under the deterministic key
      await TripCacheService.cacheLastPlan(plan, cacheKey);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              plan: plan,
              cacheState: CacheReadResult.fresh,
            ),
          ),
        );
      }
    } catch (e) {
      // 🛰 Offline fallback: serve last cached plan if available
      final result = TripCacheService.getLastPlan(cacheKey);
      if (result.hasData && mounted) {
        setState(() => _isOfflineMode = true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                plan: result.plan!,
                cacheState: result.state,
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BatikBackground(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.white,
                const Color(0xFFF5F7F9), // Very light gray-blue
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: _hasError ? _buildErrorView() : _buildLoadingView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 🗺 Premium Map Animation
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 280,
              height: 280,
              child: AnimatedBuilder(
                animation: _mapController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: JourneyPathPainter(
                      progress: _mapController.value,
                      color: AppTheme.modernGreen.withValues(alpha: 0.1),
                    ),
                  );
                },
              ),
            ),
            // Floating Oracle Eye & Tracer
            FadeTransition(
              opacity: _pulseAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.modernGreen.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.modernGreen.withValues(alpha: 0.2), width: 0.5),
                      boxShadow: [
                        BoxShadow(color: AppTheme.modernGreen.withValues(alpha: 0.1), blurRadius: 40, spreadRadius: 10),
                      ],
                    ),
                    child: Icon(
                      _isOfflineMode ? Icons.cloud_done_outlined : Icons.auto_awesome,
                      size: 48,
                      color: AppTheme.modernGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const ModernTracerIndicator(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        
        // 🚥 Status messages with luxury typography
        Text(
          "SERENDIB ORACLE",
          style: GoogleFonts.inter(
            color: AppTheme.modernGreen,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          child: Text(
            _isOfflineMode ? "Synthesizing Local Memories…" : _statusText.toUpperCase(),
            key: ValueKey(_statusText),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: AppTheme.darkText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 64),
        
        // 📊 Summary Glass Chips
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             _glassChip(Icons.location_on_outlined, widget.destination),
             const SizedBox(width: 12),
             _glassChip(Icons.calendar_month_outlined, "${widget.days}D"),
          ],
        ),
      ],
    );
  }

  Widget _glassChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.modernBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.modernBlue.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.modernGreen),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(color: AppTheme.darkText.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 80),
        const SizedBox(height: 32),
        Text("Thinking Blocked", 
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(_errorMessage, 
          textAlign: TextAlign.center, 
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _hasError = false;
              _msgIndex = 0;
            });
            _generate();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.modernGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text("TRY AGAIN"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Refine Request", style: TextStyle(color: AppTheme.darkText.withValues(alpha: 0.5))),
        ),
      ],
    );
  }
}

/// 🎨 Custom JourneyPainter for the premium loading effect
class JourneyPathPainter extends CustomPainter {
  final double progress;
  final Color color;

  JourneyPathPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppTheme.modernGreen
      ..style = PaintingStyle.fill;

    // Stylized path approximating a journey across Sri Lanka
    final path = Path();
    path.moveTo(size.width * 0.4, size.height * 0.1); 
    path.quadraticBezierTo(size.width * 0.2, size.height * 0.4, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.6, size.width * 0.6, size.height * 0.9);
    path.lineTo(size.width * 0.3, size.height * 0.7);
    path.close();

    // Draw background path
    canvas.drawPath(path, paint..color = color.withValues(alpha: 0.1));

    // Draw animated progress path
    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(0.0, pathMetrics.length * progress);
    canvas.drawPath(extractPath, paint..color = AppTheme.modernGreen..strokeWidth = 3.0);

    // Draw the "traveling dot"
    final pos = pathMetrics.getTangentForOffset(pathMetrics.length * progress)?.position;
    if (pos != null) {
      canvas.drawCircle(pos, 6, dotPaint);
      canvas.drawCircle(pos, 12, dotPaint..color = AppTheme.modernGreen.withValues(alpha: 0.3));
    }
  }

  @override
  bool shouldRepaint(covariant JourneyPathPainter oldDelegate) => true;
}
