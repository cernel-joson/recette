import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intelligent_nutrition_app/features/recipes/data/models/models.dart';
import 'package:intelligent_nutrition_app/features/recipes/presentation/widgets/widgets.dart';

// A helper function to wrap our widget in a MaterialApp.
Widget makeTestableWidget({required Widget child}) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('RecipeCard Widget Tests', () {
    // Create a rich, detailed Recipe object to use in our tests.
    final fullRecipe = Recipe(
      id: 1,
      title: 'Super Test Soup',
      description: 'A delicious and hearty soup for testing.',
      prepTime: '10 mins',
      cookTime: '30 mins',
      totalTime: '40 mins',
      servings: '4 servings',
      sourceUrl: 'https://example.com/soup',
      ingredients: [
        Ingredient(quantity: '2', unit: 'cups', name: 'broth', notes: 'vegetable'),
        Ingredient(quantity: '1', unit: '', name: 'large carrot', notes: 'diced'),
      ],
      instructions: [
        'Combine ingredients in a pot.',
        'Bring to a boil.',
        'Simmer for 30 minutes.',
      ],
      otherTimings: [
        TimingInfo(label: 'Rest Time', duration: '5 mins'),
      ],
    );

    testWidgets('RecipeCard displays all recipe information correctly',
        (WidgetTester tester) async {
      // 1. Act: Render the RecipeCard with our full recipe data.
      await tester.pumpWidget(makeTestableWidget(
        child: RecipeCard(recipe: fullRecipe),
      ));

      // 2. Assert: Verify that all the key pieces of information are displayed.
      
      // Check for title and description
      expect(find.text('Super Test Soup'), findsOneWidget);
      expect(find.text('A delicious and hearty soup for testing.'), findsOneWidget);
      
      // Check for the source URL
      expect(find.text('Source: https://example.com/soup'), findsOneWidget);

      // Check for the standard timings
      expect(find.textContaining('Prep: 10 mins'), findsOneWidget);
      expect(find.textContaining('Cook: 30 mins'), findsOneWidget);
      expect(find.textContaining('Total: 40 mins'), findsOneWidget);
      expect(find.textContaining('Serves: 4 servings'), findsOneWidget);
      
      // Check for the "other" timing
      expect(find.textContaining('Rest Time: 5 mins'), findsOneWidget);

      // Check for ingredients
      // We use textContaining because the full string includes the bullet point
      expect(find.textContaining('2 cups broth (vegetable)'), findsOneWidget);
      expect(find.textContaining('1 large carrot (diced)'), findsOneWidget);

      // Check for instructions
      expect(find.text('Combine ingredients in a pot.'), findsOneWidget);
      expect(find.text('Simmer for 30 minutes.'), findsOneWidget);
    });

    testWidgets('RecipeCard handles recipes with minimal data gracefully',
        (WidgetTester tester) async {
      // 1. Setup: Create a recipe with only the required fields.
      final minimalRecipe = Recipe(
        title: 'Minimalist Dish',
        description: '',
        prepTime: '',
        cookTime: '',
        totalTime: '',
        servings: '',
        sourceUrl: '',
        ingredients: [],
        instructions: ['Just serve it.'],
        otherTimings: [],
      );

      // 2. Act: Render the widget.
      await tester.pumpWidget(makeTestableWidget(
        child: RecipeCard(recipe: minimalRecipe),
      ));

      // 3. Assert: Verify the required fields are there and optional ones are not.
      expect(find.text('Minimalist Dish'), findsOneWidget);
      expect(find.text('Just serve it.'), findsOneWidget);

      // Check that optional fields are NOT present.
      expect(find.textContaining('Prep:'), findsNothing);
      expect(find.textContaining('Servings:'), findsNothing);
      expect(find.text('Ingredients'), findsOneWidget); // The header is always there
      expect(find.textContaining('•'), findsNothing); // But there are no bullet points
    });
  });
}