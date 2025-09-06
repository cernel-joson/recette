import 'package:recette/core/data/models/list_item_model.dart';

/// A generic parser for converting to and from a Markdown-like text format.
class MarkdownParser<T extends ListItem, C extends ListCategory> {
  /// Generates a Markdown string from grouped items.
  String generateMarkdown(Map<C, List<T>> groupedItems) {
    final buffer = StringBuffer();
    groupedItems.forEach((category, items) {
      buffer.writeln('## ${category.name}');
      for (final item in items) {
        buffer.writeln('- ${item.rawText}');
      }
      buffer.writeln();
    });
    return buffer.toString().trim();
  }

  /// Parses a single line of text into a raw map of data.
  /// The concrete controller will use this to create a specific ListItem.
  Map<String, String> parseLine(String line) {
    final rawText = line.trim().replaceFirst(RegExp(r'^\s*-\s*'), '');
    final RegExp itemRegex = RegExp(r'^\s*([\d\.\/½¼¾⅓⅔⅛\s\w]*?)\s+([a-zA-Z].*)');
    
    String? parsedName = rawText;
    String? parsedQuantity = '';

    final match = itemRegex.firstMatch(rawText);
    if (match != null && match.groupCount >= 2) {
      parsedQuantity = match.group(1)?.trim();
      parsedName = match.group(2)?.trim();
    }

    return {
      'rawText': rawText,
      'parsedName': parsedName ?? rawText,
      'parsedQuantity': parsedQuantity ?? '',
    };
  }
  
  /// Parses a full Markdown string into a structured map of categories and their items.
  Map<String, List<Map<String, String>>> parseMarkdownToStructure(String markdownText) {
    final lines = markdownText.split('\n');
    final structuredData = <String, List<Map<String, String>>>{};
    // Start with a default category in case the markdown doesn't specify one.
    String currentCategory = 'Uncategorized';

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (trimmedLine.startsWith('## ')) {
        currentCategory = trimmedLine.substring(3).trim();
        // Ensure the category key exists in the map, even if it has no items yet.
        structuredData.putIfAbsent(currentCategory, () => []);
      } else if (trimmedLine.startsWith('- ')) {
        final parsedItem = parseLine(trimmedLine);
        // Ensure the category key exists before trying to add an item to its list.
        structuredData.putIfAbsent(currentCategory, () => []).add(parsedItem);
      }
    }
    return structuredData;
  }
}
