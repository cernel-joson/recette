// lib/features/dietary_profile/data/services/profile_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recette/features/dietary_profile/data/models/dietary_profile_model.dart';

class ProfileReview {
  final String suggestedRules;
  final String suggestedPreferences;

  ProfileReview({
    required this.suggestedRules,
    required this.suggestedPreferences,
  });

  factory ProfileReview.fromJson(Map<String, dynamic> json) {
    return ProfileReview(
      suggestedRules: json['suggested_rules'] ?? '',
      suggestedPreferences: json['suggested_preferences'] ?? '',
    );
  }
}

class ProfileService {
  static const _rulesKey = 'dietary_profile_rules';
  static const _preferencesKey = 'dietary_profile_preferences';

  static Future<void> saveProfile(DietaryProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rulesKey, profile.rules);
    await prefs.setString(_preferencesKey, profile.preferences);
  }

  static Future<DietaryProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return DietaryProfile(
      rules: prefs.getString(_rulesKey) ?? '',
      preferences: prefs.getString(_preferencesKey) ?? '',
    );
  }
}