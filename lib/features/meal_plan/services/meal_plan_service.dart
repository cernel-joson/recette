import 'package:flutter/foundation.dart';
import 'package:recette/features/meal_plan/data/models/meal_plan_entry_model.dart';
import 'package:recette/features/meal_plan/data/repositories/meal_plan_repository.dart';

/// Service for managing the meal plan.
class MealPlanService {
  final MealPlanRepository _repository;

  // Public constructor
  MealPlanService() : _repository = MealPlanRepository();

  // Constructor for testing
  @visibleForTesting
  MealPlanService.internal(this._repository);

  /// Fetches all meal plan entries from the database.
  Future<List<MealPlanEntry>> getEntries() {
    return _repository.entries.getAll();
  }

  /// Adds a new entry to the meal plan.
  Future<void> addEntry(MealPlanEntry entry) {
    return _repository.entries.create(entry);
  }

  /// Deletes an entry from the meal plan.
  Future<void> deleteEntry(int id) {
    return _repository.entries.delete(id);
  }
  
  Future<void> batchInsertEntries(List<MealPlanEntry> entries) {
    return _repository.entries.batchInsert(entries);
  }
  
  /// Deletes all entries from the meal plan.
  Future<void> clearPlan() {
    return _repository.entries.clear();
  }
}