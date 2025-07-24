import 'package:shared_preferences/shared_preferences.dart';
import '../models/recipe_model.dart';
import '../helpers/database_helper.dart';
import '../helpers/fingerprint_generator.dart';
import '../helpers/api_helper.dart'; // Assuming you have an ApiHelper for the actual API call
import '../helpers/profile_helper.dart'; // Import profile helper

/// A data class to hold the result of a health analysis.
class HealthAnalysisResult {
  final String rating; // e.g., "GREEN", "YELLOW", "RED"
  final String summary;
  final List<String> suggestions;

  HealthAnalysisResult({
    required this.rating,
    required this.summary,
    required this.suggestions,
  });

  factory HealthAnalysisResult.fromJson(Map<String, dynamic> json) {
    return HealthAnalysisResult(
      rating: json['health_rating'] ?? 'UNKNOWN',
      summary: json['summary'] ?? 'No summary provided.',
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}

// A dedicated service to handle the logic for recipe health analysis,
// incorporating the caching mechanism.
class HealthCheckService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // The key used to store and retrieve the dietary profile from SharedPreferences.
  static const String dietaryProfileKey = 'dietary_profile_text';

  /// Gets the health analysis for a given recipe, using a cache-aware strategy.
  ///
  /// This function orchestrates the entire "Calculate, then Cache" logic:
  /// 1. Retrieves the user's current dietary profile.
  /// 2. Generates a "fingerprint" of that profile.
  /// 3. Checks if the recipe has a cached rating with a matching fingerprint.
  /// 4. If the cache is valid (a "hit"), it returns the stored data instantly.
  /// 5. If the cache is invalid (a "miss"), it triggers a new API call.
  /// 6. After the API call, it saves the new analysis and fingerprint to the
  ///    database for future use.
  ///
  /// [recipe] The recipe to be analyzed.
  /// Returns a Map containing the 'rating' and 'summary'.
  Future<HealthAnalysisResult> getHealthAnalysisForRecipe(Recipe recipe) async {
    // 1. Load the user's current dietary profile text.
    final currentProfileText = await ProfileHelper.loadProfile();

    // If the user has no profile set, we can't provide a rating.
    if (currentProfileText.isEmpty) {
      return HealthAnalysisResult.fromJson({
        'health_rating': 'UNRATED',
        'summary': 'Please set your dietary profile to get a health rating.',
        'suggestions': '',
      });
    }

    // 2. Generate the fingerprint for the current profile.
    final currentFingerprint = generateProfileFingerprint(currentProfileText);

    // 3. Check if the cached data is valid (Cache Hit).
    // A valid cache requires a non-null rating AND a matching fingerprint.
    if (recipe.healthRating != null &&
        recipe.dietaryProfileFingerprint == currentFingerprint) {
      print("CACHE HIT for Recipe ID ${recipe.id}! Using stored health rating.");
      
      return HealthAnalysisResult.fromJson({
        'health_rating': recipe.healthRating!,
        'summary': recipe.healthSummary ?? 'No summary available.',
        'suggestions': recipe.healthSuggestions ?? [],
      });
    }

    // 4. If we reach here, it's a Cache Miss.
    print("CACHE MISS for Recipe ID ${recipe.id}. Fetching new rating from API.");

    // 5. Make the actual API call to get a fresh analysis.
    // This is where you call your existing Gemini API logic.
    final newAnalysis =
        await getHealthAnalysis(
          profileText: currentProfileText,
          recipe: recipe,
        );

    // 6. Save the new analysis and fingerprint back to the database.
    // We create a new Recipe object with the updated info to save it.
    final updatedRecipe = recipe
      ..healthRating = newAnalysis.rating
      ..healthSummary = newAnalysis.summary
      ..healthSuggestions = newAnalysis.suggestions
      ..dietaryProfileFingerprint = currentFingerprint;

    await _dbHelper.update(updatedRecipe);
    print("Updated cache for Recipe ID ${recipe.id} with new analysis.");

    return newAnalysis;
  }

  // Helper method to save the dietary profile, for use in the settings screen.
  Future<void> saveDietaryProfile(String profileText) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(dietaryProfileKey, profileText);
  }

  /// NEW: Sends a recipe and profile to the AI for a health analysis.
  static Future<HealthAnalysisResult> getHealthAnalysis({
    required String profileText,
    required Recipe recipe,
  }) async {
    final body = {
      'health_check': true, // The new key to trigger the right logic
      'dietary_profile': profileText,
      'recipe_data': recipe.toMap(), // Send the full recipe data
    };

    final responseBody = await ApiHelper.analyzeRaw(body);
    return HealthAnalysisResult.fromJson(responseBody);
  }
}