// lib/helpers/api_helper.dart

import 'dart:convert';
import 'dart:io'; // Import dart:io to use the File class.
import 'package:intelligent_nutrition_app/features/recipes/data/models/models.dart';
import 'package:intelligent_nutrition_app/core/services/api_helper.dart';

/// A helper class to handle all communication with the back-end API.
class RecipeParsingService {
  /// Analyzes a recipe from a given URL.
  static Future<Recipe> analyzeUrl(String url) async {
    final Map<String, dynamic> data = await ApiHelper.analyzeRaw(
      {'url': url},
      model: AiModel.flash,
    );
    return Recipe.fromJson(data, url);
  }

  /// Analyzes a recipe from a block of unformatted text.
  static Future<Recipe> analyzeText(String text) async {
    final Map<String, dynamic> data = await ApiHelper.analyzeRaw(
      {'text': text},
      model: AiModel.flash,
    );
    return Recipe.fromJson(data, 'Pasted Text');
  }

  /// --- UPDATED: Analyzes a recipe from an image file path. ---
  static Future<Recipe> analyzeImage(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final Map<String, dynamic> data = await ApiHelper.analyzeRaw(
      {'image': base64Image},
      model: AiModel.pro,
    );
    return Recipe.fromJson(data, 'Scanned Content');
  }
}