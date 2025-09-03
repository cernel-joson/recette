import 'package:flutter/foundation.dart';
import 'package:recette/core/data/repositories/data_repository.dart';

enum MealType { breakfast, lunch, dinner, snack }
enum MealPlanEntryType { recipe, text }

@immutable
class MealPlanEntry implements DataModel {
  @override
  final int? id;
  final DateTime date;
  final MealType mealType;
  
  // The entry can now be one of two types.
  final MealPlanEntryType entryType;
  final int? recipeId; // Nullable if it's a text entry
  final String? recipeTitle; // Nullable, denormalized for easy display
  final String? textEntry; // Nullable if it's a recipe entry

  const MealPlanEntry({
    this.id,
    required this.date,
    required this.mealType,
    required this.entryType,
    this.recipeId,
    this.recipeTitle,
    this.textEntry,
  });

  // A convenient getter to display the correct text ---
  String get displayText => entryType == MealPlanEntryType.recipe ? (recipeTitle ?? 'Untitled Recipe') : (textEntry ?? 'Note');

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'meal_type': mealType.name,
      'entry_type': entryType.name,
      'recipe_id': recipeId,
      'recipe_title': recipeTitle,
      'text_entry': textEntry,
    };
  }

  factory MealPlanEntry.fromMap(Map<String, dynamic> map) {
    return MealPlanEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      mealType: MealType.values.byName(map['meal_type']),
      entryType: MealPlanEntryType.values.byName(map['entry_type']),
      recipeId: map['recipe_id'],
      recipeTitle: map['recipe_title'],
      textEntry: map['text_entry'],
    );
  }
}