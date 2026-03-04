import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/premium_service.dart';
import '../widgets/batik_background.dart';

import 'package:hidden_gems_sl/l10n/app_localizations.dart';
import '../../core/localization/locale_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late var profile = UserPreferenceService.getProfile();
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAuth();
  }

  Future<void> _checkBiometricAuth() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Verify your identity to access User Details',
      );

      if (mounted) {
        if (didAuthenticate) {
          setState(() {
            _isAuthenticated = true;
            _isAuthenticating = false;
          });
        } else {
          // Authentication failed or canceled. Send them out of this screen gracefully
          setState(() => _isAuthenticating = false);
        }
      }
    } on PlatformException catch (_) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true; // Fallback to accessible if crash
          _isAuthenticating = false;
        });
      }
    }
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
      backgroundColor: const Color(0xFF1E293B),
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
                color: Colors.white,
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
                      style: GoogleFonts.inter(color: Colors.white),
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
      backgroundColor: AppTheme.primaryBlue,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.uploadPhoto, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
            decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticating) {
      return const Scaffold(
        backgroundColor: AppTheme.silkPearl,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.silkPearl,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: AppTheme.primaryBlue),
              const SizedBox(height: 20),
              Text(
                "Access Denied",
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkBiometricAuth,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOchre),
                child: Text("Retry Authentication", style: GoogleFonts.inter(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

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
                        color: Colors.white, // Pop against dark background
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatsRow(),
                    const SizedBox(height: 32),
                    _buildVibeSelector(),
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F2027), AppTheme.primaryBlue, AppTheme.accentOchre],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              )
            else
              Container(color: AppTheme.primaryBlue),
            
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
                        color: (isPremium ? AppTheme.accentOchre : Colors.white).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                    border: Border.all(
                      color: isPremium ? AppTheme.accentOchre : Colors.white,
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
                    color: AppTheme.accentOchre,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryBlue, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue, size: 16),
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
      color: Colors.white10,
      child: Icon(
        isPremium ? Icons.stars : Icons.person,
        color: Colors.white70,
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
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(height: 30, width: 1, color: Colors.white24);
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
            color: Colors.white,
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
          color: isSelected ? AppTheme.accentOchre : AppTheme.glassDecoration().color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentOchre : Colors.white24,
          ),
          boxShadow: isSelected ? AppTheme.premiumShadow : AppTheme.softShadow,
        ),
        child: Text(
          v.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.primaryBlue : Colors.white70,
            letterSpacing: 1,
          ),
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
        _settingsTile(Icons.notifications_active_outlined, "Notifications"),
        _settingsTile(
          Icons.language_outlined, 
          l10n.language,
          onTap: () => _showLanguagePicker(context),
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
            color: Colors.white10,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white54),
        onTap: onTap ?? () {},
      ),
    );
  }
}
