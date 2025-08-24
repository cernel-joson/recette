import 'package:flutter/material.dart';
import 'package:recette/features/meal_plan/meal_plan.dart';

class MealPlanController with ChangeNotifier {
  final MealPlanService _service = MealPlanService();

  Map<String, List<MealPlanEntry>> _mealPlan = {};
  Map<String, List<MealPlanEntry>> get mealPlan => _mealPlan;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DateTime _focusedDate = DateTime.now();
  DateTime get focusedDate => _focusedDate;

  Future<void> loadMealPlan(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();
    _mealPlan = await _service.getMealPlanForDateRange(startDate, endDate);
    _isLoading = false;
    notifyListeners();
  }

  void setFocusedDate(DateTime date) {
    _focusedDate = date;
    notifyListeners();
  }

  Future<void> addEntry(MealPlanEntry entry) async {
    await _service.addMealPlanEntry(entry);
    loadMealPlan(
        _focusedDate.subtract(const Duration(days: 30)), _focusedDate.add(const Duration(days: 30)));
  }

  Future<void> deleteEntry(int id) async {
    await _service.deleteMealPlanEntry(id);
    loadMealPlan(
        _focusedDate.subtract(const Duration(days: 30)), _focusedDate.add(const Duration(days: 30)));
  }
}