import 'package:intelligent_nutrition_app/features/recipes/data/models/models.dart';

/// A helper class to format a Recipe object into a plain text string.
class TextFormatter {
  static String formatRecipe(Recipe recipe) {
    final buffer = StringBuffer();

    // Title
    buffer.writeln(recipe.title.toUpperCase());
    buffer.writeln('=' * recipe.title.length);
    if (recipe.description.isNotEmpty) {
      buffer.writeln(recipe.description);
    }
    buffer.writeln();

    // Timings
    if (recipe.prepTime.isNotEmpty) buffer.writeln('Prep Time: ${recipe.prepTime}');
    if (recipe.cookTime.isNotEmpty) buffer.writeln('Cook Time: ${recipe.cookTime}');
    if (recipe.totalTime.isNotEmpty) buffer.writeln('Total Time: ${recipe.totalTime}');
    if (recipe.servings.isNotEmpty) buffer.writeln('Servings: ${recipe.servings}');
    for (var timing in recipe.otherTimings) {
      buffer.writeln('${timing.label}: ${timing.duration}');
    }
    buffer.writeln();

    // Ingredients
    buffer.writeln('INGREDIENTS');
    buffer.writeln('-----------');
    for (var ingredient in recipe.ingredients) {
      buffer.writeln('- ${ingredient.toString()}');
    }
    buffer.writeln();

    // Instructions
    buffer.writeln('INSTRUCTIONS');
    buffer.writeln('------------');
    for (int i = 0; i < recipe.instructions.length; i++) {
      buffer.writeln('${i + 1}. ${recipe.instructions[i]}');
    }
    buffer.writeln();

    // Source
    if (recipe.sourceUrl.isNotEmpty && recipe.sourceUrl.startsWith('http')) {
      buffer.writeln('Source: ${recipe.sourceUrl}');
    }

    return buffer.toString();
  }
}