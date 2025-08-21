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
    final requestData = json.decode(job.requestPayload);

    final responseJson = await ApiHelper.analyzeRaw({
      'recipe_analysis_request': requestData
    }, model: AiModel.pro);

    final aiResult = responseJson['result'];
    final promptText = responseJson['prompt_text'];
    final rawResponseText = responseJson['raw_response_text']; // <-- NEW
    final errorMessage = responseJson['error']; // <-- NEW

    // If parsing failed on the backend, throw an exception here
    if (aiResult == null) {
      throw Exception(errorMessage ?? "Backend failed to parse AI response.");
    }

    final recipe = Recipe.fromJson(aiResult, requestData['recipe_data']['url'] ?? 'Pasted Content');

    return JobResult(
      responsePayload: json.encode(recipe.toMap()),
      title: recipe.title,
      promptText: promptText,
      rawAiResponse: rawResponseText, // <-- NEW
    );
  }
}