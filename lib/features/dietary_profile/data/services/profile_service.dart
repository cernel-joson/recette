import 'package:shared_preferences/shared_preferences.dart';
import 'package:recette/core/services/api_helper.dart';
import 'package:recette/features/dietary_profile/data/models/dietary_profile_model.dart'; // Import the new model

/// A new data class to hold the structured review from the AI.
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

/// A service class to manage loading, saving, and interacting
/// with the user's dietary profile..
class ProfileService {
  static const _rulesKey = 'dietary_profile_rules';
  static const _preferencesKey = 'dietary_profile_preferences';

  /// UPDATED: Sends profile text to the AI and returns a structured [ProfileReview] object.
  static Future<ProfileReview> reviewProfile(DietaryProfile profile) async {
    final responseBody = await ApiHelper.analyzeRaw({
      'review_text': profile.fullProfileText,
    });
    return ProfileReview.fromJson(responseBody);
  }

  /// Saves the user's dietary profile to local storage.
  static Future<void> saveProfile(DietaryProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rulesKey, profile.rules);
    await prefs.setString(_preferencesKey, profile.preferences);
  }

  /// Loads the user's dietary profile from local storage.
  static Future<DietaryProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return DietaryProfile(
      rules: prefs.getString(_rulesKey) ?? '',
      preferences: prefs.getString(_preferencesKey) ?? '',
    );
  }
}