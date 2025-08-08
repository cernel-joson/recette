import 'package:flutter_test/flutter_test.dart';
import 'package:recette/features/recipes/data/models/models.dart';

void main() {
  // A group is used to organize related tests together.
  group('Ingredient Model Tests', () {
    // A test case for the fromString factory constructor.
    test('Ingredient.fromString should parse a full string correctly', () {
      // 1. Setup: Define the input string.
      const input = '2 cups all-purpose flour';

      // 2. Act: Call the method we are testing.
      final ingredient = Ingredient.fromString(input);

      // 3. Assert: Check if the output is what we expect.
      expect(ingredient.quantity, '2');
      expect(ingredient.unit, 'cups');
      expect(ingredient.name, 'all-purpose flour');
    });

    /* test('Ingredient.fromString should handle strings with no unit', () {
      const input = '1 large onion';
      final ingredient = Ingredient.fromString(input);
      expect(ingredient.quantity, '1');
      expect(ingredient.unit, ''); // Expect unit to be empty
      expect(ingredient.name, 'large onion');
    }); */

    test('toString should format with notes correctly', () {
      final ingredient = Ingredient(
        quantity: '1',
        unit: 'tsp',
        name: 'Dijon mustard',
        notes: 'I like Maille brand',
      );
      expect(ingredient.toString(), '1 tsp Dijon mustard (I like Maille brand)');
    });

     test('toString should format without notes correctly', () {
      final ingredient = Ingredient(
        quantity: '2',
        unit: 'cloves',
        name: 'garlic',
      );
      expect(ingredient.toString(), '2 cloves garlic');
    });
  });

  group('Recipe Model Tests', () {
    test('Recipe.fromJson should parse a valid JSON map', () {
      // 1. Setup: Create a sample JSON map, similar to what our AI would return.
      final jsonMap = {
        "title": "Test Cake",
        "description": "A delicious test cake.",
        "prep_time": "15 minutes",
        "cook_time": "30 minutes",
        "total_time": "45 minutes",
        "servings": "8 slices",
        "ingredients": [
          {"quantity": "2", "unit": "cups", "name": "flour", "notes": "sifted"},
          {"quantity": "1", "unit": "cup", "name": "sugar", "notes": ""}
        ],
        "instructions": ["Mix ingredients.", "Bake at 350F."]
      };
      const sourceUrl = 'http://example.com';

      // 2. Act: Call the fromJson factory constructor.
      final recipe = Recipe.fromJson(jsonMap, sourceUrl);

      // 3. Assert: Verify that all properties were assigned correctly.
      expect(recipe.title, 'Test Cake');
      expect(recipe.description, 'A delicious test cake.');
      expect(recipe.servings, '8 slices');
      expect(recipe.sourceUrl, sourceUrl);
      expect(recipe.ingredients.length, 2);
      expect(recipe.ingredients[0].name, 'flour');
      expect(recipe.ingredients[0].notes, 'sifted');
      expect(recipe.instructions.length, 2);
      expect(recipe.instructions[1], 'Bake at 350F.');
    });

    test('Recipe.fromJson should handle missing optional fields gracefully', () {
      // Setup a JSON map where most fields are missing.
      final jsonMap = {
        "title": "Simple Test",
        "ingredients": [],
        "instructions": []
      };
       const sourceUrl = 'http://example.com/simple';

      // Act
      final recipe = Recipe.fromJson(jsonMap, sourceUrl);

      // Assert: Check that the required fields are set and optional ones are empty.
      expect(recipe.title, 'Simple Test');
      expect(recipe.description, ''); // Should default to empty string
      expect(recipe.servings, '');     // Should default to empty string
      expect(recipe.ingredients, isEmpty);
      expect(recipe.instructions, isEmpty);
    });
  });
}