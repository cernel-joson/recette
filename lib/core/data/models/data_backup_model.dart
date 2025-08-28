import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:recette/features/inventory/data/models/models.dart';
import 'package:recette/features/meal_plan/data/models/meal_plan_entry_model.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/features/shopping_list/shopping_list.dart';

/// A model representing a complete backup of the user's application data.
@immutable
class DataBackup {
  /// The version of the backup format. Allows for future-proofing.
  final int version;

  /// The timestamp when the backup was created.
  final DateTime createdAt;

  // The core data lists
  final List<Recipe> recipes;
  final List<InventoryItem> inventoryItems;
  final List<InventoryCategory> inventoryCategories;
  final List<Location> inventoryLocations;
  final List<ShoppingListItem> shoppingListItems;
  final List<MealPlanEntry> mealPlanEntries;

  const DataBackup({
    required this.version,
    required this.createdAt,
    this.recipes = const [],
    this.inventoryItems = const [],
    this.inventoryCategories = const [],
    this.inventoryLocations = const [],
    this.shoppingListItems = const [],
    this.mealPlanEntries = const [],
  });

  /// Converts the DataBackup object to a JSON string.
  String toJson() {
    return json.encode({
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'recipes': recipes.map((r) => r.toMap()).toList(),
      'inventoryItems': inventoryItems.map((i) => i.toMap()).toList(),
      'inventoryCategories':
          inventoryCategories.map((c) => c.toMap()).toList(),
      'inventoryLocations': inventoryLocations.map((l) => l.toMap()).toList(),
      'shoppingListItems': shoppingListItems.map((s) => s.toMap()).toList(),
      'mealPlanEntries': mealPlanEntries.map((m) => m.toMap()).toList(),
    });
  }

  /// Creates a DataBackup object from a JSON string.
  factory DataBackup.fromJson(String source) {
    final map = json.decode(source);
    return DataBackup(
      version: map['version'],
      createdAt: DateTime.parse(map['createdAt']),
      recipes: (map['recipes'] as List)
          .map((item) => Recipe.fromMap(item))
          .toList(),
      inventoryItems: (map['inventoryItems'] as List)
          .map((item) => InventoryItem.fromMap(item))
          .toList(),
      inventoryCategories: (map['inventoryCategories'] as List)
          .map((item) => InventoryCategory.fromMap(item))
          .toList(),
      inventoryLocations: (map['inventoryLocations'] as List)
          .map((item) => Location.fromMap(item))
          .toList(),
      shoppingListItems: (map['shoppingListItems'] as List)
          .map((item) => ShoppingListItem.fromMap(item))
          .toList(),
      mealPlanEntries: (map['mealPlanEntries'] as List)
          .map((item) => MealPlanEntry.fromMap(item))
          .toList(),
    );
  }
}