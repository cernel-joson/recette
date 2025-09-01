import 'package:flutter/foundation.dart';

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
    // --- THIS IS THE FIX ---
    // Make the parsing logic defensive against incorrect types from the AI.
    final suggestionsData = json['suggestions'];
    List<String> suggestionsList = [];

    if (suggestionsData is List) {
      // If it's a list, convert it as expected.
      suggestionsList = suggestionsData.map((item) => item.toString()).toList();
    } else if (suggestionsData is String) {
      // Failsafe: if the AI returns a single string, split it by commas
      // or just wrap it in a list to prevent a crash.
      suggestionsList = [suggestionsData];
    }

    return HealthAnalysisResult(
      rating: json['health_rating'] ?? 'UNKNOWN',
      summary: json['summary'] ?? 'No summary provided.',
      suggestions: suggestionsList, // Use the safely parsed list
    );
  }
}