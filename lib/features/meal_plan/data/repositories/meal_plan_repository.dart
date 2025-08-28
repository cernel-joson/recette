import 'package:recette/core/data/repositories/data_repository.dart';
import 'package:recette/features/meal_plan/data/models/meal_plan_entry_model.dart';

/// The single data access point for all meal plan data.
class MealPlanRepository {
  /// A generic repository specifically for handling MealPlanEntry objects.
  final entries = DataRepository<MealPlanEntry>(
    tableName: 'meal_plan_entries',
    fromMap: (map) => MealPlanEntry.fromMap(map),
  );

  // In the future, any custom queries for the meal plan,
  // like "get entries for a specific date range," would go here.
}