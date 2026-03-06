import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';

class UserPreferenceService {
  static const String _profileKey = 'current_profile';
  static const _secureStorage = FlutterSecureStorage();

  static Future<void> init() async {
    // Hive is still used for other non-sensitive caching if any,
    // but we'll move the core profile to SecureStorage.
  }

  // Auth Tokens
  static Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  static Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  static Future<UserProfile> loadProfile() async {
    final raw = await _secureStorage.read(key: _profileKey);
    if (raw == null) return UserProfile.defaultProfile();
    try {
      return UserProfile.fromJson(json.decode(raw));
    } catch (_) {
      return UserProfile.defaultProfile();
    }
  }

  // For synchronous access (like from UI builders), we might still need a cached version.
  static UserProfile? _cachedProfile;

  static UserProfile getProfile() {
    return _cachedProfile ?? UserProfile.defaultProfile();
  }

  static Future<void> saveProfile(UserProfile profile) async {
    _cachedProfile = profile;
    await _secureStorage.write(key: _profileKey, value: json.encode(profile.toJson()));
  }

  static Future<void> ensureProfileLoaded() async {
    _cachedProfile = await loadProfile();
  }

  static Future<void> updateVibe(String vibe) async {
    final profile = getProfile();
    profile.vibe = vibe;
    await saveProfile(profile);
  }

  static Future<void> addTrip() async {
    final profile = getProfile();
    profile.totalTripsGenerated++;
    await saveProfile(profile);
  }

  static Future<void> addVisitedPlace(String place) async {
    final profile = getProfile();
    if (!profile.visitedPlaces.contains(place)) {
      profile.visitedPlaces.add(place);
      await saveProfile(profile);
    }
  }

  static Future<void> updateLanguage(String languageCode) async {
    final profile = getProfile();
    profile.languageCode = languageCode;
    await saveProfile(profile);
  }

  static Future<void> updateProfileImagePath(String? path) async {
    final profile = getProfile();
    profile.profileImagePath = path;
    await saveProfile(profile);
  }

  static Future<void> updateVibeTheme(String themeId) async {
    final profile = getProfile();
    profile.vibeTheme = themeId;
    await saveProfile(profile);
  }

  static Future<void> updateThemeMode(String mode) async {
    final profile = getProfile();
    profile.themeMode = mode;
    await saveProfile(profile);
  }
}
