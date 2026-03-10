import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../widgets/batik_background.dart';
import '../widgets/dynamic_light_wrapper.dart';
import '../widgets/custom_buttons.dart';
import 'scanner_screen.dart';
import 'saved_plans_screen.dart';
import 'trip_form_screen.dart';
import 'discovery_screen.dart';
import 'profile_screen.dart';
import 'event_calendar_screen.dart';
import '../admin/admin_shell.dart';
import '../../data/datasources/live_events_service.dart';
import '../../data/models/event_model.dart';

class HomeScreen extends StatefulWidget {
  final bool isOffline;
  const HomeScreen({super.key, this.isOffline = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // For bottom navigation
  
  List<EventModel> _todayEvents = [];
  bool _showEventBanner = true;
  
  late Timer _bgTimer;
  int _bgImageIndex = 0;
  final List<String> _bgImages = [
    "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1546708973-b339540b5162?q=80&w=2670&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1588598108426-e49053cbf995?q=80&w=2070&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1610448106192-36ff0183b052?q=80&w=2072&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1578330105307-f3900ac1048b?q=80&w=2070&auto=format&fit=crop",
  ];

  @override
  void initState() {
    super.initState();
    _checkTodayEvents();
    _startBgTimer();
  }

  void _startBgTimer() {
    _bgTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _bgImageIndex = (_bgImageIndex + 1) % _bgImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bgTimer.cancel();
    super.dispose();
  }

  void _checkTodayEvents() {
    final events = LiveEventsService.getTodayEvents();
    if (events.isNotEmpty && mounted) {
      setState(() {
        _todayEvents = events;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOffline = widget.isOffline;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent, // Background handled by BatikBackground
      body: Stack(
        children: [
          BatikBackground(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                SliverToBoxAdapter(
                  child: AnimationLimiter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 800),
                          childAnimationBuilder: (widget) => FadeInAnimation(
                            child: SlideAnimation(
                              verticalOffset: 30.0,
                              child: widget,
                            ),
                          ),
                          children: [
                            _journalUnfold(child: _buildWelcomeCard()),
                            const SizedBox(height: 24),
                            ModernGradientButton(
                              label: l10n.planNewTrip,
                              icon: Icons.auto_awesome,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TripFormScreen()),
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            if (_todayEvents.isNotEmpty && _showEventBanner) ...[
                               _buildTodayEventBanner(),
                               const SizedBox(height: 24),
                            ],
                            if (isOffline) ...[
                              _buildSectionHeader(l10n.localGemsOffline),
                              const SizedBox(height: 16),
                              _buildLocalGemsScroller(context),
                              const SizedBox(height: 24),

                            ],
                            const SizedBox(height: 16),
                            _buildCategoriesGrid(),
                            const SizedBox(height: 32),
                            _buildSectionHeader(l10n.oraclesChoice),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildRecentPlansList(context, l10n),
                  ),
                ),
              ],
            ),
          ),
          if (isOffline) _buildOfflineBadge(),
          // Time-Aware Dynamic Overlay
          IgnorePointer(
            child: Container(
              color: AppTheme.getDynamicOverlay(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, l10n),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.sigiriyaOchre.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TripFormScreen()),
            );
          },
          backgroundColor: AppTheme.sigiriyaOchre,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.auto_awesome, color: Colors.black, size: 28),
        ),
      ),
    );
  }

  Widget _buildTodayEventBanner() {
    final event = _todayEvents.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(opacity: 0.15, blur: 20).copyWith(
        border: Border.all(color: AppTheme.accentOchre.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentOchre.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration, color: AppTheme.accentOchre, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today in Sri Lanka 🇱🇰",
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.name,
                      style: GoogleFonts.outfit(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (event.description.isNotEmpty)
                      Text(
                        event.description,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: -10,
            right: -10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 18),
              onPressed: () {
                setState(() => _showEventBanner = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _journalUnfold({required Widget child}) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 1000),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: child,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final user = widget.isOffline ? null : FirebaseAuth.instance.currentUser;
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent, // Let gradient show
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Rotating Background Image with cross-fade & improved loading
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1500),
              child: Container(
                key: ValueKey<int>(_bgImageIndex),
                width: double.infinity,
                height: double.infinity,
                child: Image.network(
                  _bgImages[_bgImageIndex],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.primaryBlue),
                ),
              ),
            ),
            // Darker Overlay for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.2),
                    AppTheme.primaryBlue.withOpacity(0.8),
                    AppTheme.primaryBlue,
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // "Discover Sri Lanka" Title
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const SizedBox(height: 40),
                   Text(
                    "Discover Sri Lanka",
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Let the Oracle guide your journey",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 54,
                      decoration: AppTheme.glassDecoration(
                        opacity: 0.1, 
                        blur: 20,
                        isDark: true,
                        radius: BorderRadius.circular(27),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(Icons.search, color: AppTheme.sigiriyaOchre, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Search secret locations...",
                              style: GoogleFonts.inter(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (user != null)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Container(
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.sigiriyaOchre.withOpacity(0.2),
                  backgroundImage: NetworkImage(user.photoURL ?? "https://ui-avatars.com/api/?name=${user.displayName}"),
                ),
              ),
            ),
          )
        else
          _glassActionIcon(Icons.person_outline, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }, iconColor: Theme.of(context).colorScheme.onSurface),
        
        _glassActionIcon(Icons.bookmark_border_rounded, () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlansScreen()));
        }),
        _glassActionIcon(Icons.camera_enhance_outlined, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
        }),
        _glassActionIcon(Icons.shield_outlined, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminShell()));
        }),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildOfflineBadge() {
    return Positioned(
      top: 60,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              "OFFLINE MODE",
              style: AppTheme.labelStyle(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final user = widget.isOffline ? null : FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(" ").first ?? "Traveler";

    return DynamicLightWrapper(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassDecoration(), // Ocean Glassmorphism
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.modernGradient.createShader(bounds),
                  child: Text(
                    "Ayubowan, $name!".toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Where shall the\nOracle guide you?",
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  Widget _buildCategoriesGrid() {
    final categories = [
      ("Nature", Icons.forest_outlined, AppTheme.modernGreen),
      ("Beaches", Icons.waves_rounded, Colors.blue),
      ("Culture", Icons.temple_hindu_outlined, AppTheme.sigiriyaOchre),
      ("Adventure", Icons.explore_outlined, AppTheme.modernGreen),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Explore by Category"),
        const SizedBox(height: 16),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final cat = categories[i];
            return Container(
              decoration: AppTheme.glassDecoration(
                opacity: 0.05,
                blur: 30,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cat.$3.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(cat.$2, color: cat.$3, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cat.$1,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentPlansList(BuildContext context, AppLocalizations l10n) {
    final cachedTrips = TripCacheService.getAllTrips();
    if (cachedTrips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.recentPlans),
        const SizedBox(height: 16),
        ...cachedTrips.take(3).map((trip) => _buildPlanCard(
          context, 
          trip.destination, 
          trip.humanText, 
          "${trip.itinerary.length} Days"
        )),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, String title, String desc, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.premiumShadow,
        border: Border.all(color: AppTheme.accentOchre.withOpacity(0.3), width: 1),
        image: const DecorationImage(
          image: NetworkImage("https://images.unsplash.com/photo-1546708973-b339540b5162?q=80&w=2670&auto=format&fit=crop"),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryBlue.withOpacity(0.2), AppTheme.primaryBlue.withOpacity(0.9)],
                stops: const [0.4, 1.0]
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _miniChip("MOST POPULAR", AppTheme.accentOchre),
                          const SizedBox(height: 6),
                          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                          Text(desc, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70), maxLines: 1),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: AppTheme.glassDecoration(opacity: 0.2),
                      child: Text(duration, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _glassActionIcon(IconData icon, VoidCallback onTap, {Color? iconColor}) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: AppTheme.glassDecoration(
        opacity: Theme.of(context).brightness == Brightness.light ? 0.8 : 0.2, 
        radius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppLocalizations l10n) {
    return BottomAppBar(
      color: Colors.transparent,
      elevation: 0,
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: 70, // Increased height for better label visibility
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: AppTheme.glassDecoration(
          opacity: Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.4,
          blur: 30, // Increased blur for premium feel
          isDark: Theme.of(context).brightness == Brightness.dark,
        ).copyWith(
          border: Border(
            top: BorderSide(color: AppTheme.sigiriyaOchre.withOpacity(0.2), width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(l10n.home, Icons.home_rounded, 0, onTap: () {
              setState(() => _selectedIndex = 0);
            }),
            _navItem("Explore", Icons.travel_explore_rounded, 1, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscoveryScreen()));
            }),
            const SizedBox(width: 48), // FAB Notch Space
            _navItem("Events", Icons.calendar_month_rounded, 2, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EventCalendarScreen()));
            }),
            _navItem(l10n.profile, Icons.person_rounded, 3, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String label, IconData icon, int index, {VoidCallback? onTap}) {
    final bool active = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
        if (onTap != null) onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.sigiriyaOchre.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                color: active ? AppTheme.sigiriyaOchre : Colors.grey[500],
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: active ? AppTheme.sigiriyaOchre : Colors.grey[500],
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                letterSpacing: active ? 0.5 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalGemsScroller(BuildContext context) {
    // Basic extraction from our local KB for offline access
    final gems = [
      ("Pahanthudawa", "Ratnapura", "4.8"),
      ("Narangala", "Badulla", "4.9"),
      ("Sera Ella", "Matale", "4.7"),
      ("Mandaramnuwara", "N. Eliya", "4.9"),
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: gems.length,
        itemBuilder: (context, i) {
          final gem = gems[i];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.accentOchre),
                    Text(gem.$3, style: AppTheme.labelStyle(context)),
                  ],
                ),
                const Spacer(),
                Text(gem.$1, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color), maxLines: 1),
                Text(gem.$2, style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          );
        },
      ),
    );
  }
}
