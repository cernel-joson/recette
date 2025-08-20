// lib/helpers/api_helper.dart

import 'dart:convert';
import 'dart:io'; // Import dart:io to use the File class.
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/core/services/api_helper.dart';
import 'package:recette/features/recipes/data/services/ai_enhancement_service.dart'; // Keep for the enum

/// A helper class to handle all communication with the back-end API.
class RecipeParsingService {
  /// Analyzes a recipe from a given URL.
  // Methods now accept an optional set of tasks
  static Future<Recipe> analyzeUrl(String url, {Set<AiEnhancementTask> tasks = const {}}) async {
    final requestBody = {
      'url': url,
      'tasks': tasks.map((t) => t.toString().split('.').last).toList(),
    };
    final Map<String, dynamic> data = await ApiHelper.analyzeRaw(requestBody, model: AiModel.pro);
    return Recipe.fromJson(data, url);
  }

  /// Analyzes a recipe from a block of unformatted text.
  static Future<Recipe> analyzeText(String text, {Set<AiEnhancementTask> tasks = const {}}) async {
    final requestBody = {
      'text': text,
      'tasks': tasks.map((t) => t.toString().split('.').last).toList(),
    };
    final Map<String, dynamic> data = await ApiHelper.analyzeRaw(requestBody, model: AiModel.pro);
    return Recipe.fromJson(data, 'Pasted Text');
  }

  /// --- UPDATED: Analyzes a recipe from an image file path. ---
  static Future<Recipe> analyzeImage(String imagePath, {Set<AiEnhancementTask> tasks = const {}}) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final requestBody = {
      'image': base64Image,
      'tasks': tasks.map((t) => t.toString().split('.').last).toList(),
    };
    final Map<String, dynamic> data = await ApiHelper.analyzeRaw(requestBody, model: AiModel.pro);
    return Recipe.fromJson(data, 'Scanned Content');
  }
}