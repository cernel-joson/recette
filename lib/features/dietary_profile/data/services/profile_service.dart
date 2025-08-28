// lib/features/dietary_profile/data/services/profile_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recette/features/dietary_profile/data/models/dietary_profile_model.dart';

class ProfileService {
  static const _profileKey = 'dietary_profile_markdown';

  static Future<void> saveProfile(DietaryProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profile.markdownText);
  }

  static Future<DietaryProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return DietaryProfile(
      markdownText: prefs.getString(_profileKey) ?? '',
    );
  }

  static Future<DietaryProfile> getProfile() async {
    return loadProfile();
  }

  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}