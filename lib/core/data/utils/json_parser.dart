// lib/core/data/utils/json_parser_utils.dart

class JsonParser {
  /// Safely parses a dynamic value into a String.
  /// Handles cases where the value might be a String, List, or other type.
  static String? safeParseString(dynamic value) {
    return switch (value) {
      String s => s, // If it's a String, use it.
      List l => l.join(', '), // If it's a List, join its elements.
      _ => value?.toString(), // For anything else, try converting to a string.
    };
  }

  /// Safely parses a dynamic value into a List<String>.
  static List<String> safeParseStringList(dynamic value) {
    return switch (value) {
      List l => l.map((item) => item.toString()).toList(), // If it's a List, convert items to string.
      String s => [s], // If it's a single String, wrap it in a list.
      _ => [], // For anything else, return an empty list.
    };
  }

  // You can add more for integers, doubles, booleans, etc.
}