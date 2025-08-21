// lib/features/recipes/data/jobs/recipe_analysis_worker.dart

import 'dart:convert';
import 'package:recette/core/core.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';
import 'package:recette/core/jobs/logic/job_worker.dart';
import 'package:recette/features/recipes/recipes.dart';

// Renamed from RecipeParsingWorker
class RecipeAnalysisWorker implements JobWorker {
  @override
  Future<JobResult> execute(Job job) async {
    // This worker's job is now to simply pass the request payload
    // to the unified backend endpoint.
    final requestData = json.decode(job.requestPayload);

    // --- THIS IS THE FIX ---
    // The ApiHelper sends the request body directly. We need to ensure the
    // payload is wrapped with the key the backend router is expecting.
    final responseJson = await ApiHelper.analyzeRaw({
      'recipe_analysis_request': requestData
    }, model: AiModel.pro);
    // --- END OF FIX ---
    
    // --- NEW: Extract data from the new response structure ---
    final aiResult = responseJson['result'];
    final promptText = responseJson['prompt_text'];

    final recipe = Recipe.fromMap(aiResult);

    // The result contains the full recipe JSON and its title for the job banner.
    return JobResult(
      responsePayload: json.encode(recipe.toMap()),
      title: recipe.title,
      // The worker can now also pass the prompt text to be saved in the job.
      // You would need to add a `promptText` field to `JobResult` and handle
      // it in the `JobRepository.completeJob` method.
    );
  }
}