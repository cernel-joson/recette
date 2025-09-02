import 'package:flutter/foundation.dart';
import 'package:recette/core/presentation/controllers/base_controller.dart'; // IMPORT base controller
import 'package:recette/features/meal_plan/data/models/meal_plan_entry_model.dart';
import 'package:recette/features/meal_plan/data/services/meal_plan_service.dart';
import 'package:recette/features/recipes/data/models/recipe_model.dart';

// --- UPDATED: Extend BaseController<MealPlanEntry> ---
class MealPlanController extends BaseController<MealPlanEntry> {
  final MealPlanService _mealPlanService;
  
  // --- REMOVED: Redundant properties ---
  // List<MealPlanEntry> _entries = [];
  // bool _isLoading = false;

  // --- RETAINED: This is state specific to the meal planner ---
  DateTime _selectedDate = DateTime.now();

  MealPlanController({MealPlanService? mealPlanService})
      : _mealPlanService = mealPlanService ?? MealPlanService();

  // --- REMOVED: Redundant `entries` and `isLoading` getters ---

  // --- RETAINED: Getter for selected date ---
  DateTime get selectedDate => _selectedDate;

  // --- UPDATED: Custom getters now use the `items` list from the base class ---
  Map<DateTime, List<MealPlanEntry>> get groupedEntries {
    final map = <DateTime, List<MealPlanEntry>>{};
    for (final entry in items) { // Uses `items` from BaseController
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      (map[date] ??= []).add(entry);
    }
    return map;
  }

  List<MealPlanEntry> get entriesForSelectedDate {
    return items // Uses `items` from BaseController
        .where((entry) =>
            entry.date.year == _selectedDate.year &&
            entry.date.month == _selectedDate.month &&
            entry.date.day == _selectedDate.day)
        .toList();
  }
  
  // --- NEW: Implement the required abstract method ---
  @override
  Future<List<MealPlanEntry>> fetchItems() {
    return _mealPlanService.getEntries();
  }

  // --- RETAINED: All state modification methods are kept ---
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> addRecipeToMealPlan(
      Recipe recipe, DateTime date, MealType mealType) async {
    final newEntry = MealPlanEntry(
      date: date,
      mealType: mealType,
      recipeId: recipe.id!,
      recipeTitle: recipe.title,
    );
    await _mealPlanService.addEntry(newEntry);
    await loadItems(); // Reload to reflect the change
  }

  Future<void> deleteEntry(int id) async {
    await _mealPlanService.deleteEntry(id);
    await loadItems(); // Reload
  }

  Future<void> clearPlan() async {
    await _mealPlanService.clearPlan();
    await loadItems(); // Reload
  }
}