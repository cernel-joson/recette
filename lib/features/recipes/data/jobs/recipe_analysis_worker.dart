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

    // The backend router key is now 'recipe_analysis_request'
    final responseJson = await ApiHelper.analyzeRaw({
      'recipe_analysis_request': requestData
    }, model: AiModel.pro);

    final recipe = Recipe.fromMap(responseJson);

    // The result contains the full recipe JSON and its title for the job banner.
    return JobResult(
      responsePayload: json.encode(recipe.toMap()),
      title: recipe.title,
    );
  }
}