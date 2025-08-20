import 'dart:convert';
import 'package:recette/core/jobs/job_model.dart';
import 'package:recette/core/jobs/job_result.dart';
import 'package:recette/core/jobs/job_worker.dart';
import 'package:recette/features/recipes/data/models/recipe_model.dart';
import 'package:recette/features/recipes/data/services/recipe_parsing_service.dart';

/// A worker that knows how to execute a recipe parsing job.
class RecipeParsingWorker implements JobWorker {
  @override
  Future<JobResult> execute(Job job) async {
    final requestData = json.decode(job.requestPayload);

    Recipe parsedRecipe;
    String source = requestData['source'] ?? 'Unknown Source';

    // Determine the source (URL, text, or image) from the request payload.
    if (requestData.containsKey('url')) {
      parsedRecipe = await RecipeParsingService.analyzeUrl(requestData['url']);
    } else if (requestData.containsKey('text')) {
      parsedRecipe = await RecipeParsingService.analyzeText(requestData['text']);
    } else if (requestData.containsKey('image')) {
      // Note: For a real implementation, the image data (base64) would be in the payload.
      // This worker assumes the payload contains a path, which the service handles.
      parsedRecipe = await RecipeParsingService.analyzeImage(requestData['image']);
    } else {
      throw Exception('Invalid recipe_parsing job payload. Missing url, text, or image key.');
    }

    final responsePayloadMap = {
      'recipe': parsedRecipe.toMap(),
      'sourceUrl': source,
    };

    // Return a JobResult object with the payload and the title.
    return JobResult(
      responsePayload: json.encode(responsePayloadMap),
      title: parsedRecipe.title,
    );
  }
}