// lib/features/dietary_profile/data/utils/profile_parser.dart

import 'package:flutter/foundation.dart';

// A data class to hold a single rule.
@immutable
class ProfileRule {
  final String text;
  final int indentation;

  const ProfileRule({required this.text, this.indentation = 0});
}

// A data class to hold a category (an ExpansionTile) and its list of rules.
@immutable
class ProfileCategory {
  final String title;
  final List<ProfileRule> rules;

  const ProfileCategory({required this.title, required this.rules});
}

/// A utility class to parse a Markdown string into a structured list of categories and rules.
class ProfileParser {
  static List<ProfileCategory> parse(String markdownText) {
    final lines = markdownText.split('\n');
    final categories = <ProfileCategory>[];

    // Check for the fallback case: unstructured text with no headings.
    if (!lines.any((line) => line.trim().startsWith('## '))) {
      final rules = lines
          .where((line) => line.trim().isNotEmpty)
          .map((line) => ProfileRule(text: line.trim()))
          .toList();
      if (rules.isNotEmpty) {
        return [ProfileCategory(title: 'General Guidelines', rules: rules)];
      }
      return [];
    }

    // Process the structured Markdown
    List<ProfileRule>? currentRules;
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      if (trimmedLine.startsWith('## ')) {
        // Start a new category.
        final title = trimmedLine.substring(3).trim();
        categories.add(ProfileCategory(title: title, rules: []));
        currentRules = categories.last.rules;
      } else if (trimmedLine.startsWith('- ') || trimmedLine.startsWith('* ')) {
        if (currentRules != null) {
          // Calculate indentation for nested rules
          final indentation = line.indexOf(trimmedLine.trimLeft());
          final ruleText = trimmedLine.substring(2).trim();
          currentRules.add(ProfileRule(text: ruleText, indentation: indentation));
        }
      }
    }

    return categories;
  }
}