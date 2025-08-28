import 'package:flutter/foundation.dart';
import 'package:recette/features/meal_plan/data/models/meal_plan_entry_model.dart';
import 'package:recette/features/meal_plan/data/services/meal_plan_service.dart';
import 'package:recette/features/recipes/data/models/recipe_model.dart';

class MealPlanController with ChangeNotifier {
  final MealPlanService _mealPlanService;
  List<MealPlanEntry> _entries = [];
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();

  MealPlanController({MealPlanService? mealPlanService})
      : _mealPlanService = mealPlanService ?? MealPlanService() {
    loadEntries();
  }

  // --- Getters for UI state ---
  List<MealPlanEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  DateTime get selectedDate => _selectedDate;

  /// Returns a map of dates to meal entries for the calendar view.
  Map<DateTime, List<MealPlanEntry>> get groupedEntries {
    final map = <DateTime, List<MealPlanEntry>>{};
    for (final entry in _entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      (map[date] ??= []).add(entry);
    }
    return map;
  }

  /// Returns the meal entries for the currently selected date.
  List<MealPlanEntry> get entriesForSelectedDate {
    return _entries
        .where((entry) =>
            entry.date.year == _selectedDate.year &&
            entry.date.month == _selectedDate.month &&
            entry.date.day == _selectedDate.day)
        .toList();
  }

  // --- State Modification Methods ---

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    _entries = await _mealPlanService.getEntries();
    _isLoading = false;
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
    await loadEntries(); // Reload to reflect the change
  }

  Future<void> deleteEntry(int id) async {
    await _mealPlanService.deleteEntry(id);
    await loadEntries(); // Reload
  }

  Future<void> clearPlan() async {
    await _mealPlanService.clearPlan();
    await loadEntries(); // Reload
  }
}