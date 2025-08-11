// lib/features/meal_plan/meal_plan.dart
import 'package:recette/core/services/database_helper.dart';

// --- MODEL ---
class MealPlanDay {
  final String date; // YYYY-MM-DD format
  final int? breakfastRecipeId;
  final int? lunchRecipeId;
  final int? dinnerRecipeId;

  // These will be populated after fetching from the DB
  String? breakfastRecipeTitle;
  String? lunchRecipeTitle;
  String? dinnerRecipeTitle;

  MealPlanDay({
    required this.date,
    this.breakfastRecipeId,
    this.lunchRecipeId,
    this.dinnerRecipeId,
  });

  factory MealPlanDay.fromMap(Map<String, dynamic> map) {
    return MealPlanDay(
      date: map['date'],
      breakfastRecipeId: map['breakfast_recipe_id'],
      lunchRecipeId: map['lunch_recipe_id'],
      dinnerRecipeId: map['dinner_recipe_id'],
    );
  }
}

// --- SERVICE ---
class MealPlanService {
  final _db = DatabaseHelper.instance;

  Future<void> assignRecipeToSlot(String date, String mealType, int recipeId) async {
    final db = await _db.database;
    // Check if a row for this date exists
    final existing = await db.query('meal_plan', where: 'date = ?', whereArgs: [date]);
    if (existing.isEmpty) {
      await db.insert('meal_plan', {'date': date, '${mealType}_recipe_id': recipeId});
    } else {
      await db.update('meal_plan', {'${mealType}_recipe_id': recipeId}, where: 'date = ?', whereArgs: [date]);
    }
  }

  Future<List<MealPlanDay>> getWeekPlan(DateTime startDate) async {
    final db = await _db.database;
    List<MealPlanDay> weekPlan = [];

    for (int i = 0; i < 7; i++) {
      final day = startDate.add(Duration(days: i));
      final dateString = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
      
      final result = await db.query('meal_plan', where: 'date = ?', whereArgs: [dateString]);
      MealPlanDay mealDay;
      if(result.isNotEmpty){
        mealDay = MealPlanDay.fromMap(result.first);
        // Helper to get recipe titles
        if(mealDay.breakfastRecipeId != null) mealDay.breakfastRecipeTitle = await _getRecipeTitle(mealDay.breakfastRecipeId!);
        if(mealDay.lunchRecipeId != null) mealDay.lunchRecipeTitle = await _getRecipeTitle(mealDay.lunchRecipeId!);
        if(mealDay.dinnerRecipeId != null) mealDay.dinnerRecipeTitle = await _getRecipeTitle(mealDay.dinnerRecipeId!);
      } else {
        mealDay = MealPlanDay(date: dateString);
      }
      weekPlan.add(mealDay);
    }
    return weekPlan;
  }

  Future<String?> _getRecipeTitle(int recipeId) async {
    final db = await _db.database;
    final result = await db.query('recipes', columns: ['title'], where: 'id = ?', whereArgs: [recipeId]);
    if (result.isNotEmpty) {
      return result.first['title'] as String?;
    }
    return null;
  }
}