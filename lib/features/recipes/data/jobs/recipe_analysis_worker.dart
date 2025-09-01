// lib/features/recipes/data/jobs/recipe_analysis_worker.dart

import 'dart:convert';
import 'dart:developer' as developer; // 1. Import the developer log
import 'package:recette/core/core.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';
import 'package:recette/core/jobs/data/repositories/job_repository.dart';
import 'package:recette/core/jobs/logic/job_worker.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/features/recipes/data/services/recipe_service.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';

// Renamed from RecipeParsingWorker
class RecipeAnalysisWorker implements JobWorker {
  final RecipeService _recipeService;
  
  RecipeAnalysisWorker({
    // Using default initializers for convenience
    RecipeService? recipeService,
  })  : _recipeService = recipeService ?? RecipeService();

  @override
  Future<JobResult> execute(Job job) async {
    final requestData = json.decode(job.requestPayload);

    final responseJson = await ApiHelper.analyzeRaw({
      'recipe_analysis_request': requestData
    }, model: AiModel.pro);
    
    // --- 2. DEBUG LOGGING ---
    // This will print the raw server response to your debug console.
    developer.log('--- RAW AI RESPONSE FROM SERVER ---');
    developer.log(jsonEncode(responseJson)); // Use jsonEncode for clean printing
    developer.log('--- END RAW AI RESPONSE ---');

    final aiResult = responseJson['result'];
    final promptText = responseJson['prompt_text'];
    final rawResponseText = responseJson['raw_response_text'];
    final errorMessage = responseJson['error'];

    // If parsing failed on the backend, throw an exception here
    if (aiResult == null) {
      throw Exception(errorMessage ?? "Backend failed to parse AI response.");
    }

    final recipe = Recipe.fromJson(
        aiResult, requestData['recipe_data']['url'] ?? 'Pasted Content');

    // --- THIS IS THE FIX ---
    String finalTitle = recipe.title;
    // If the AI returns the default placeholder, try to create a better title.
    if (finalTitle == 'No Title Provided') {
      final url = requestData['recipe_data']['url'] as String?;
      if (url != null && url.isNotEmpty) {
        // A simple way to generate a title from a URL
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty);
        if (pathSegments.isNotEmpty) {
          finalTitle = pathSegments.last
              .replaceAll('-', ' ')
              .replaceAll('.html', '')
              .split(' ')
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');
        }
      } else {
        finalTitle = 'Pasted Recipe Analysis';
      }
    }
    // --- END OF FIX ---

    return JobResult(
      responsePayload: json.encode(recipe.toMap()),
      title: finalTitle, // Use the new, smarter title
      promptText: promptText,
      rawAiResponse: rawResponseText,
    );
  }

  @override
  Future<void> onComplete(Job job) async {
    final requestData = json.decode(job.requestPayload);
    final recipeData = requestData['recipe_data'] as Map<String, dynamic>;

    // Only process jobs that were for an EXISTING recipe.
    if (recipeData.containsKey('id') && recipeData['id'] != null) {
      // --- THIS IS THE FIX ---
      if (job.rawAiResponse == null || job.rawAiResponse!.isEmpty) return;

      final db = DatabaseHelper.instance;
      final jobRepo = JobRepository();
      final recipeId = recipeData['id'] as int;
      final originalRecipe = await _recipeService.getRecipeById(recipeId);

      if (originalRecipe == null) return;

      // Sanitize the raw response string to remove markdown fences.
      final jsonString = job.rawAiResponse!.trim().replaceAll("```json", "").replaceAll("```", "").trim();
      
      // Decode the sanitized string.
      final rawAiResult = json.decode(jsonString);
      
      // Use fromJson, which is designed to handle the AI's data structure.
      final updatedDataFromAi = Recipe.fromJson(rawAiResult, originalRecipe.sourceUrl);

      // Get the profile that was used in this job's API call.
      final profile = await ProfileService.loadProfile();
      final newProfileFingerprint = FingerprintHelper.generate(profile);
      
      // We need the fingerprint of the recipe *as it was analyzed*.
      // We can regenerate it from the original recipe object that was sent in the job payload.
      final recipeFingerprintForAnalysis = FingerprintHelper.generate(originalRecipe);


      // Combine the new AI data with the original recipe's core data.
      final finalRecipe = originalRecipe.copyWith(
        tags: updatedDataFromAi.tags,
        healthRating: updatedDataFromAi.healthRating,
        healthSummary: updatedDataFromAi.healthSummary,
        healthSuggestions: updatedDataFromAi.healthSuggestions,
        nutritionalInfo: updatedDataFromAi.nutritionalInfo,
        // Store the fingerprints that this analysis is valid for.
        dietaryProfileFingerprint: newProfileFingerprint,
        fingerprint: recipeFingerprintForAnalysis
      );

      // 4. Save the fully updated recipe and archive the job.
      await db.update(finalRecipe, finalRecipe.tags);
      await jobRepo.updateJobStatus(job.id!, JobStatus.archived);
      // --- END OF FIX ---
    }
  }
}