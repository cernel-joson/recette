// test/widgets/recipe_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/features/recipes/presentation/widgets/widgets.dart';

Widget makeTestableWidget({required Widget child}) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('RecipeCard Widget Tests', () {
    final fullRecipe = Recipe(
      id: 1,
      title: 'Super Test Soup',
      description: 'A delicious and hearty soup for testing.',
      prepTime: '10 mins',
      cookTime: '30 mins',
      totalTime: '40 mins',
      servings: '4 servings',
      sourceUrl: 'https://example.com/soup',
      ingredients: [],
      instructions: [],
      otherTimings: [],
      tags: ['soup', 'easy', 'winter'],
    );

    testWidgets('RecipeCard displays title, description, and tags', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(makeTestableWidget(
        child: RecipeCard(
          recipe: fullRecipe,
          onTap: () {},
        ),
      ));

      // Assert
      expect(find.text('Super Test Soup'), findsOneWidget);
      expect(find.text('A delicious and hearty soup for testing.'), findsOneWidget);
      // The summary card shows the first 3 tags.
      expect(find.text('soup'), findsOneWidget);
      expect(find.text('easy'), findsOneWidget);
      expect(find.text('winter'), findsOneWidget);

      // --- THIS IS THE FIX: Verify that details are NOT present ---
      expect(find.textContaining('Source:'), findsNothing);
    });

    testWidgets('RecipeCard handles minimal data gracefully', (WidgetTester tester) async {
      final minimalRecipe = Recipe(
        title: 'Minimalist Dish',
        description: '',
        prepTime: '', cookTime: '', totalTime: '', servings: '', sourceUrl: '',
        ingredients: [], instructions: [], otherTimings: [], tags: [],
      );

      // Act
      await tester.pumpWidget(makeTestableWidget(
        child: RecipeCard(
          recipe: minimalRecipe,
          onTap: () {},
        ),
      ));

      // Assert
      expect(find.text('Minimalist Dish'), findsOneWidget);
      // Verify that the description and tag sections are not built when data is empty.
      expect(find.textContaining('A delicious'), findsNothing);
      expect(find.byType(Chip), findsNothing);
    });
  });
}