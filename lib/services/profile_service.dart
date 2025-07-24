import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/api_helper.dart';

/// A helper class to handle all communication with the back-end API.
class ProfileService {
  static const _profileKey = 'dietary_profile_text';

  /// NEW: Sends profile text to the AI for review and returns its feedback.
  static Future<String> reviewProfile(String profileText) async {
    // We reuse the _analyze method but expect a different response structure.
    // The key 'review_text' tells our cloud function which prompt to use.
    final responseBody = await ApiHelper.analyzeRaw({'review_text': profileText});
    // The AI's response for a review is expected to be a simple JSON with a 'summary' key.
    return responseBody['summary'] ?? 'AI could not provide a summary.';
  }

  /// Saves the user's dietary profile string to local storage.
  static Future<void> saveProfile(String profileText) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profileText);
  }

  /// Loads the user's dietary profile string from local storage.
  ///
  /// Returns an empty string if no profile is saved.
  static Future<String> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileKey) ?? '';
  }
}