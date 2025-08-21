// lib/features/recipes/data/services/recipe_import_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:recette/core/jobs/logic/job_manager.dart';
import 'package:recette/core/utils/usage_limiter.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';

class RecipeImportService {
  final JobManager _jobManager;
  final UsageLimiter _usageLimiter;

  RecipeImportService(this._jobManager, this._usageLimiter);

  /// A private helper to build the common request payload for a recipe analysis job.
  Future<String> _buildPayload({
    required Map<String, dynamic> recipeData,
  }) async {
    // The list of tasks is now hardcoded here, as this service's purpose
    // is always to do a full analysis on a new recipe.
    final tasks = {'parse', 'generateTags', 'healthCheck', 'estimateNutrition'};
    final profile = await ProfileService.loadProfile();

    return json.encode({
      'tasks': tasks.toList(),
      'recipe_data': recipeData,
      'dietary_profile': profile.fullProfileText,
    });
  }

  /// Creates and submits a job to import a recipe from a URL.
  Future<void> importFromUrl(String url) async {
    final payload = await _buildPayload(
      recipeData: {'url': url},
    );
    await _jobManager.submitJob(
      jobType: 'recipe_analysis',
      requestPayload: payload,
    );
  }

  /// Creates and submits a job to import a recipe from pasted text.
  Future<void> importFromText(String text) async {
    final payload = await _buildPayload(
      recipeData: {'text': text},
    );
    await _jobManager.submitJob(
      jobType: 'recipe_analysis',
      requestPayload: payload,
    );
  }

  /// Creates and submits a job to import a recipe from an image.
  Future<void> importFromImage(String imagePath) async {
    final canScan = await _usageLimiter.isAllowed('ocr_scan', maxUsages: 10, duration: const Duration(days: 1));
    if (!canScan) {
      throw Exception('Daily scan limit reached. Please try again tomorrow.');
    }

    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final payload = await _buildPayload(
      recipeData: {'image': base64Image},
    );

    await _jobManager.submitJob(
      jobType: 'recipe_analysis',
      requestPayload: payload,
    );

    await _usageLimiter.recordUsage('ocr_scan');
  }
}