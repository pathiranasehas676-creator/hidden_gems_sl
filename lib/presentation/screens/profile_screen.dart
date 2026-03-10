import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/premium_service.dart';
import '../../data/datasources/trip_cache_service.dart';
import '../widgets/batik_background.dart';
import '../widgets/skeleton_loaders.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import 'emergency_kit_screen.dart';
import 'event_calendar_screen.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/screenshot_provider.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late var profile = UserPreferenceService.getProfile();
  // Events hub relocated.

  void _showLanguagePicker(BuildContext context) {
    final languages = [
      {'name': 'English', 'code': 'en', 'flag': '🇺🇸'},
      {'name': 'සිංහල', 'code': 'si', 'flag': '🇱🇰'},
      {'name': 'தமிழ்', 'code': 'ta', 'flag': '🇱🇰'},
      {'name': '日本語', 'code': 'ja', 'flag': '🇯🇵'},
      {'name': 'Русский', 'code': 'ru', 'flag': '🇷🇺'},
      {'name': '한국어', 'code': 'ko', 'flag': '🇰🇷'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.selectLanguage,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  return ListTile(
                    leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      lang['name']!,
                      style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    onTap: () {
                      context.read<LocaleProvider>().setLocale(Locale(lang['code']!));
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(AppLocalizations l10n) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.uploadPhoto, style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(Icons.camera_alt_outlined, l10n.camera, ImageSource.camera),
                _photoOption(Icons.photo_library_outlined, l10n.gallery, ImageSource.gallery),
              ],
            ),
            if (profile.profileImagePath != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                label: Text(l10n.removePhoto, style: const TextStyle(color: Colors.redAccent)),
                onPressed: () async {
                  await UserPreferenceService.updateProfileImagePath(null);
                  if (!context.mounted) return;
                  setState(() => profile = UserPreferenceService.getProfile());
                  Navigator.pop(context);
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await picker.pickImage(source: source, maxWidth: 800);
      if (image != null) {
        await UserPreferenceService.updateProfileImagePath(image.path);
        if (mounted) setState(() => profile = UserPreferenceService.getProfile());
      }
    }
  }

  Widget _photoOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.1), 
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premiumService = context.watch<PremiumService>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent, // Let Batik ocean gradient show
      body: BatikBackground(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(premiumService.isPremium, l10n),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settings,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 32),
                    _buildThemeModeToggle(),
                    const SizedBox(height: 32),
                    _buildVibeSelector(),

                    const SizedBox(height: 40),
                    _buildSettingsSection(l10n),
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

  Widget _buildAppBar(bool isPremium, AppLocalizations l10n) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            // Dark Overlay Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    AppTheme.primaryBlue,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            
            // Profile Image with Gold Ring
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => _pickImage(l10n),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing Green Aura Ring
                      _GlowingProfileRing(
                        child: Hero(
                          tag: 'profile_pic',
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: const BoxDecoration(shape: BoxShape.circle),
                            child: ClipOval(
                              child: profile.profileImagePath != null
                                  ? Image.file(
                                      File(profile.profileImagePath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => 
                                        _defaultAvatar(isPremium),
                                    )
                                  : _defaultAvatar(isPremium),
                            ),
                          ),
                        ),
                      ),
                      // Camera Icon Badge
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.modernGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryBlue, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isPremium ? "Premium Traveler" : "Oracle Traveler",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Level 1 Oracle Initiate",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.sigiriyaOchre,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(bool isPremium) {
    return Container(
      color: Theme.of(context).dividerColor.withOpacity(0.1),
      child: Icon(
        isPremium ? Icons.stars : Icons.person,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        size: 50,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: AppTheme.glassDecoration(
        opacity: 0.08,
        blur: 20,
        isDark: true,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(profile.totalTripsGenerated.toString(), "Trips"),
          _verticalDivider(),
          _statItem(profile.visitedPlaces.length.toString(), "Places"),
          _verticalDivider(),
          _statItem("1", "Oracle Lvl"),
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
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(height: 30, width: 1, color: Theme.of(context).dividerColor.withOpacity(0.2));
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
            color: Theme.of(context).colorScheme.onSurface,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: AppTheme.glassDecoration(
          opacity: Theme.of(context).brightness == Brightness.dark ? (isSelected ? 0.15 : 0.05) : 0.6,
          blur: 30,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ).copyWith(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppTheme.sigiriyaOchre.withOpacity(0.8) : Colors.white.withOpacity(0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          v.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }




  // ── Dark/Light Mode Toggle ────────────────────────────────────────────────
  Widget _buildThemeModeToggle() {
    final modeProvider = context.watch<AppModeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("APPEARANCE STYLE", style: AppTheme.labelStyle(context)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: AppTheme.glassDecoration(
            opacity: 0.05,
            isDark: isDark,
          ),
          child: Row(
            children: [
              Expanded(
                child: _modeOption(
                  "ZEN LIGHT",
                  Icons.wb_sunny_outlined,
                  modeProvider.currentMode == ThemeMode.light,
                  () => modeProvider.setMode(ThemeMode.light),
                ),
              ),
              Expanded(
                child: _modeOption(
                  "MIDNIGHT",
                  Icons.nightlight_round_outlined,
                  modeProvider.currentMode == ThemeMode.dark,
                  () => modeProvider.setMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeOption(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isSelected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? theme.colorScheme.onSurface 
                    : theme.colorScheme.onSurface.withOpacity(0.4),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(AppLocalizations l10n) {
    return Column(
      children: [
        _settingsTile(
          Icons.photo_camera_outlined, 
          l10n.uploadPhoto,
          onTap: () => _pickImage(l10n),
        ),
        _settingsTile(
          Icons.camera_alt_outlined, 
          "Screenshot Utility",
          trailing: Switch(
            value: context.watch<ScreenshotProvider>().isVisible,
            onChanged: (val) => context.read<ScreenshotProvider>().toggleVisibility(val),
            activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        _settingsTile(Icons.notifications_active_outlined, "Notifications"),
        _settingsTile(
          Icons.language_outlined, 
          l10n.language,
          onTap: () => _showLanguagePicker(context),
        ),
        _settingsTile(
          Icons.emergency_outlined,
          "Emergency Kit",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmergencyKitScreen()),
          ),
        ),
        _settingsTile(Icons.privacy_tip_outlined, "Privacy Policy"),
        _settingsTile(Icons.help_outline_rounded, "Support Center"),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, {VoidCallback? onTap, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassDecoration(
        opacity: 0.05,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        onTap: onTap ?? () {},
      ),
    );
  }
}

class _GlowingProfileRing extends StatefulWidget {
  final Widget child;
  const _GlowingProfileRing({required this.child});

  @override
  State<_GlowingProfileRing> createState() => _GlowingProfileRingState();
}

class _GlowingProfileRingState extends State<_GlowingProfileRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Replicates a smooth, infinite "Smart Animate" style pulse from Figma
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 114 + (_controller.value * 12), // Subtle pulsing expansion
          height: 114 + (_controller.value * 12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.modernGreen.withOpacity(0.3 + (_controller.value * 0.5)),
              width: 1.5 + (_controller.value * 2.0),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.modernGreen.withOpacity(0.1 + (_controller.value * 0.3)),
                blurRadius: 15 + (_controller.value * 20),
                spreadRadius: 2 + (_controller.value * 8),
              )
            ],
          ),
          child: Center(child: widget.child),
        );
      },
    );
  }
}
