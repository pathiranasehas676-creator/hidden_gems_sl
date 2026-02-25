import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/premium_service.dart';
import '../widgets/batik_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late var profile = UserPreferenceService.getProfile();

  @override
  Widget build(BuildContext context) {
    final premiumService = Provider.of<PremiumService>(context);

    return Scaffold(
      backgroundColor: AppTheme.silkPearl,
      body: BatikBackground(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(premiumService.isPremium),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 32),
                    _buildVibeSelector(),
                    const SizedBox(height: 32),
                    _buildSettingsSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isPremium) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          "TRAVELER PROFILE",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        background: Stack(
          alignment: Alignment.center,
          children: [
            Container(color: AppTheme.primaryBlue),
            if (isPremium)
              const Icon(Icons.stars, color: AppTheme.accentOchre, size: 80)
            else
              const Icon(Icons.person_outline, color: Colors.white24, size: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration(opacity: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(profile.totalTripsGenerated.toString(), "TRIPS"),
          _verticalDivider(),
          _statItem(profile.visitedPlaces.length.toString(), "PLACES"),
          _verticalDivider(),
          _statItem("LVL 1", "RANK"),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(height: 30, width: 1, color: Colors.black12);
  }

  Widget _buildVibeSelector() {
    final vibes = ["explorer", "luxury", "photographer", "budget"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CHOOSE YOUR VIBE",
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: vibes.map((v) => _vibeChip(v)).toList(),
        ),
      ],
    );
  }

  Widget _vibeChip(String v) {
    final isSelected = profile.vibe == v;
    return GestureDetector(
      onTap: () async {
        await UserPreferenceService.updateVibe(v);
        setState(() {
          profile = UserPreferenceService.getProfile();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.black12,
          ),
          boxShadow: isSelected ? AppTheme.premiumShadow : AppTheme.softShadow,
        ),
        child: Text(
          v.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      children: [
        _settingsTile(Icons.notifications_active_outlined, "Notifications"),
        _settingsTile(Icons.language_outlined, "Language (English/Sinhala)"),
        _settingsTile(Icons.privacy_tip_outlined, "Privacy Policy"),
        _settingsTile(Icons.help_outline_rounded, "Support Center"),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue, size: 20),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () {},
      ),
    );
  }
}
