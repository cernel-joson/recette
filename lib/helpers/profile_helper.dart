import 'package:shared_preferences/shared_preferences.dart';

/// A helper class to manage saving and loading the user's dietary profile.
class ProfileHelper {
  static const _profileKey = 'dietary_profile_text';

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