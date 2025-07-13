// lib/helpers/api_helper.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';

/// A helper class to handle all communication with the back-end API.
class ApiHelper {
  // The single source of truth for our cloud function URL.
  static const String _cloudFunctionUrl =
      "https://recipe-analyzer-api-1004204297555.us-central1.run.app";

  /// Analyzes a recipe from a given URL.
  ///
  /// Throws an [Exception] if the request fails or the response is invalid.
  static Future<Recipe> analyzeUrl(String url) async {
    return _analyze({'url': url});
  }

  /// Analyzes a recipe from a block of unformatted text.
  ///
  /// Throws an [Exception] if the request fails or the response is invalid.
  static Future<Recipe> analyzeText(String text) async {
    return _analyze({'text': text});
  }

  /// The private, generic analysis function that handles the HTTP request.
  static Future<Recipe> _analyze(Map<String, String> body) async {
    try {
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        // The source URL is passed back to be stored in the Recipe object.
        final String sourceUrl = body['url'] ?? 'Pasted Text';
        return Recipe.fromJson(data, sourceUrl);
      } else {
        // If the server returns an error, throw an exception with the details.
        throw Exception(
            'Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      // Re-throw any other exceptions (network errors, etc.) to be handled by the UI.
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }
}