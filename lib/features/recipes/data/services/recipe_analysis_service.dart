import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:recette/core/core.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/features/recipes/data/services/services.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';
import 'package:recette/core/jobs/logic/job_manager.dart';

// Enum to define the different kinds of analysis a user can request.
enum RecipeAnalysisTask {
  generateTags,
  healthCheck,
  estimateNutrition,
  findSimilar // The new task for our fuzzy matching
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

    // --- CACHING LOGIC ---
    if (tasks.contains(RecipeAnalysisTask.healthCheck)) {
      final isCacheValid = FingerprintHelper.generate(profile) == recipe.dietaryProfileFingerprint;
      if (isCacheValid) {
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

  /*Future<Recipe> enhanceSingleRecipe({
    required Recipe recipe,
    required Set<RecipeAnalysisTask> tasks,
  }) async {
    final currentProfile = await ProfileService.loadProfile();
    Recipe recipeToUpdate = recipe;
    
    // 1. Check the HealthCheck cache first.
    HealthAnalysisResult? cachedHealthResult;
    if (tasks.contains(RecipeAnalysisTask.healthCheck)) {
      cachedHealthResult = await HealthCheckService.getCachedAnalysis(recipe, currentProfile);
    }

    // 2. Determine which tasks ACTUALLY need to be sent to the API.
    final tasksForApi = Set<RecipeAnalysisTask>.from(tasks);
    if (cachedHealthResult != null) {
      tasksForApi.remove(RecipeAnalysisTask.healthCheck);
    }

    // --- THIS IS THE FIX ---
    // 3. Declare the response variable here, outside the 'if' block, so it has a wider scope.
    Map<String, dynamic>? response;

    if (tasksForApi.isNotEmpty) {
      final requestBody = {
        // Use the correct key that the backend router expects.
        'recipe_analysis_request': {
          'tasks': tasksForApi.map((t) => t.toString().split('.').last).toList(),
          'recipe_data': recipeToUpdate.toMap(), // Send the single recipe map
          'dietary_profile': currentProfile.fullProfileText,
        }
      };

      final responseBody = await ApiHelper.analyzeRaw(requestBody, model: AiModel.pro);
      
      // Extract data from the new standardized response structure
      final aiResult = responseBody['result'];
      response = aiResult as Map<String, dynamic>?;

      if (response != null) {
          final tagsData = response['tags'];
          List<String> newTags = recipeToUpdate.tags; 

          if (tagsData is List) {
            newTags = tagsData.map((item) => item.toString()).toList();
          } else if (tagsData is String) {
            newTags = [tagsData];
          }

          final nutritionData = response['nutritional_info'] as Map<String, dynamic>?;

          recipeToUpdate = recipeToUpdate.copyWith(
            tags: newTags,
            nutritionalInfo: nutritionData,
          );
      }
    }

    // 4. Apply the health results and save.
    if (tasks.contains(RecipeAnalysisTask.healthCheck)) {
      HealthAnalysisResult healthAnalysis;

      if (tasksForApi.contains(RecipeAnalysisTask.healthCheck)) {
        final healthData = response?['health_analysis'] as Map<String, dynamic>?;
        if (healthData == null) {
          throw Exception('API response did not include health analysis as requested.');
        }
        healthAnalysis = HealthAnalysisResult.fromJson(healthData);
      } else {
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
    await DatabaseHelper.instance.update(recipeToUpdate, recipeToUpdate.tags);
    return recipeToUpdate;
  } */

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
}