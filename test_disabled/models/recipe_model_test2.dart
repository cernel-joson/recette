// test/models/recipe_model_test.dart

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:recette/features/recipes/data/models/models.dart';

void main() {
  group('Recipe Model Tests', () {
    // 1. Create a rich, detailed Recipe object to use as a baseline for all tests.
    final testRecipe = Recipe(
      id: 1,
      parentRecipeId: null,
      fingerprint: 'test-fingerprint',
      title: 'Test Soup',
      description: 'A delicious soup.',
      prepTime: '10 mins',
      cookTime: '20 mins',
      totalTime: '30 mins',
      servings: '4',
      ingredients: [
        Ingredient(quantity: '1', unit: 'cup', name: 'broth', quantityNumeric: 1.0),
      ],
      instructions: ['Heat broth.', 'Serve.'],
      sourceUrl: 'http://example.com',
      otherTimings: [TimingInfo(label: 'Rest', duration: '5 mins')],
      healthRating: 'GREEN',
      healthSummary: 'Looks good.',
      healthSuggestions: ['Add more vegetables.'],
      dietaryProfileFingerprint: 'profile-fingerprint',
      tags: ['soup', 'easy'],
    );

    test('toMap serializes correctly', () {
      // Act
      final recipeMap = testRecipe.toMap();

      // Assert
      expect(recipeMap['id'], 1);
      expect(recipeMap['title'], 'Test Soup');
      expect(recipeMap['healthRating'], 'GREEN');
      // Check that lists are correctly JSON encoded
      expect(json.decode(recipeMap['instructions'])[0], 'Heat broth.');
      expect(json.decode(recipeMap['tags'])[0], 'soup');
    });

    test('fromMap deserializes correctly', () {
      // Arrange: Create a map that simulates data from the database.
      final recipeMap = {
        'id': 1,
        'parentRecipeId': null,
        'fingerprint': 'test-fingerprint',
        'title': 'Test Soup',
        'description': 'A delicious soup.',
        'prepTime': '10 mins',
        'cookTime': '20 mins',
        'totalTime': '30 mins',
        'servings': '4',
        'ingredients': json.encode([
          {'quantity': '1', 'quantityNumeric': 1.0, 'unit': 'cup', 'name': 'broth', 'notes': ''}
        ]),
        'instructions': json.encode(['Heat broth.', 'Serve.']),
        'sourceUrl': 'http://example.com',
        'otherTimings': json.encode([{'label': 'Rest', 'duration': '5 mins'}]),
        'healthRating': 'GREEN',
        'healthSummary': 'Looks good.',
        'healthSuggestions': json.encode(['Add more vegetables.']),
        'dietaryProfileFingerprint': 'profile-fingerprint',
        // Note: Tags are not stored in the main recipe table, so they aren't in this map.
        // They are loaded separately after the main object is created.
      };

      // Act
      final recipe = Recipe.fromMap(recipeMap);

      // Assert
      expect(recipe.id, 1);
      expect(recipe.title, 'Test Soup');
      expect(recipe.ingredients.first.name, 'broth');
      expect(recipe.healthSuggestions?.first, 'Add more vegetables.');
    });

    test('copyWith creates a correct copy with updated values', () {
      // Act
      final updatedRecipe = testRecipe.copyWith(
        title: 'New Title',
        healthRating: 'RED',
      );

      // Assert
      expect(updatedRecipe.id, testRecipe.id); // ID should be the same
      expect(updatedRecipe.title, 'New Title'); // Title should be updated
      expect(updatedRecipe.healthRating, 'RED'); // Health rating should be updated
      expect(updatedRecipe.description, testRecipe.description); // Description should be unchanged
    });

    test('copyWith creates a proper variation', () {
      // Act
      final variationRecipe = testRecipe.copyWith(isVariation: true);

      // Assert
      expect(variationRecipe.id, isNull); // New variations have no ID
      expect(variationRecipe.parentRecipeId, testRecipe.id); // Parent ID is set
      // Health data should be reset for a new variation
      expect(variationRecipe.healthRating, isNull);
      expect(variationRecipe.healthSummary, isNull);
      expect(variationRecipe.dietaryProfileFingerprint, isNull);
      expect(variationRecipe.title, testRecipe.title); // Other fields are copied
    });
  });

  group('Ingredient Model Tests', () {
    final testIngredient = Ingredient(
      quantity: '1.5',
      quantityNumeric: 1.5,
      unit: 'cups',
      name: 'flour',
      notes: 'sifted',
    );

    test('toMap serializes correctly', () {
      final ingredientMap = testIngredient.toMap();
      expect(ingredientMap['quantityNumeric'], 1.5);
      expect(ingredientMap['name'], 'flour');
      expect(ingredientMap['notes'], 'sifted');
    });

    test('fromMap deserializes correctly', () {
      final ingredientMap = {
        'quantity': '1.5',
        'quantityNumeric': 1.5,
        'unit': 'cups',
        'name': 'flour',
        'notes': 'sifted',
      };
      final ingredient = Ingredient.fromMap(ingredientMap);
      expect(ingredient.quantityNumeric, 1.5);
      expect(ingredient.name, 'flour');
      expect(ingredient.notes, 'sifted');
    });
  });

  group('TimingInfo Model Tests', () {
    final testTiming = TimingInfo(label: 'Marinate', duration: '2 hours');

    test('toMap serializes correctly', () {
      final timingMap = testTiming.toMap();
      expect(timingMap['label'], 'Marinate');
      expect(timingMap['duration'], '2 hours');
    });

    test('fromMap deserializes correctly', () {
      final timingMap = {'label': 'Marinate', 'duration': '2 hours'};
      final timing = TimingInfo.fromMap(timingMap);
      expect(timing.label, 'Marinate');
      expect(timing.duration, '2 hours');
    });
  });
}