// lib/features/inventory/data/jobs/meal_suggestion_worker.dart
import 'dart:convert';
import 'package:recette/core/core.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';
import 'package:recette/core/jobs/logic/job_worker.dart';

class MealSuggestionWorker implements JobWorker {
  @override
  Future<JobResult> execute(Job job) async {
    final requestData = json.decode(job.requestPayload);

    // The backend router key is 'meal_suggestion_request'
    final responseBody = await ApiHelper.analyzeRaw({
      'meal_suggestion_request': requestData
    });

    // --- THIS IS THE FIX ---
    // Extract all parts of the standardized response from the backend
    final aiResult = responseBody['result'];
    final promptText = responseBody['prompt_text'];
    final rawAiResponse = responseBody['raw_response_text'];
    // --- END OF FIX ---
    
    return JobResult(
      responsePayload: json.encode(aiResult),
      promptText: promptText,
      rawAiResponse: rawAiResponse, // Pass the raw response to the result
      title: 'Meal Ideas',
    );
  }

  @override
  Future<void> onComplete(Job job) async {
    // onComplete can be empty because the result is handled by the UI banner.
  }
}