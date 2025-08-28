import 'package:flutter/foundation.dart';
import 'package:recette/core/services/database_helper.dart';
import 'package:recette/core/utils/utils.dart';
import 'package:recette/core/services/api_helper.dart'; // Assuming you have an ApiHelper for the actual API call
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/features/dietary_profile/data/models/models.dart'; // Import the profile model
import 'package:recette/features/dietary_profile/data/services/services.dart';

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
    // --- THIS IS THE FIX ---
    // Make the parsing logic defensive against incorrect types from the AI.
    final suggestionsData = json['suggestions'];
    List<String> suggestionsList = [];

    if (suggestionsData is List) {
      // If it's a list, convert it as expected.
      suggestionsList = suggestionsData.map((item) => item.toString()).toList();
    } else if (suggestionsData is String) {
      // Failsafe: if the AI returns a single string, split it by commas
      // or just wrap it in a list to prevent a crash.
      suggestionsList = [suggestionsData];
    }

    return HealthAnalysisResult(
      rating: json['health_rating'] ?? 'UNKNOWN',
      summary: json['summary'] ?? 'No summary provided.',
      suggestions: suggestionsList, // Use the safely parsed list
    );
  }
}

// A dedicated service to handle the logic for recipe health analysis,
// incorporating the caching mechanism.
class HealthCheckService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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
  /// Returns a Map containing the 'rating' and 'summary'.// --- THIS PUBLIC METHOD STAYS, BUT WILL BE SIMPLIFIED ---
  Future<HealthAnalysisResult> getHealthAnalysisForRecipe(Recipe recipe) async {
    final currentProfile = await ProfileService.loadProfile();
    // It now calls the static, reusable logic
    return _getOrFetchHealthAnalysis(recipe, currentProfile);
  }

  // --- NEW: STATIC, REUSABLE LOGIC ---

  /// Checks if a recipe's cached health data is valid against a given profile.
  static bool isHealthCacheValid(Recipe recipe, DietaryProfile profile) {
    final currentProfileFingerprint = FingerprintHelper.generate(profile);
    final currentRecipeFingerprint = FingerprintHelper.generate(recipe);

    return recipe.healthRating != null &&
        recipe.dietaryProfileFingerprint == currentProfileFingerprint &&
        recipe.fingerprint == currentRecipeFingerprint;
  }

  /// The core logic, now extracted. It returns the analysis but DOES NOT make an API call if the cache is valid.
  static Future<HealthAnalysisResult?> getCachedAnalysis(Recipe recipe, DietaryProfile profile) async {
    if (isHealthCacheValid(recipe, profile)) {
      debugPrint("CACHE HIT for Recipe ID ${recipe.id}! Using stored health rating.");
      return HealthAnalysisResult(
        rating: recipe.healthRating!,
        summary: recipe.healthSummary ?? 'No summary available.',
        suggestions: recipe.healthSuggestions ?? [],
      );
    }
    return null; // Return null on a cache miss
  }

  /// A private, static version of the original method.
  static Future<HealthAnalysisResult> _getOrFetchHealthAnalysis(Recipe recipe, DietaryProfile profile) async {
    final cachedResult = await getCachedAnalysis(recipe, profile);
    if (cachedResult != null) return cachedResult;

    // On a cache miss, this makes a standalone API call.
    debugPrint("CACHE MISS for Recipe ID ${recipe.id}. Fetching new rating from API.");
    final body = {
      // --- THIS IS THE FIX ---
      // Use the correct key for the backend router.
      'recipe_analysis_request': {
        'tasks': ['healthCheck'],
        'recipe_data': recipe.toMap(), // Send the single recipe map
        'dietary_profile': profile.fullProfileText,
      }
    };
    final responseBody = await ApiHelper.analyzeRaw(body, model: AiModel.flash);
    
    final aiResult = responseBody['result'];
    final resultData = aiResult['health_analysis'];
    
    return HealthAnalysisResult.fromJson(resultData);
  }
}