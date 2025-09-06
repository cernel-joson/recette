import 'dart:convert';
import 'package:flutter/foundation.dart'; // Import foundation for debugPrint
import 'package:recette/core/data/datasources/api_helper.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';
import 'package:recette/core/jobs/logic/job_worker.dart';
import 'package:recette/features/recipes/data/models/recipe_model.dart';
import 'package:recette/features/recipes/data/services/recipe_service.dart';

/// A specialized job worker that asks the AI to create a healthier
/// version of a given recipe.
class HealthifyRecipeWorker implements JobWorker {
  @override
  Future<JobResult> execute(Job job) async {
    final requestData = json.decode(job.requestPayload);

    // Use the 'pro' model for this more creative, nuanced task.
    final responseJson = await ApiHelper.analyzeRaw(
        {'healthify_recipe_request': requestData},
        model: AiModel.pro);

    // This will print the entire structure of the JSON response from the
    // backend to your debug console, allowing you to inspect the data types.
    debugPrint("--- HEALTHIFY WORKER RAW RESPONSE ---");
    debugPrint(responseJson.toString());
    // Add these debug prints to inspect the runtime type of each field.
    // One of these will almost certainly print "List<dynamic>".
    debugPrint("Type of 'prompt_text': ${responseJson['prompt_text'].runtimeType}");
    debugPrint("Type of 'raw_response_text': ${responseJson['raw_response_text'].runtimeType}");
    debugPrint("Type of 'result': ${responseJson['result'].runtimeType}");

    final aiResult = responseJson['result'];
    final promptText = responseJson['prompt_text'] as String;
    final rawResponseText = responseJson['raw_response_text'] as String;

    if (aiResult == null) {
      throw Exception(
          responseJson['error'] ?? "Backend failed to process healthify request.");
    }

    final healthifiedRecipe = Recipe.fromMap(aiResult);

    return JobResult(
      responsePayload: json.encode(healthifiedRecipe.toMap()),
      title: 'Healthier: ${healthifiedRecipe.title}',
      promptText: promptText,
      rawAiResponse: rawResponseText,
    );
  }

  @override
  Future<void> onComplete(Job job) async {
    if (job.responsePayload == null) return;

    final recipeService = RecipeService();
    final healthifiedRecipeMap = json.decode(job.responsePayload!);
    final healthifiedRecipe = Recipe.fromMap(healthifiedRecipeMap);

    // The original recipe was passed in the request payload.
    final requestData = json.decode(job.requestPayload);
    final originalRecipeMap = requestData['recipe_data'];
    final originalRecipe = Recipe.fromMap(originalRecipeMap);

    // Create the final variation object, ensuring it's treated as a new
    // recipe linked to the original.
    final recipeToSave = healthifiedRecipe.copyWith(
      id: null, // Ensures it gets a new ID from the database.
      parentRecipeId: originalRecipe.id,
    );

    // Save the new variation, which also archives the source job.
    await recipeService.createRecipe(recipeToSave, jobId: job.id);
  }
}
