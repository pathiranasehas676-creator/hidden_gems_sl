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
import '../../data/models/event_model.dart';
import '../widgets/batik_background.dart';
import '../widgets/skeleton_loaders.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import '../../core/providers/locale_provider.dart';
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
  List<EventModel> _interestedEvents = [];
  bool _isLoadingEvents = true;

  @override
  void initState() {
    super.initState();
    _loadInterestedEvents();
  }

  Future<void> _loadInterestedEvents() async {
    setState(() => _isLoadingEvents = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final rawEvents = TripCacheService.getInterestedEvents();
    setState(() {
      _interestedEvents = rawEvents.map((e) => EventModel.fromJson(json.decode(e))).toList();
      _isLoadingEvents = false;
    });
  }

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
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1), 
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
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
                    _buildMyEventsHub(),
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
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        background: Stack(
          alignment: Alignment.center,
          children: [
            if (isPremium)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              )
            else
              Container(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
            
            // Profile Image with Glow
            GestureDetector(
              onTap: () => _pickImage(l10n),
              child: Hero(
                tag: 'profile_pic',
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isPremium ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                    border: Border.all(
                      color: isPremium ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
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
            
            // Edit Overlay Icon
            Positioned(
              right: MediaQuery.of(context).size.width / 2 - 55,
              bottom: 60,
              child: GestureDetector(
                onTap: () => _pickImage(l10n),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).cardColor, width: 2),
                  ),
                  child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.onPrimary, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(bool isPremium) {
    return Container(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      child: Icon(
        isPremium ? Icons.stars : Icons.person,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        size: 50,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -20, left: 20,
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentOchre.withValues(alpha: 0.3)),
          ),
        ),
        Positioned(
          bottom: -20, right: 20,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryBlue.withValues(alpha: 0.8)),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration(opacity: 0.08),
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
            ),
          ),
        ),
      ],
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(height: 30, width: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2));
  }

  Widget _buildMyEventsHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "MY INTERESTED EVENTS",
              style: AppTheme.labelStyle,
            ),
            if (_interestedEvents.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventCalendarScreen()),
                ),
                child: Text(
                  "VIEW CALENDAR",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sigiriyaOchre,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingEvents)
          _buildHubShimmer()
        else if (_interestedEvents.isEmpty)
          _buildEmptyEventsState()
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _interestedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _buildMiniEventCard(_interestedEvents[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHubShimmer() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: ModernTracerShimmer(
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEventsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.glassDecoration(opacity: 0.05),
      child: Column(
        children: [
          Icon(Icons.event_available_outlined, color: Colors.white.withValues(alpha: 0.2), size: 40),
          const SizedBox(height: 12),
          Text(
            "No events pinned yet",
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventCalendarScreen()),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.sigiriyaOchre.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "EXPLORE EVENTS",
              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.sigiriyaOchre),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniEventCard(EventModel event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EventCalendarScreen()),
      ),
      child: Container(
        width: 150,
        decoration: AppTheme.glassDecoration(opacity: 0.1).copyWith(
          border: Border.all(color: event.categoryColor.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: event.categoryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.category.name.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: event.categoryColor),
              ),
            ),
            const Spacer(),
            Text(
              event.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 10, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  event.date ?? "SOON",
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          v.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
        Text("APPEARANCE STYLE", style: AppTheme.labelStyle),
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
              ? theme.colorScheme.primary.withValues(alpha: 0.15) 
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
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? theme.colorScheme.onSurface 
                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
            activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        onTap: onTap ?? () {},
      ),
    );
  }
}
