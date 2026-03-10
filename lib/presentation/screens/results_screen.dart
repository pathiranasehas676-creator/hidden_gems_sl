import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/locale_provider.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/datasources/monetization_service.dart';
import '../../data/datasources/premium_service.dart';
import '../../data/datasources/pdf_service.dart';
import '../../data/models/trip_plan_model.dart';
import '../widgets/offline_highlights_widget.dart';
import '../widgets/batik_background.dart';
import '../widgets/oracle_aura_widget.dart';
import '../widgets/dynamic_light_wrapper.dart';
import '../widgets/custom_buttons.dart';
import 'map_route_screen.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import 'dart:ui';
import '../../core/analytics/analytics_service.dart';
import '../../core/rating/rating_service.dart';
import '../../data/datasources/voice_service.dart';
import '../../core/utils/screenshot_service.dart';
import 'package:screenshot/screenshot.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'budget_tracker_screen.dart';

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
  bool _planBUnlocked = false;
  bool _isListening = false;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  final ScreenshotService _screenshotService = ScreenshotService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.lightImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isInit = true);
    });

    _initBanner();
    _triggerPostGenerationEvents();
  }

  void _triggerPostGenerationEvents() async {
    // 1. Log Analytics
    await AnalyticsService().logPlanGenerated(
      destination: widget.plan.destination,
      style: widget.plan.tripSummary.style,
      days: widget.plan.itinerary.length,
      verifiedScore: widget.plan.verifiedScore,
    );

    // 2. Increment Trip Count for User DNA
    await UserPreferenceService.addTrip();

    // 3. Check for Rating Prompt (Milestone trigger)
    await RatingService().checkAndRequestReview();
  }

  void _initBanner() async {
    final isPremium = Provider.of<PremiumService>(context, listen: false).isPremium;
    if (!isPremium) {
      _bannerAd = await MonetizationService().createBannerAd();
      setState(() => _isBannerLoaded = true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = Provider.of<PremiumService>(context).isPremium;
    final l10n = AppLocalizations.of(context)!;
    final plan = widget.plan;

    return Scaffold(
      backgroundColor: Colors.white, // Background handled by BatikBackground
      body: Screenshot(
        controller: _screenshotService.controller,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor, // Ensure background is captured
          child: Stack(
            children: [
              NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  stretch: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).colorScheme.primary, size: 20),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: AppTheme.glassDecoration(opacity: 0.2, radius: BorderRadius.circular(16)),
                      child: _buildSaveButton(plan),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: AppTheme.glassDecoration(opacity: 0.2, radius: BorderRadius.circular(16)),
                      child: IconButton(
                        icon: const Icon(Icons.public, color: AppTheme.modernBlue),
                        tooltip: "View Visual Route",
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MapRouteScreen(plan: plan)));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: AppTheme.glassDecoration(opacity: 0.2, radius: BorderRadius.circular(16)),
                      child: IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.modernBlue),
                        onPressed: () {
                          if (isPremium) {
                            PdfService.generateAndShareTripPdf(plan);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("PDF Export is a Premium feature.")),
                            );
                            _tabController.animateTo(2); // Jump to Plan B / Premium CTA
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: AppTheme.glassDecoration(opacity: 0.2, radius: BorderRadius.circular(16)),
                      child: IconButton(
                        icon: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.modernBlue),
                        tooltip: "Budget Tracker",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BudgetTrackerScreen(plan: plan),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildConfidenceBadge(plan.verifiedScore),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 60),
                    title: Builder(
                      builder: (context) {
                        final summary = widget.plan.tripSummary;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.destinationCity,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              "Your Personalized Journey",
                              style: GoogleFonts.inter(
                                fontSize: 10, 
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _getDestinationImage(widget.plan.tripSummary.destinationCity),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.modernBlue, Color(0xFF0D47A1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(Icons.landscape, size: 100, color: Colors.white.withOpacity(0.2)),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.modernBlue, Color(0xFF0D47A1)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(Icons.broken_image, size: 100, color: Colors.white.withOpacity(0.2)),
                            ),
                          ),
                        ),
                        // Gradient overlay for text readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.4),
                                Colors.transparent,
                                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
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
                        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        indicatorPadding: const EdgeInsets.symmetric(horizontal: -12, vertical: 4),
                        labelColor: Colors.white,
                        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                        tabs: [
                          Tab(text: l10n.itinerary),
                          const Tab(text: "Budget"),
                          const Tab(text: "Map"),
                          Tab(text: l10n.planB),
                          Tab(text: l10n.tips),
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
                    _buildItineraryTab(plan, l10n),
                    _buildBudgetTab(plan),
                    _buildMapTab(plan),
                    _buildPlanBTab(plan, isPremium),
                    _buildTipsTab(plan),
                  ],
                ),
              ),
            ),
          ),

          // Oracle Aura Overlay
          if (_isListening)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: OracleAuraWidget(isVisible: _isListening),
                ),
              ),
            ),
          
          // Ad Banner at bottom (Optimized & Polished)
          if (!isPremium && _isBannerLoaded)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.silkPearl.withOpacity(0.1), width: 1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
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
    ),
  ),
);
}


  Widget _buildVoiceButton(TripPlan plan, bool isPremium) {
    final localeCode = Provider.of<LocaleProvider>(context, listen: false).locale?.languageCode ?? 'en';
    
    return IconButton(
      icon: Icon(
        _isListening ? Icons.stop_circle_outlined : Icons.play_circle_fill,
        color: AppTheme.accentOchre,
        size: 28,
      ),
      onPressed: () async {
        if (!isPremium) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Voice Guide is a Premium feature.")),
          );
          _tabController.animateTo(2);
          return;
        }

        if (_isListening) {
          await VoiceService().stop();
          if (mounted) setState(() => _isListening = false);
        } else {
          setState(() => _isListening = true);
          await VoiceService().speak(plan.humanText, languageCode: localeCode);
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  Widget _buildSaveButton(TripPlan plan) {
    return IconButton(
      icon: Icon(
        _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
        color: _isSaved ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: AppTheme.glassDecoration(opacity: 0.2, radius: BorderRadius.circular(16)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              value: score / 100,
              backgroundColor: AppTheme.modernBlue.withOpacity(0.1),
              color: AppTheme.modernGreen,
              strokeWidth: 3,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 2),
              Text("$score", style: GoogleFonts.outfit(color: AppTheme.modernBlue, fontWeight: FontWeight.bold, fontSize: 11)),
              Text("VERIFIED", style: GoogleFonts.inter(color: AppTheme.modernGreen, fontSize: 5, fontWeight: FontWeight.bold)),
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
  Widget _buildItineraryTab(TripPlan plan, AppLocalizations l10n) {
    final isPremium = Provider.of<PremiumService>(context, listen: false).isPremium;

    return Column(
      children: [
        if (widget.cacheState != CacheReadResult.fresh)
          OfflineHighlightsWidget(destination: plan.destination),
        
        // Oracle's Summary & Voice Guide
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(opacity: 0.1, radius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.modernGreen, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      "ORACLE'S VISION",
                      style: GoogleFonts.outfit(
                        color: AppTheme.modernGreen, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 2, 
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    _buildVoiceButton(plan, isPremium),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  plan.humanText,
                  style: GoogleFonts.inter(
                    color: AppTheme.darkText, 
                    height: 1.6, 
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

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
        decoration: AppTheme.glassDecoration(
          opacity: Theme.of(context).brightness == Brightness.light ? 0.8 : 0.1, 
          radius: BorderRadius.circular(20),
          color: Colors.white,
        ).copyWith(
          border: Border.all(color: AppTheme.modernBlue.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.modernGradient, 
                shape: BoxShape.circle, 
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.modernGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Text(
                "${day.day}", 
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Day ${day.day}".toUpperCase(), 
                    style: GoogleFonts.inter(
                      color: AppTheme.modernGreen, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 12, 
                      letterSpacing: 2,
                    ),
                  ),
                  if (day.dayTheme.isNotEmpty)
                    Text(
                      day.dayTheme, 
                      style: GoogleFonts.outfit(
                        color: AppTheme.darkText, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 20,
                      ),
                    ),
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
                      color: AppTheme.modernBlue,
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
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.modernGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppTheme.modernGreen.withOpacity(0.5), blurRadius: 8, spreadRadius: 2),
                    const BoxShadow(color: Colors.white, blurRadius: 2, spreadRadius: 1),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: 2, 
                  margin: const EdgeInsets.symmetric(vertical: 8), 
                  decoration: BoxDecoration(
                    color: AppTheme.modernGreen.withOpacity(0.3),
                  )
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: AppTheme.glassDecoration(
                color: Colors.white,
                opacity: 0.9,
              ).copyWith(
                border: Border(left: BorderSide(color: AppTheme.modernGreen, width: 4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title, 
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16, 
                              color: AppTheme.darkText,
                            ),
                          ),
                        ),
                        Icon(typeInfo.icon, size: 18, color: typeInfo.color.withOpacity(0.5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _infoChip("${item.durationMin} MINS", Colors.grey.shade600),
                        if (item.costLkr > 0) ...[
                          const SizedBox(width: 12),
                          _infoChip(_fmtLkr(item.costLkr), AppTheme.modernGreen),
                        ],
                      ],
                    ),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        item.notes, 
                        style: GoogleFonts.inter(
                          fontSize: 13, 
                          color: AppTheme.darkText.withOpacity(0.7), 
                          height: 1.5,
                        ),
                      ),
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
  Widget _buildBudgetTab(TripPlan plan) {
    int totalCost = 0;
    Map<String, int> categories = {
      'Transport': 0,
      'Food': 0,
      'Attractions': 0,
      'Hotel': 0,
      'Other': 0,
    };

    for (var day in plan.itinerary) {
      for (var item in day.items) {
        totalCost += item.costLkr;
        if (item.isTransport) {
          categories['Transport'] = categories['Transport']! + item.costLkr;
        } else if (item.isFood) {
          categories['Food'] = categories['Food']! + item.costLkr;
        } else if (item.isHotel) {
          categories['Hotel'] = categories['Hotel']! + item.costLkr;
        } else if (item.type == 'attraction') {
          categories['Attractions'] = categories['Attractions']! + item.costLkr;
        } else {
          categories['Other'] = categories['Other']! + item.costLkr;
        }
      }
    }
    
    final userBudget = plan.tripSummary.userBudgetLkr;
    final progress = userBudget > 0 ? (totalCost / userBudget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = totalCost > userBudget && userBudget > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBudgetCard(totalCost, userBudget, progress, isOverBudget),
          const SizedBox(height: 24),
          _buildSectionHeader("Expense Breakdown"),
          const SizedBox(height: 16),
          ...categories.entries.where((e) => e.value > 0).map((e) => _buildBudgetRow(e.key, e.value, totalCost)),
        ],
      ),
    );
  }

  Widget _buildHeroBudgetCard(int total, int userBudget, double progress, bool isOver) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(
        color: Theme.of(context).cardColor,
        opacity: Theme.of(context).brightness == Brightness.light ? 0.9 : 0.15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ESTIMATED TOTAL", 
                style: GoogleFonts.inter(
                  color: AppTheme.modernGreen, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 12, 
                  letterSpacing: 1.5,
                ),
              ),
              if (isOver) 
                const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmtLkr(total), 
            style: GoogleFonts.outfit(
              color: AppTheme.darkText, 
              fontSize: 32, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? Colors.orangeAccent : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "User Budget: ${_fmtLkr(userBudget)}", 
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), 
                  fontSize: 12,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}% Used", 
                style: TextStyle(
                  color: isOver ? Colors.orangeAccent : Theme.of(context).colorScheme.primary, 
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRow(String label, int amount, int total) {
    final percent = (amount / total * 100).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        color: Theme.of(context).cardColor,
        opacity: Theme.of(context).brightness == Brightness.light ? 0.7 : 0.05,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
            child: Icon(_getCategoryIcon(label), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, 
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "$percent% of total", 
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), 
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _fmtLkr(amount), 
            style: GoogleFonts.outfit(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), 
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String label) {
    switch (label) {
      case 'Transport': return Icons.directions_bus_outlined;
      case 'Food': return Icons.restaurant_outlined;
      case 'Hotel': return Icons.hotel_outlined;
      case 'Attractions': return Icons.map_outlined;
      default: return Icons.more_horiz;
    }
  }

  Widget _buildMapTab(TripPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.map_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 32),
          Text(
            "Visual Tour Route",
            style: GoogleFonts.outfit(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Plot your entire journey across the teardrop isle. View detailed route segments and travel times.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), 
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          ModernGradientButton(
            label: "Open Route Map",
            onPressed: () {
               HapticFeedback.heavyImpact();
               Navigator.push(context, MaterialPageRoute(builder: (_) => MapRouteScreen(plan: plan)));
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 3 – PLAN B (RAIN)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPlanBTab(TripPlan plan, bool isPremium) {
    if (!isPremium && !_planBUnlocked) {
      return _buildRewardedGate();
    }

    final item = plan.planB;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.umbrella, color: AppTheme.accentOchre, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Oracle's Rain Plan", 
                        style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.primary, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Caught in a sudden shower? Switch to this.", 
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), 
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildPlanBCard(item),
          const SizedBox(height: 40),
          _buildPremiumCTA(),
        ],
      ),
    );
  }

  Widget _buildRewardedGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.glassDecoration(
            color: Theme.of(context).cardColor,
            opacity: Theme.of(context).brightness == Brightness.light ? 0.9 : 0.2,
          ).copyWith(
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.accentOchre.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: AppTheme.accentOchre, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                "Oracle's Vault",
                style: GoogleFonts.outfit(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "The rainy-day alternative is locked for free travelers.\nWatch a short video to unlock it for this trip.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                MonetizationService().showRewardedAd(onRewardEarned: (reward) {
                  setState(() => _planBUnlocked = true);
                });
              },
              icon: const Icon(Icons.play_circle_fill),
              label: const Text("UNLOCK WITH AD"),
              style: AppTheme.primaryButtonStyle(context),
            ),
            TextButton(
              onPressed: () => Provider.of<PremiumService>(context, listen: false).buyPremium(),
              child: Text(
                "Go Premium for Ad-Free Experience", 
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    ),
   );
  }

  Widget _buildPremiumCTA() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassDecoration(
        color: Theme.of(context).cardColor,
        opacity: Theme.of(context).brightness == Brightness.light ? 1.0 : 0.2, // Make it pop in light mode
      ).copyWith(
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.stars, color: AppTheme.accentOchre.withOpacity(0.2), size: 80),
              const Icon(Icons.rocket_launch_rounded, color: AppTheme.primaryBlue, size: 40),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "TRIPME LUXURY",
            style: GoogleFonts.outfit(
              color: Colors.white, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 4,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Go beyond the ordinary. Unlock the Oracle's full wisdom.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _premiumFeature(Icons.mic_none, "Voice"),
              _premiumFeature(Icons.picture_as_pdf, "PDF"),
              _premiumFeature(Icons.block, "No Ads"),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentOchre.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Provider.of<PremiumService>(context, listen: false).buyPremium(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOchre,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                "UNLEASH THE ORACLE", 
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumFeature(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildPlanBCard(PlanBItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title, 
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, 
                fontSize: 18, 
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.reason, 
              style: GoogleFonts.inter(
                fontSize: 14, 
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), 
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                const SizedBox(width: 4),
                Text("${item.lat.toStringAsFixed(4)}, ${item.lng.toStringAsFixed(4)}", 
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
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
        Text("Verification Sources", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: plan.kbCitations.map((c) => _sourceChip(c)).toList(),
        ),
        const SizedBox(height: 32),
        const Text("💡 Pro Tips for Sri Lanka", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
        const SizedBox(height: 12),
        ...plan.tips.map((t) => _tipItem(t)),
      ],
    );
  }

  Widget _buildSafetyHero(String tip) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
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
          Text(tip, style: GoogleFonts.inter(fontSize: 15, color: Colors.orangeAccent, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sourceChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
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
          Expanded(child: Text(tip, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════

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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
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
