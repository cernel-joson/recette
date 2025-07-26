import '../models/recipe_model.dart';
import '../models/dietary_profile_model.dart'; // Import the profile model
import '../helpers/database_helper.dart';
import '../helpers/fingerprint_helper.dart'; // Import the generic helper
import '../helpers/api_helper.dart'; // Assuming you have an ApiHelper for the actual API call
import '../services/profile_service.dart';
import 'package:flutter/foundation.dart';

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
    // 1. Load the user's current dietary profile object.
    final currentProfile = await ProfileService.loadProfile();

    if (currentProfile.fullProfileText.isEmpty) {
      return HealthAnalysisResult(
        rating: 'UNRATED',
        summary: 'Please set your dietary profile to get a health rating.',
        suggestions: [],
      );
    }

    // 2. Generate fingerprints for BOTH the current profile and the recipe.
    final currentProfileFingerprint = FingerprintHelper.generate(currentProfile);
    final currentRecipeFingerprint = FingerprintHelper.generate(recipe);

    // 3. Check if the cached data is valid (Cache Hit).
    // A valid cache now requires THREE conditions to be met.
    final bool isCacheValid = recipe.healthRating != null &&
        recipe.dietaryProfileFingerprint == currentProfileFingerprint &&
        recipe.fingerprint == currentRecipeFingerprint;

    print("recipe.healthRating: ${recipe.healthRating}");
    print("${recipe.dietaryProfileFingerprint} == ${currentProfileFingerprint}?");
    print("${recipe.fingerprint} == ${currentRecipeFingerprint}?");

    if (isCacheValid) {
      print("CACHE HIT for Recipe ID ${recipe.id}! Using stored health rating.");
      return HealthAnalysisResult(
        rating: recipe.healthRating!,
        summary: recipe.healthSummary ?? 'No summary available.',
        suggestions: recipe.healthSuggestions ?? [],
      );
    }

    // 4. If we reach here, it's a Cache Miss.
    print("CACHE MISS for Recipe ID ${recipe.id}. Fetching new rating from API.");

    // 5. Make the actual API call to get a fresh analysis.
    final newAnalysis = await _fetchHealthAnalysisFromApi(
      profile: currentProfile,
      recipe: recipe,
    );

    // 6. Save the new analysis and BOTH fingerprints back to the database.
    final updatedRecipe = recipe.copyWith(
      healthRating: newAnalysis.rating,
      healthSummary: newAnalysis.summary,
      healthSuggestions: newAnalysis.suggestions,
      dietaryProfileFingerprint: currentProfileFingerprint,
      fingerprint: currentRecipeFingerprint,
    );

    // --- THIS IS THE FIX ---
    // The health check results must be saved to the database to update the cache.
    await _dbHelper.update(updatedRecipe);
    debugPrint("Updated cache for Recipe ID ${recipe.id} with new analysis.");

    return newAnalysis;
  }

  /// Private method to handle the API call logic.
  static Future<HealthAnalysisResult> _fetchHealthAnalysisFromApi({
    required DietaryProfile profile,
    required Recipe recipe,
  }) async {
    final body = {
      'health_check': true,
      'dietary_profile': profile.fullProfileText,
      'recipe_data': recipe.toMap(),
    };

    final responseBody = await ApiHelper.analyzeRaw(body);
    return HealthAnalysisResult.fromJson(responseBody);
  }
}