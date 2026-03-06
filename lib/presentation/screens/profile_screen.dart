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
import '../widgets/batik_background.dart';
import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/datasources/live_events_service.dart';
import 'emergency_kit_screen.dart';
import '../../core/theme/vibe_theme_provider.dart';
import '../../core/theme/app_mode_provider.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late var profile = UserPreferenceService.getProfile();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = LiveEventsService.getEventsForTrip(_selectedDay!, 1);
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
                      context.read<LocaleProvider>().setLocale(lang['code']!);
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
            decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), shape: BoxShape.circle),
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
                    _buildThemePicker(),
                    const SizedBox(height: 32),
                    _buildThemeModeToggle(),
                    const SizedBox(height: 32),
                    _buildVibeSelector(),
                    const SizedBox(height: 32),
                    _buildCalendarSection(),
                    const SizedBox(height: 32),
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
              decoration: AppTheme.glassDecoration(),
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

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Sri Lanka Live Events",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.celebration, color: AppTheme.accentOchre, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: AppTheme.glassDecoration(opacity: 0.1, blur: 15).copyWith(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedEvents = LiveEventsService.getEventsForTrip(selectedDay, 1);
                  });
                },
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                headerStyle: HeaderStyle(
                  titleTextStyle: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
                  formatButtonVisible: false,
                  leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                  weekendStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.primary, fontSize: 12),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                  weekendTextStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                  outsideTextStyle: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 13),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: (day) {
                  return LiveEventsService.getEventsForTrip(day, 1);
                },
              ),
              if (_selectedEvents.isNotEmpty) ...[
                const Divider(color: Colors.white10, height: 1),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedEvents.length,
                  itemBuilder: (context, index) {
                    final ev = _selectedEvents[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(color: AppTheme.accentOchre.withValues(alpha: 0.2), shape: BoxShape.circle),
                         child: const Icon(Icons.star, color: AppTheme.accentOchre, size: 16),
                      ),
                      title: Text(
                        ev['name'] ?? 'Event',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          ev['description'] ?? '',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (_selectedEvents.isEmpty) ...[
                 const Divider(color: Colors.white10, height: 1),
                 Padding(
                   padding: const EdgeInsets.all(24.0),
                   child: Text("No major events on this date.", style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                 ),
              ]
            ],
          ),
        ),
      ],
    );
  }

  // ── Theme Picker ─────────────────────────────────────────────────────────
  Widget _buildThemePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.palette_outlined, color: AppTheme.sigiriyaOchre, size: 18),
            const SizedBox(width: 8),
            Text(
              'APP THEME',
              style: AppTheme.labelStyle,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: VibeThemes.all.length,
            itemBuilder: (context, i) {
              final theme = VibeThemes.all[i];
              final provider = context.watch<VibeThemeProvider>();
              final isActive = provider.current.id == theme.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.read<VibeThemeProvider>().setTheme(theme);
                  setState(() {
                    profile = UserPreferenceService.getProfile();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: theme.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? theme.accent
                          : Colors.white12,
                      width: isActive ? 2 : 1,
                    ),
                    boxShadow: isActive
                        ? [BoxShadow(color: theme.accent.withValues(alpha: 0.4), blurRadius: 12)]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(theme.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        theme.name.split(' ').first,
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isActive)
                        const Icon(Icons.check_circle, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Dark/Light Mode Toggle ────────────────────────────────────────────────
  Widget _buildThemeModeToggle() {
    final modeProvider = context.watch<AppModeProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.brightness_medium_outlined, color: AppTheme.sigiriyaOchre, size: 18),
            const SizedBox(width: 8),
            Text(
              'APPEARANCE',
              style: AppTheme.labelStyle,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light', style: TextStyle(fontSize: 13)),
                icon: Icon(Icons.light_mode_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System', style: TextStyle(fontSize: 13)),
                icon: Icon(Icons.settings_suggest_outlined, size: 18),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark', style: TextStyle(fontSize: 13)),
                icon: Icon(Icons.dark_mode_outlined, size: 18),
              ),
            ],
            selected: {modeProvider.currentMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              HapticFeedback.lightImpact();
              modeProvider.setThemeMode(newSelection.first);
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.transparent,
              selectedBackgroundColor: Theme.of(context).colorScheme.primary,
              selectedForegroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
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

  Widget _settingsTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassDecoration(),
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
        trailing: Icon(Icons.chevron_right, size: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        onTap: onTap ?? () {},
      ),
    );
  }
}
