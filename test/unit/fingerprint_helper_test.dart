// test/unit/fingerprint_helper_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:recette/features/recipes/data/models/recipe_model.dart';
import 'package:recette/core/utils/fingerprint_helper.dart';
import 'package:recette/features/recipes/recipes.dart';

void main() {
  group('FingerprintHelper', () {
    test('generates a consistent fingerprint for a simple recipe', () {
      // Arrange
      final recipe = Recipe(
        title: 'Test Recipe',
        description: 'A test',
        prepTime: '10 minutes',
        cookTime: '20 minutes',
        totalTime: '30 minutes',
        servings: '4',
        ingredients: [
          Ingredient(quantity: '1', unit: 'jar', name: 'Nothing')
        ],
        instructions: ['Empty jar'],
        sourceUrl: 'Test',
      );

      // Act
      final fingerprint1 = FingerprintHelper.generate(recipe);
      final fingerprint2 = FingerprintHelper.generate(recipe);

      // Assert
      expect(fingerprint1, isNotNull);
      expect(fingerprint1, fingerprint2); // Should be identical
    });
  });
}