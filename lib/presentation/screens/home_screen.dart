import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../../data/datasources/auth_service.dart';
import '../widgets/batik_background.dart';
import '../widgets/dynamic_light_wrapper.dart';
import 'scanner_screen.dart';
import 'saved_plans_screen.dart';
import 'trip_form_screen.dart';
import 'profile_screen.dart';
import '../admin/admin_shell.dart';

class HomeScreen extends StatelessWidget {
  final bool isOffline;
  const HomeScreen({super.key, this.isOffline = false});

  @override
  Widget build(BuildContext context) {
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
                            _buildSectionHeader("Oracle's Choice"),
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
                    child: _buildRecentPlansList(context),
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
      bottomNavigationBar: _buildBottomNav(context),
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
    final user = isOffline ? null : FirebaseAuth.instance.currentUser;
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
    final user = isOffline ? null : FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(" ").first ?? "Traveler";

    return DynamicLightWrapper(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration(opacity: 0.9).copyWith(
          boxShadow: AppTheme.premiumShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ayubowan, $name!".toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.accentOchre,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
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
      ("Nature", Icons.forest_outlined),
      ("Culture", Icons.temple_hindu_outlined),
      ("Luxury", Icons.diamond_outlined),
      ("Budget", Icons.wallet_outlined),
      ("Adventure", Icons.explore_outlined),
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, i) {
          final cat = categories[i];
          return Container(
            margin: const EdgeInsets.only(right: 16),
            width: 80,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Icon(cat.$2, color: AppTheme.primaryBlue, size: 24),
                ),
                const SizedBox(height: 8),
                Text(cat.$1, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentPlansList(BuildContext context) {
    return Column(
      children: [
        _buildPlanCard(context, "Cloud-Kissed Ella", "Photographer's Golden Hour Dream", "3 Days"),
        _buildPlanCard(context, "Sigiriya Whispers", "Ancestral Majesty in the Jungle", "2 Days"),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, String title, String desc, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage("https://images.unsplash.com/photo-1546708973-b339540b5162?q=80&w=2670&auto=format&fit=crop"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _miniChip("MOST POPULAR", AppTheme.accentOchre),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(desc, style: GoogleFonts.inter(fontSize: 13, color: Colors.black54), maxLines: 1),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(duration, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.accentOchre)),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            )
          ],
        ),
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

  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      color: Colors.white,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(Icons.explore_outlined, "Explore", true),
            _navIcon(Icons.map_outlined, "Plan", false, onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const TripFormScreen()));
            }),
            const SizedBox(width: 40),
            _navIcon(Icons.bookmark_border, "Saved", false, onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlansScreen()));
            }),
            _navIcon(Icons.person_outline, "Profile", false, onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, String label, bool active, {VoidCallback? onTap}) {
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
