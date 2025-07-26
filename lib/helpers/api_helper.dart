// lib/helpers/api_helper.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';

enum AiModel { pro, flash }

/// A helper class to handle all communication with the back-end API.
class ApiHelper {
  // The single source of truth for our cloud function URL.
  static const String _cloudFunctionUrl =
      "https://recipe-analyzer-api-1004204297555.us-central1.run.app";

  /// A private, generic analysis function that returns the raw JSON map.
  static Future<Map<String, dynamic>> analyzeRaw(
      Map<String, dynamic> body, {
      AiModel model = AiModel.pro
  }) async {
    // Add the chosen model to the request body sent to your Cloud Function
    final fullBody = {
      ...body,
      'model_choice': model == AiModel.pro ? 'gemini-2.5-pro' : 'gemini-2.5-flash',
    };

    try {
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(fullBody),
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

  // --- The original _analyze method now uses analyzeRaw ---
  static Future<Recipe> analyze(
    Map<String, String> body, {
    AiModel model = AiModel.pro
  }) async {
    final Map<String, dynamic> data = await analyzeRaw(body, model: model);
    final String sourceUrl = body['url'] ?? (body['image'] != null ? 'Scanned Content' : 'Pasted Text');
    return Recipe.fromJson(data, sourceUrl);
  }
}