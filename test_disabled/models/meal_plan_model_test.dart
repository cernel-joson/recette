// test/models/meal_plan_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:recette/features/meal_plan/meal_plan.dart';

void main() {
  group('MealPlanDay Model Tests', () {
    final testMealPlan = MealPlanDay(
      date: '2025-08-18',
      breakfastRecipeId: 101,
      lunchRecipeId: 102,
      dinnerRecipeId: 103,
    );

    // Note: MealPlanDay does not have a toMap method as it's not directly
    // saved in that format; the service layer handles database writes.

    test('fromMap deserializes correctly', () {
      // Arrange
      final map = {
        'date': '2025-08-18',
        'breakfast_recipe_id': 101,
        'lunch_recipe_id': 102,
        'dinner_recipe_id': 103,
      };

      // Act
      final mealPlanDay = MealPlanDay.fromMap(map);

      // Assert
      expect(mealPlanDay.date, '2025-08-18');
      expect(mealPlanDay.breakfastRecipeId, 101);
      expect(mealPlanDay.lunchRecipeId, 102);
      expect(mealPlanDay.dinnerRecipeId, 103);
    });

    test('fromMap handles null recipe IDs gracefully', () {
      // Arrange
      final map = {
        'date': '2025-08-19',
        'breakfast_recipe_id': null,
        'lunch_recipe_id': 201,
        'dinner_recipe_id': null,
      };

      // Act
      final mealPlanDay = MealPlanDay.fromMap(map);

      // Assert
      expect(mealPlanDay.date, '2025-08-19');
      expect(mealPlanDay.breakfastRecipeId, isNull);
      expect(mealPlanDay.lunchRecipeId, 201);
      expect(mealPlanDay.dinnerRecipeId, isNull);
    });
  });
}