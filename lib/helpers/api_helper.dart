// lib/helpers/api_helper.dart

import 'dart:convert';
import 'dart:io'; // Import dart:io to use the File class.
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Import image_picker
import '../models/recipe_model.dart';

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

  /// A private, generic analysis function that returns the raw JSON map.
  static Future<Map<String, dynamic>> _analyzeRaw(Map<String, String> body) async {
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