import 'package:flutter/foundation.dart';
import 'package:recette/core/data/repositories/data_repository.dart';

enum MealType { breakfast, lunch, dinner, snack }

@immutable
class MealPlanEntry implements DataModel {
  @override
  final int? id;
  final DateTime date;
  final MealType mealType;
  final int recipeId;
  final String recipeTitle; // Denormalized for easy display

  const MealPlanEntry({
    this.id,
    required this.date,
    required this.mealType,
    required this.recipeId,
    required this.recipeTitle,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mealType': mealType.name,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
    };
  }

  factory MealPlanEntry.fromMap(Map<String, dynamic> map) {
    return MealPlanEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      mealType: MealType.values.byName(map['mealType']),
      recipeId: map['recipeId'],
      recipeTitle: map['recipeTitle'],
    );
  }
}