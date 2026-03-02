import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class UserPreferenceService {
  static const String _boxName = 'user_preference_box';
  static const String _profileKey = 'current_profile';

  static Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  static UserProfile getProfile() {
    final box = Hive.box<String>(_boxName);
    final raw = box.get(_profileKey);
    if (raw == null) return UserProfile.defaultProfile();
    try {
      return UserProfile.fromJson(json.decode(raw));
    } catch (_) {
      return UserProfile.defaultProfile();
    }
  }

  static Future<void> saveProfile(UserProfile profile) async {
    final box = Hive.box<String>(_boxName);
    await box.put(_profileKey, json.encode(profile.toJson()));
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
}
