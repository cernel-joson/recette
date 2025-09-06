// lib/helpers/api_helper.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

enum AiModel { pro, flash }

/// A helper class to handle all communication with the back-end API.
@Deprecated('Use ApiClient instead. This will be removed in a future version.')
class ApiHelper {
  // The single source of truth for our cloud function URL.
  // static const String _cloudFunctionUrl =
  //     "https://us-central1-recette-fdf64.cloudfunctions.net/recipe_analyzer_api";
  
  // Read the URL from a compile-time environment variable.
  // We provide a default value for local debugging.
  static const String _cloudFunctionUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://us-central1-recette-fdf64.cloudfunctions.net/recette-api-dev',
  );

  /// A private, generic analysis function that returns the raw JSON.
  /// It now returns Future<dynamic> to handle both Map and List responses.
  static Future<dynamic> analyzeRaw(
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
        // Return the decoded body directly, which could be a Map or a List.
        return json.decode(response.body);
      } else {
        throw Exception(
            'Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: ${e.toString()}');
    }
  }
}