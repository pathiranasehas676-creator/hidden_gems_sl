import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/datasources/auth_service.dart';
import '../widgets/batik_background.dart';
import '../widgets/dynamic_light_wrapper.dart';
import 'scanner_screen.dart';
import 'saved_plans_screen.dart';
import 'trip_form_screen.dart';
import 'discovery_screen.dart';
import 'profile_screen.dart';
import '../admin/admin_shell.dart';

class HomeScreen extends StatefulWidget {
  final bool isOffline;
  const HomeScreen({super.key, this.isOffline = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // For bottom navigation

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOffline = widget.isOffline;
    return Scaffold(
      backgroundColor: AppTheme.silkPearl,
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
                            const SizedBox(height: 32),
                            if (isOffline) ...[
                              _buildSectionHeader("Local Gems (Offline)"),
                              const SizedBox(height: 16),
                              _buildLocalGemsScroller(),
                              const SizedBox(height: 32),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TripFormScreen()),
          );
        },
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.auto_awesome, color: AppTheme.accentOchre),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
      backgroundColor: AppTheme.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder for generated hero image
            Image.network(
              "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=2078&auto=format&fit=crop",
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.6),
                    Colors.transparent,
                    AppTheme.primaryBlue.withOpacity(0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: 20,
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  children: [
                    const TextSpan(text: "TripMe", style: TextStyle(color: Colors.white)),
                    const TextSpan(text: ".ai", style: TextStyle(color: AppTheme.accentOchre)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(user.photoURL ?? "https://ui-avatars.com/api/?name=${user.displayName}"),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _glassActionIcon(Icons.bookmark_border_rounded, () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlansScreen()));
          }),
        ),
        _glassActionIcon(Icons.camera_enhance_outlined, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
        }),
        _glassActionIcon(Icons.shield_outlined, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminShell()));
        }),
        _glassActionIcon(Icons.person_outline, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
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
            decoration: BoxDecoration(
              color: AppTheme.silkPearl.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.accentOchre.withOpacity(0.5), width: 1.5),
              boxShadow: AppTheme.premiumShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.accentOchre, Colors.orangeAccent],
                  ).createShader(bounds),
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
                    color: AppTheme.primaryBlue,
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
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      ("Nature", Icons.forest_outlined, const [Color(0xFF2E7D5B), Color(0xFF1B5E20)]),
      ("Culture", Icons.temple_hindu_outlined, const [Color(0xFFE2725B), Color(0xFFC62828)]),
      ("Luxury", Icons.diamond_outlined, const [AppTheme.accentOchre, Color(0xFFF57F17)]),
      ("Budget", Icons.wallet_outlined, const [Color(0xFF1565C0), Color(0xFF0D47A1)]),
      ("Adventure", Icons.explore_outlined, const [Color(0xFF8E24AA), Color(0xFF4A148C)]),
    ];

    return SizedBox(
      height: 120,
      child: AnimationLimiter(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final cat = categories[i];
            return AnimationConfiguration.staggeredList(
              position: i,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                horizontalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 80,
                    child: Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(20),
                            splashColor: Colors.white24,
                            child: Ink(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: cat.$3, begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: cat.$3[0].withOpacity(0.4), blurRadius: 12, spreadRadius: 0, offset: const Offset(0, 6))
                                ],
                              ),
                              child: Icon(cat.$2, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(cat.$1, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
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
                colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.8)],
                stops: const [0.5, 1.0]
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
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white30),
                      ),
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
      ),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _glassActionIcon(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: AppTheme.glassDecoration(opacity: 0.2, radius: BorderRadius.circular(12)),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, AppLocalizations l10n) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(l10n.home, Icons.home_rounded, 0, onTap: () {
              setState(() => _selectedIndex = 0);
            }),
            _navItem(l10n.discovery, Icons.travel_explore_rounded, -1, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscoveryScreen()));
            }),
            const SizedBox(width: 40),
            _navItem("Saved", Icons.bookmark_border, -1, onTap: () {}),
            _navItem(l10n.profile, Icons.person_rounded, 1, onTap: () {
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
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppTheme.primaryBlue : Colors.grey.shade400, size: 24),
          Text(label, style: TextStyle(
            color: active ? AppTheme.primaryBlue : Colors.grey.shade400,
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          )),
        ],
      ),
    );
  }

  Widget _buildLocalGemsScroller() {
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
              color: Colors.white,
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
                    Text(gem.$3, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                Text(gem.$1, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1),
                Text(gem.$2, style: GoogleFonts.inter(fontSize: 10, color: Colors.black54)),
              ],
            ),
          );
        },
      ),
    );
  }
}
