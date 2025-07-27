// lib/helpers/api_helper.dart

import 'dart:convert';
import 'dart:io'; // Import dart:io to use the File class.
import '../models/recipe_model.dart';
import '../helpers/api_helper.dart';

/// A helper class to handle all communication with the back-end API.
class RecipeParsingService {
  /// Analyzes a recipe from a given URL.
  static Future<Recipe> analyzeUrl(String url) async {
    // This method remains unchanged.
    return ApiHelper.analyze(
      {'url': url},
      model: AiModel.flash, // Use the more faster model for URL import
    );
  }

  /// Analyzes a recipe from a block of unformatted text.
  static Future<Recipe> analyzeText(String text) async {
    // This method remains unchanged.
    return ApiHelper.analyze(
      {'text': text},
      model: AiModel.flash, // Use the more faster model for text import
    );
  }

  /// --- UPDATED: Analyzes a recipe from an image file path. ---
  static Future<Recipe> analyzeImage(String imagePath) async {
    // 1. Read the image file as bytes from the given path.
    final imageBytes = await File(imagePath).readAsBytes();
    // 2. Convert the bytes to a Base64 encoded string.
    final base64Image = base64Encode(imageBytes);
    // 3. Call the generic analysis function with the image data.
    return ApiHelper.analyze(
      {'image': base64Image},
      model: AiModel.pro, // Use the more powerful model for OCR
    );
  }
}