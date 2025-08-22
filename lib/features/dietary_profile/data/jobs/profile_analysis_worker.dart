// lib/features/dietary_profile/data/jobs/profile_analysis_worker.dart
import 'dart:convert';
import 'package:recette/core/core.dart';
import 'package:recette/core/jobs/data/models/job_model.dart';
import 'package:recette/core/jobs/data/models/job_result.dart';
import 'package:recette/core/jobs/logic/job_worker.dart';

class ProfileAnalysisWorker implements JobWorker {
  @override
  Future<JobResult> execute(Job job) async {
    final requestData = json.decode(job.requestPayload);
    final profileText = requestData['profile_text'];

    final responseBody = await ApiHelper.analyzeRaw({
      'review_text': profileText,
    });
    
    final aiResult = responseBody['result'];
    final promptText = responseBody['prompt_text'];
    final rawAiResponse = responseBody['raw_response_text'];

    return JobResult(
      responsePayload: json.encode(aiResult),
      promptText: promptText,
      rawAiResponse: rawAiResponse,
      title: 'Profile Review Suggestions',
    );
  }

  // --- ADD THIS METHOD ---
  @override
  Future<void> onComplete(Job job) async {
    // This job type doesn't require any follow-up action,
    // so the implementation is empty.
  }
  // --- END OF FIX ---
}