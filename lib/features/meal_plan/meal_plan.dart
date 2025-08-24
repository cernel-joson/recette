// lib/features/meal_plan/meal_plan.dart
import 'package:flutter/foundation.dart';
import 'package:recette/core/services/database_helper.dart';

// --- MODELS ---

enum MealPlanEntryType { recipe, text }

class MealPlanEntry {
  final int? id;
  final String date; // YYYY-MM-DD format
  final String mealType; // e.g., 'Breakfast', 'Lunch', 'Dinner'
  final MealPlanEntryType entryType;
  final int? recipeId;
  final String? textEntry;
  String? recipeTitle; // To be populated after fetching

  MealPlanEntry({
    this.id,
    required this.date,
    required this.mealType,
    required this.entryType,
    this.recipeId,
    this.textEntry,
    this.recipeTitle,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'meal_type': mealType,
      'entry_type': entryType.toString().split('.').last,
      'recipe_id': recipeId,
      'text_entry': textEntry,
    };
  }

  factory MealPlanEntry.fromMap(Map<String, dynamic> map) {
    return MealPlanEntry(
      id: map['id'],
      date: map['date'],
      mealType: map['meal_type'],
      entryType: MealPlanEntryType.values
          .firstWhere((e) => e.toString().split('.').last == map['entry_type']),
      recipeId: map['recipe_id'],
      textEntry: map['text_entry'],
    );
  }
}

// --- SERVICE ---

class MealPlanService {
  final DatabaseHelper _db;

  // Public constructor uses the real instance
  MealPlanService() : _db = DatabaseHelper.instance;

  // Internal constructor for testing
  @visibleForTesting
  MealPlanService.internal(this._db);

  Future<Map<String, List<MealPlanEntry>>> getMealPlanForDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await _db.database;
    final startDateString =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    final endDateString =
        "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

    final List<Map<String, dynamic>> maps = await db.query(
      'meal_plan_entries',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDateString, endDateString],
      orderBy: 'id ASC',
    );

    final Map<String, List<MealPlanEntry>> mealPlan = {};

    for (var map in maps) {
      final entry = MealPlanEntry.fromMap(map);
      if (entry.entryType == MealPlanEntryType.recipe &&
          entry.recipeId != null) {
        entry.recipeTitle = await _getRecipeTitle(entry.recipeId!);
      }

      if (mealPlan.containsKey(entry.date)) {
        mealPlan[entry.date]!.add(entry);
      } else {
        mealPlan[entry.date] = [entry];
      }
    }
    return mealPlan;
  }

  Future<void> addMealPlanEntry(MealPlanEntry entry) async {
    final db = await _db.database;
    await db.insert('meal_plan_entries', entry.toMap());
  }

  Future<void> updateMealPlanEntry(MealPlanEntry entry) async {
    final db = await _db.database;
    await db.update('meal_plan_entries', entry.toMap(),
        where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> deleteMealPlanEntry(int id) async {
    final db = await _db.database;
    await db
        .delete('meal_plan_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> _getRecipeTitle(int recipeId) async {
    final db = await _db.database;
    final result = await db.query('recipes',
        columns: ['title'], where: 'id = ?', whereArgs: [recipeId]);
    if (result.isNotEmpty) {
      return result.first['title'] as String?;
    }
    return null;
  }
}