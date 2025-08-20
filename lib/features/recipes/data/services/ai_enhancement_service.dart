import 'package:recette/core/core.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/features/recipes/data/services/services.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';


// Enum to define the different kinds of analysis a user can request.
enum AiEnhancementTask {
  generateTags,
  healthCheck,
  estimateNutrition,
  findSimilar // The new task for our fuzzy matching
}

class AiEnhancementService {

  Future<Recipe> enhanceSingleRecipe({
    required Recipe recipe,
    required Set<AiEnhancementTask> tasks,
  }) async {
    final currentProfile = await ProfileService.loadProfile();
    Recipe recipeToUpdate = recipe;
    
    // 1. Check the HealthCheck cache first.
    HealthAnalysisResult? cachedHealthResult;
    if (tasks.contains(AiEnhancementTask.healthCheck)) {
      cachedHealthResult = await HealthCheckService.getCachedAnalysis(recipe, currentProfile);
    }

    // 2. Determine which tasks ACTUALLY need to be sent to the API.
    final tasksForApi = Set<AiEnhancementTask>.from(tasks);
    if (cachedHealthResult != null) {
      tasksForApi.remove(AiEnhancementTask.healthCheck);
    }

    // --- THIS IS THE FIX ---
    // 3. Declare the response variable here, outside the 'if' block, so it has a wider scope.
    Map<String, dynamic>? response;

    if (tasksForApi.isNotEmpty) {
      final requestBody = {
        'enhancement_request': {
          'tasks': tasksForApi.map((t) => t.toString().split('.').last).toList(),
          'recipe_data': [recipeToUpdate.toMap()],
          'dietary_profile': currentProfile.fullProfileText,
        }
      };

      // Assign the result to the response variable.
      // Safely cast the response
      response = await ApiHelper.analyzeRaw(requestBody, model: AiModel.pro) as Map<String, dynamic>?;

      // Add a null check before accessing the response data
      if (response != null && response['results'] is List && (response['results'] as List).isNotEmpty) {
          final resultData = response['results'][0];

          final tagsData = resultData['tags'];
          List<String> newTags = recipeToUpdate.tags; 

          if (tagsData is List) {
            newTags = tagsData.map((item) => item.toString()).toList();
          } else if (tagsData is String) {
            newTags = [tagsData];
          }

          // --- NEW: Parse Nutritional Info ---
          final nutritionData = resultData['nutritional_info'] as Map<String, dynamic>?;

          recipeToUpdate = recipeToUpdate.copyWith(
            tags: newTags,
            nutritionalInfo: nutritionData, // <-- Add to copyWith
          );
      }
    }

    // 4. Apply the health results and save.
    if (tasks.contains(AiEnhancementTask.healthCheck)) {
      // If we had a cache hit, use that. Otherwise, parse the result from the API response.
      HealthAnalysisResult healthAnalysis;

      // --- THIS IS THE FIX ---
      // If the health check was handled by the API (i.e., it was a cache miss),
      // then we parse the result from the API response.
      if (tasksForApi.contains(AiEnhancementTask.healthCheck)) {
        final healthData = response!['results'][0]['health_analysis'] as Map<String, dynamic>?;
        if (healthData == null) {
          // Handle cases where the API might fail to return the health part
          throw Exception('API response did not include health analysis as requested.');
        }
        healthAnalysis = HealthAnalysisResult.fromJson(healthData);
      } else {
        // Otherwise, we use the valid result we found in the cache.
        healthAnalysis = cachedHealthResult!;
      }

      final newProfileFingerprint = FingerprintHelper.generate(currentProfile);

      recipeToUpdate = recipeToUpdate.copyWith(
        healthRating: healthAnalysis.rating,
        healthSummary: healthAnalysis.summary,
        healthSuggestions: healthAnalysis.suggestions,
        dietaryProfileFingerprint: newProfileFingerprint,
      );
    }

    // 5. Save the final, fully updated recipe to the database ONCE.
    await DatabaseHelper.instance.update(recipeToUpdate);
    return recipeToUpdate;
  }

  /// The method for our fuzzy similarity matching feature.
  Future<List<int>> findSimilarRecipes({
    required Recipe newRecipe,
    required List<Recipe> candidates,
  }) async {
    final requestBody = {
      'enhancement_request': {
        'tasks': ['findSimilar'],
        'recipe_data': [newRecipe.toMap()], // The new recipe is the primary subject
        'candidate_recipes': candidates.map((r) => r.toMap()).toList(),
      }
    };
    
    final response = await ApiHelper.analyzeRaw(requestBody, model: AiModel.pro);
    
    // The response would be something like {"similar_recipe_ids": [12, 78]}
    return List<int>.from(response['similar_recipe_ids'] ?? []);
  }

  /// --- NEW METHOD FOR QUICK NUTRITIONAL ANALYSIS ---
  /// Takes a block of text and returns a map of nutritional info.
  Future<Map<String, dynamic>> getNutritionalAnalysisForText(String text) async {
    if (text.trim().isEmpty) return {};

    final requestBody = {
      'nutritional_estimation_request': {'text': text}
    };
    
    // Use the fast and cheap flash model for this simple task.
    final response = await ApiHelper.analyzeRaw(requestBody, model: AiModel.flash);

    if (response is Map<String, dynamic>) {
      return response;
    }
    
    // Return an empty map if the response is not in the expected format
    return {};
  }

  // Future method for bulk health checks would go here.
  /*Future<List<Recipe>> enhanceMultipleRecipes(...) async {
    // This would be similar to enhanceSingleRecipe but would handle
    // a list of recipes and a list of results.
  }*/
}