// test/unit/fingerprint_helper_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:recette/core/utils/fingerprint_helper.dart';
import 'package:recette/features/dietary_profile/data/models/dietary_profile_model.dart';
import 'package:recette/features/recipes/data/models/models.dart';

void main() {
  group('FingerprintHelper', () {
    // A simple recipe object for testing.
    final recipe1 = Recipe(
      title: 'Chicken Soup',
      description: 'A simple soup',
      ingredients: [Ingredient(name: 'Chicken', quantity: '1', unit: 'whole')],
      instructions: ['Boil water'],
      prepTime: '10 minutes',
      cookTime: '20 minutes',
      totalTime: '30 minutes',
      servings: '4',
      sourceUrl: 'https://example.com/chicken-soup',
    );

    // An identical recipe object.
    final recipe2 = Recipe(
      title: 'Chicken Soup',
      description: 'A simple soup',
      ingredients: [Ingredient(name: 'Chicken', quantity: '1', unit: 'whole')],
      instructions: ['Boil water'],
      prepTime: '10 minutes',
      cookTime: '20 minutes',
      totalTime: '30 minutes',
      servings: '4',
      sourceUrl: 'https://example.com/chicken-soup',
    );

    // A slightly different recipe object.
    final recipe3 = Recipe(
      title: 'Beef Soup', // Changed title
      description: 'A simple soup',
      ingredients: [Ingredient(name: 'Chicken', quantity: '1', unit: 'whole')],
      instructions: ['Boil water'],
      prepTime: '10 minutes',
      cookTime: '20 minutes',
      totalTime: '30 minutes',
      servings: '4',
      sourceUrl: 'https://example.com/chicken-soup',
    );

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

    test('generate returns a non-empty string', () {
      // Act
      final fingerprint = FingerprintHelper.generate(recipe1);
      // Assert
      expect(fingerprint, isA<String>());
      expect(fingerprint, isNotEmpty);
    });

    test('generate produces a consistent fingerprint for identical objects', () {
      // Act
      final fingerprint1 = FingerprintHelper.generate(recipe1);
      final fingerprint2 = FingerprintHelper.generate(recipe2);
      // Assert
      expect(fingerprint1, equals(fingerprint2));
    });

    test('generate produces a different fingerprint for different objects', () {
      // Act
      final fingerprint1 = FingerprintHelper.generate(recipe1);
      final fingerprint3 = FingerprintHelper.generate(recipe3);
      // Assert
      expect(fingerprint1, isNot(equals(fingerprint3)));
    });

    test('generate works with DietaryProfile objects', () {
      // Arrange
      final profile1 = DietaryProfile(
          rules: 'Low sodium', preferences: 'Likes spicy food');
      final profile2 = DietaryProfile(
          rules: 'Low sodium', preferences: 'Likes spicy food');
      final profile3 =
          DietaryProfile(rules: 'Low carb', preferences: 'Likes spicy food');

      // Act
      final fingerprint1 = FingerprintHelper.generate(profile1);
      final fingerprint2 = FingerprintHelper.generate(profile2);
      final fingerprint3 = FingerprintHelper.generate(profile3);

      // Assert
      expect(fingerprint1, equals(fingerprint2));
      expect(fingerprint1, isNot(equals(fingerprint3)));
    });
  });
}