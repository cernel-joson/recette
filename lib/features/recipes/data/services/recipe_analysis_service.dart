import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:recette/core/core.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/features/dietary_profile/data/models/dietary_profile_model.dart';

// Enum to define the different kinds of analysis a user can request.
enum RecipeAnalysisTask {
  generateTags,
  healthCheck,
  estimateNutrition,
}

class RecipeAnalysisService {
  final JobManager _jobManager;

  RecipeAnalysisService(this._jobManager);
  
  Future<bool> runAnalysisTasks({
    required Recipe recipe,
    required Set<RecipeAnalysisTask> tasks,
  }) async {
    if (tasks.isEmpty) return false;

    final profile = await ProfileService.loadProfile();
    final tasksToRun = Set<RecipeAnalysisTask>.from(tasks);

    // --- RE-IMPLEMENTED CACHING LOGIC ---
    if (tasks.contains(RecipeAnalysisTask.healthCheck)) {
      if (_isHealthCacheValid(recipe, profile)) {
        debugPrint("CACHE HIT for Health Check on Recipe ID ${recipe.id}. Skipping task.");
        tasksToRun.remove(RecipeAnalysisTask.healthCheck);
      }
    }
    // (Future caching logic for other tasks could go here)

    if (tasksToRun.isEmpty) {
      debugPrint("All requested analysis tasks were covered by cache. No job submitted.");
      return false; // Indicates no job was submitted
    }
    // --- END CACHING LOGIC ---

    final requestPayload = json.encode({
      'tasks': tasksToRun.map((t) => t.toString().split('.').last).toList(),
      'recipe_data': recipe.toMap(),
      'dietary_profile': profile.fullProfileText,
    });

    await _jobManager.submitJob(
      jobType: 'recipe_analysis',
      requestPayload: requestPayload,
    );
    
    return true; // Indicates a job was submitted
  }

  /// Private helper to check if the health data is still valid.
  bool _isHealthCacheValid(Recipe recipe, DietaryProfile profile) {
    // 1. Generate the fingerprint for the CURRENT state of the dietary profile.
    final currentProfileFingerprint = FingerprintHelper.generate(profile);

    // 2. The recipe's own content fingerprint should have been set when it was last saved.
    final currentRecipeFingerprint = FingerprintHelper.generate(recipe);

    // 3. The cache is valid ONLY IF:
    //    - A health rating exists.
    //    - The stored profile fingerprint matches the current profile fingerprint.
    //    - The recipe's stored content fingerprint matches its current content fingerprint.
    return recipe.healthRating != null &&
        recipe.dietaryProfileFingerprint == currentProfileFingerprint &&
        recipe.fingerprint == currentRecipeFingerprint;
  }

  /// The method for our fuzzy similarity matching feature.
  /* Future<List<int>> findSimilarRecipes({
    required Recipe newRecipe,
    required List<Recipe> candidates,
  }) async {
    final requestBody = {
      // This service uses a different backend handler, so its key is correct.
      'find_similar_request': {
        'primary_recipe': newRecipe.toMap(),
        'candidate_recipes': candidates.map((r) => r.toMap()).toList(),
      }
    };
    
    final responseBody = await ApiHelper.analyzeRaw(requestBody, model: AiModel.pro);
    final aiResult = responseBody['result'];
    
    return List<int>.from(aiResult['similar_recipe_ids'] ?? []);
  } */

  /// --- NEW METHOD FOR QUICK NUTRITIONAL ANALYSIS ---
  Future<Map<String, dynamic>> getNutritionalAnalysisForText(String text) async {
    if (text.trim().isEmpty) return {};

    final requestBody = {
      'nutritional_estimation_request': {'text': text}
    };
    
    final responseBody = await ApiHelper.analyzeRaw(requestBody, model: AiModel.flash);
    final aiResult = responseBody['result'];

    if (aiResult is Map<String, dynamic>) {
      return aiResult;
    }
    
    return {};
  }

  // Future method for bulk health checks would go here.
  /*Future<List<Recipe>> enhanceMultipleRecipes(...) async {
    // This would be similar to enhanceSingleRecipe but would handle
    // a list of recipes and a list of results.
  }*/

  /// --- NEW ORCHESTRATOR METHOD ---
  /// This method handles the full workflow: first analyzing a recipe,
  /// then using that result to find similar recipes.
  Future<List<int>> analyzeAndFindSimilar({
    required Recipe recipeToProcess,
    required List<Recipe> candidateRecipes,
  }) async {
    // --- STEP 1: Analyze the new recipe ---
    // We create a request body for the initial analysis.
    final analysisRequestBody = {
      'recipe_analysis_request': {
        // Define the tasks needed to get a complete recipe object
        'tasks': ['parse', 'generateTags', 'estimateNutrition', 'healthCheck'],
        'recipe_data': recipeToProcess.toMap(), 
        // Assume profile is loaded elsewhere or passed in
        'dietary_profile': (await ProfileService.loadProfile()).fullProfileText,
      }
    };

    // Make the first API call to fully analyze the recipe
    final analysisResponseBody = await ApiHelper.analyzeRaw(analysisRequestBody, model: AiModel.pro);
    final analysisResult = analysisResponseBody['result'];

    if (analysisResult == null) {
      // Handle error: the initial analysis failed
      throw Exception('Failed to analyze the primary recipe.');
    }

    // --- STEP 2: Find similar recipes using the analyzed result ---
    // Now, create the request body for the second, separate API call.
    final findSimilarRequestBody = {
      'find_similar_request': {
        // Use the fully analyzed recipe from the first call's result
        'primary_recipe': analysisResult, 
        'candidate_recipes': candidateRecipes.map((r) => r.toMap()).toList(),
      }
    };
    
    // Make the second API call
    final similarResponseBody = await ApiHelper.analyzeRaw(findSimilarRequestBody, model: AiModel.pro);
    final similarResult = similarResponseBody['result'];
    
    if (similarResult == null || similarResult['similar_recipe_ids'] == null) {
      return []; // Return an empty list if no similarities were found or if there was an error
    }
    
    // Return the final list of IDs
    return List<int>.from(similarResult['similar_recipe_ids']);
  }
  
  /// This method only tries to find similar recipes.
  Future<List<int>> findSimilar({
    required Recipe recipeToProcess,
    required List<Recipe> candidateRecipes,
  }) async {
    // Find similar recipes using the analyzed result ---
    // Now, create the request body for the second, separate API call.
    final findSimilarRequestBody = {
      'find_similar_request': {
        'primary_recipe': recipeToProcess.toMap(), 
        'candidate_recipes': candidateRecipes.map((r) => r.toMap()).toList(),
      }
    };
    
    // Make the second API call
    final similarResponseBody = await ApiHelper.analyzeRaw(findSimilarRequestBody, model: AiModel.pro);
    final similarResult = similarResponseBody['result'];
    
    if (similarResult == null || similarResult['similar_recipe_ids'] == null) {
      return []; // Return an empty list if no similarities were found or if there was an error
    }
    
    // Return the final list of IDs
    return List<int>.from(similarResult['similar_recipe_ids']);
  }
}