// lib/helpers/api_helper.dart

import 'dart:convert';
import 'dart:io'; // Import dart:io to use the File class.
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Import image_picker
import '../models/recipe_model.dart';

/// A data class to hold the result of a health analysis.
class HealthAnalysisResult {
  final String rating; // e.g., "GREEN", "YELLOW", "RED"
  final String summary;
  final List<String> suggestions;

  HealthAnalysisResult({
    required this.rating,
    required this.summary,
    required this.suggestions,
  });

  factory HealthAnalysisResult.fromJson(Map<String, dynamic> json) {
    return HealthAnalysisResult(
      rating: json['health_rating'] ?? 'UNKNOWN',
      summary: json['summary'] ?? 'No summary provided.',
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}

/// A helper class to handle all communication with the back-end API.
class ApiHelper {
  // The single source of truth for our cloud function URL.
  static const String _cloudFunctionUrl =
      "https://recipe-analyzer-api-1004204297555.us-central1.run.app";

  /// Analyzes a recipe from a given URL.
  static Future<Recipe> analyzeUrl(String url) async {
    // This method remains unchanged.
    return _analyze({'url': url});
  }

  /// Analyzes a recipe from a block of unformatted text.
  static Future<Recipe> analyzeText(String text) async {
    // This method remains unchanged.
    return _analyze({'text': text});
  }

  /// --- UPDATED: Analyzes a recipe from an image file path. ---
  static Future<Recipe> analyzeImage(String imagePath) async {
    // 1. Read the image file as bytes from the given path.
    final imageBytes = await File(imagePath).readAsBytes();
    // 2. Convert the bytes to a Base64 encoded string.
    final base64Image = base64Encode(imageBytes);
    // 3. Call the generic analysis function with the image data.
    return _analyze({'image': base64Image});
  }

  /// NEW: Sends profile text to the AI for review and returns its feedback.
  static Future<String> reviewProfile(String profileText) async {
    // We reuse the _analyze method but expect a different response structure.
    // The key 'review_text' tells our cloud function which prompt to use.
    final responseBody = await _analyzeRaw({'review_text': profileText});
    // The AI's response for a review is expected to be a simple JSON with a 'summary' key.
    return responseBody['summary'] ?? 'AI could not provide a summary.';
  }

  /// NEW: Sends a recipe and profile to the AI for a health analysis.
  static Future<HealthAnalysisResult> getHealthAnalysis({
    required String profileText,
    required Recipe recipe,
  }) async {
    final body = {
      'health_check': true, // The new key to trigger the right logic
      'dietary_profile': profileText,
      'recipe_data': recipe.toMap(), // Send the full recipe data
    };

    final responseBody = await _analyzeRaw(body);
    return HealthAnalysisResult.fromJson(responseBody);
  }

  /// A private, generic analysis function that returns the raw JSON map.
  static Future<Map<String, dynamic>> _analyzeRaw(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }

  // --- The original _analyze method now uses _analyzeRaw ---
  static Future<Recipe> _analyze(Map<String, String> body) async {
    final Map<String, dynamic> data = await _analyzeRaw(body);
    final String sourceUrl = body['url'] ?? (body['image'] != null ? 'Scanned Content' : 'Pasted Text');
    return Recipe.fromJson(data, sourceUrl);
  }
}