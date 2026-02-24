import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/models/trip_plan_model.dart';
import '../widgets/offline_highlights_widget.dart';
import '../widgets/batik_background.dart';
import '../widgets/dynamic_light_wrapper.dart';

class ResultsScreen extends StatefulWidget {
  final TripPlan plan;
  final CacheReadResult cacheState;

  const ResultsScreen({
    super.key,
    required this.plan,
    this.cacheState = CacheReadResult.miss,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.lightImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isInit = true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      backgroundColor: AppTheme.silkPearl,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppTheme.primaryBlue,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                  ),
                  actions: [
                    _buildSaveButton(plan),
                    _buildConfidenceBadge(plan.verifiedScore),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 60),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.destinationCity,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.white,
                            shadows: [const Shadow(color: Colors.black45, blurRadius: 10)],
                          ),
                        ),
                        Text(
                          "Your Personalized Journey",
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          _getDestinationImage(summary.destinationCity),
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, s) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryBlue, Color(0xFF005A8E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(Icons.landscape, size: 100, color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ),
                        ),
                        // Gradient overlay for text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                                AppTheme.primaryBlue.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: AppTheme.accentOchre,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white38,
                        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(text: "Itinerary"),
                          Tab(text: "Style"),
                          Tab(text: "Plan B"),
                          Tab(text: "Tips"),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: BatikBackground(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 1000),
                opacity: _isInit ? 1.0 : 0.0,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildItineraryTab(plan),
                    _buildStyleTab(plan),
                    _buildPlanBTab(plan),
                    _buildTipsTab(plan),
                  ],
                ),
              ),
            ),
          ),
          // Time-Aware Dynamic Overlay
          IgnorePointer(
            child: Container(
              color: AppTheme.getDynamicOverlay(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(TripPlan plan) {
    return IconButton(
      icon: Icon(
        _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
        color: _isSaved ? AppTheme.accentOchre : Colors.white,
      ),
      onPressed: () async {
        if (!_isSaved) {
          await TripCacheService.savePlan(plan);
          if (mounted) setState(() => _isSaved = true);
        }
      },
    );
  }

  Widget _buildConfidenceBadge(int score) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white10,
              color: AppTheme.accentOchre,
              strokeWidth: 3,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$score", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              Text("VERIFIED", style: GoogleFonts.inter(color: AppTheme.accentOchre, fontSize: 6, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  String _getDestinationImage(String city) {
    // High-quality placeholders for key cities
    final images = {
      'Kandy': 'https://images.unsplash.com/photo-1588598116346-6019f6f67f67?auto=format&fit=crop&q=80&w=800',
      'Ella': 'https://images.unsplash.com/photo-1546708973-b339540b51bd?auto=format&fit=crop&q=80&w=800',
      'Galle': 'https://images.unsplash.com/photo-1625484478269-95333f8e6c4a?auto=format&fit=crop&q=80&w=800',
      'Colombo': 'https://images.unsplash.com/photo-1582298538104-fe2e74c27f59?auto=format&fit=crop&q=80&w=800',
    };
    return images[city] ?? 'https://images.unsplash.com/photo-1549880338-65ddcdfd017b?auto=format&fit=crop&q=80&w=800';
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1 – ITINERARY
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildItineraryTab(TripPlan plan) {
    return Column(
      children: [
        if (widget.cacheState != CacheReadResult.fresh)
          OfflineHighlightsWidget(destination: plan.destination),
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: plan.itinerary.length,
              itemBuilder: (context, dIndex) {
                final day = plan.itinerary[dIndex];
                return AnimationConfiguration.staggeredList(
                  position: dIndex,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDayHeader(day),
                          const SizedBox(height: 12),
                          ...day.items.map((item) => _buildTimelineItem(item)),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeader(ItineraryDay day) {
    return DynamicLightWrapper(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: AppTheme.glassDecoration(opacity: 0.1, radius: BorderRadius.circular(20)).copyWith(
          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle, boxShadow: AppTheme.premiumShadow),
              child: Text("${day.day}", 
                style: GoogleFonts.outfit(color: AppTheme.accentOchre, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Day ${day.day}".toUpperCase(), 
                    style: GoogleFonts.inter(color: AppTheme.accentOchre, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                  if (day.dayTheme.isNotEmpty)
                    Text(day.dayTheme, 
                      style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(ItineraryItem item) {
    final typeInfo = _typeInfo(item.type);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 70,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  item.time,
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentOchre,
                      fontSize: 13),
                ),
                Expanded(
                  child: Container(width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ],
            ),
          ),
          // Vertical Line & Dot
          Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: typeInfo.color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: typeInfo.color.withValues(alpha: 0.3), blurRadius: 10)],
                ),
              ),
              Expanded(
                child: Container(width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 8)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue))),
                        Icon(typeInfo.icon, size: 18, color: typeInfo.color.withValues(alpha: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _infoChip("${item.durationMin} MINS", Colors.grey.shade600),
                        if (item.costLkr > 0) ...[
                          const SizedBox(width: 12),
                          _infoChip(_fmtLkr(item.costLkr), AppTheme.accentOchre),
                        ],
                      ],
                    ),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(item.notes, style: GoogleFonts.inter(fontSize: 13, color: Colors.black54, height: 1.5)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2 – BUDGET
  // ═══════════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════
  // TAB 2 – ORACLE STYLE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStyleTab(TripPlan plan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOracleIntro(plan),
          const SizedBox(height: 24),
          _buildStyleToggle(plan),
        ],
      ),
    );
  }

  Widget _buildOracleIntro(TripPlan plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primaryBlue,
                child: Icon(Icons.auto_awesome, color: AppTheme.accentOchre, size: 20),
              ),
              const SizedBox(width: 12),
              Text("Oracle's Perspective", 
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan.humanText,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, height: 1.6, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleToggle(TripPlan plan) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppTheme.softShadow,
              ),
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(child: Text("Compact", style: TextStyle(fontWeight: FontWeight.bold))),
                Tab(child: Text("Narrative", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 400, // Adjust as needed
            child: TabBarView(
              children: [
                _buildCard(plan.styleVariants.compact, Icons.list_alt),
                _buildCard(plan.styleVariants.narrative, Icons.auto_stories),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryBlue.withOpacity(0.5), size: 32),
            const SizedBox(height: 16),
            Text(text, style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: Colors.blackDE)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 3 – PLAN B (RAIN)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPlanBTab(TripPlan plan) {
    final item = plan.planB;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade800,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.umbrella, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Oracle's Rain Plan", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text("Caught in a sudden shower? Switch to this.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPlanBCard(item),
        ],
      ),
    );
  }

  Widget _buildPlanBCard(PlanBItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
            const SizedBox(height: 12),
            Text(item.reason, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, height: 1.5)),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                const SizedBox(width: 4),
                Text("${item.lat.toStringAsFixed(4)}, ${item.lng.toStringAsFixed(4)}", 
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text("View on Map"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 4 – COMFORT UPGRADES
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildTipsTab(TripPlan plan) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        _buildSafetyHero(plan.safetyTip),
        const SizedBox(height: 24),
        Text("Verification Sources", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: plan.kbCitations.map((c) => _sourceChip(c)).toList(),
        ),
        const SizedBox(height: 32),
        const Text("💡 Pro Tips for Sri Lanka", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 12),
        ...plan.tips.map((t) => _tipItem(t)),
      ],
    );
  }

  Widget _buildSafetyHero(String tip) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              Text("Oracle's Local Tip", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
            ],
          ),
          const SizedBox(height: 12),
          Text(tip, style: GoogleFonts.inter(fontSize: 15, color: Colors.orange.shade900, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sourceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
    );
  }

  Widget _tipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, size: 16, color: AppTheme.accentOchre),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(tip, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _fmtLkr(int n) {
    if (n >= 100000) {
      return "LKR ${(n / 1000).toStringAsFixed(0)}K";
    }
    // Add comma formatting manually
    final s = n.toString();
    if (s.length <= 3) return "LKR $s";
    final chars = s.split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) result.add(',');
      result.add(chars[i]);
    }
    return "LKR ${result.reversed.join()}";
  }

  _TypeInfo _typeInfo(String type) {
    switch (type) {
      case 'transport':
        return _TypeInfo(Icons.directions_bus, Colors.indigo, "Transport");
      case 'food':
        return _TypeInfo(Icons.restaurant, Colors.orange, "Food");
      case 'rest':
        return _TypeInfo(Icons.hotel, Colors.teal, "Rest");
      case 'hotel':
        return _TypeInfo(Icons.bed, Colors.teal, "Hotel");
      case 'shopping':
        return _TypeInfo(Icons.shopping_bag, Colors.pink, "Shopping");
      case 'nature':
        return _TypeInfo(Icons.forest, Colors.green, "Nature");
      case 'culture':
        return _TypeInfo(Icons.temple_hindu, Colors.deepPurple, "Culture");
      case 'attraction':
        return _TypeInfo(Icons.star, AppTheme.primaryBlue, "Attraction");
      default:
        return _TypeInfo(Icons.place, Colors.blueGrey, type);
    }
  }
}

class _TypeInfo {
  final IconData icon;
  final Color color;
  final String label;
  _TypeInfo(this.icon, this.color, this.label);
}
