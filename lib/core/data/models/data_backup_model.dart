import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:recette/features/inventory/data/models/models.dart';
import 'package:recette/features/meal_plan/data/models/meal_plan_entry_model.dart';
import 'package:recette/features/recipes/recipes.dart';
import 'package:recette/features/shopping_list/shopping_list.dart';
import 'package:recette/features/dietary_profile/data/models/models.dart';

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
  final DietaryProfile? dietaryProfile;
  
  const DataBackup({
    required this.version,
    required this.createdAt,
    this.recipes = const [],
    this.inventoryItems = const [],
    this.inventoryCategories = const [],
    this.inventoryLocations = const [],
    this.shoppingListItems = const [],
    this.mealPlanEntries = const [],
    this.dietaryProfile,
  });

  // --- SERIALIZATION LOGIC ---

  /// Converts the object to a Map. Consistent with other models.
  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'recipes': recipes.map((r) => r.toMap()).toList(),
      'inventoryItems': inventoryItems.map((i) => i.toMap()).toList(),
      'inventoryCategories': inventoryCategories.map((c) => c.toMap()).toList(),
      'inventoryLocations': inventoryLocations.map((l) => l.toMap()).toList(),
      'shoppingListItems': shoppingListItems.map((s) => s.toMap()).toList(),
      'mealPlanEntries': mealPlanEntries.map((m) => m.toMap()).toList(),
      'dietaryProfile': dietaryProfile?.fullProfileText,
    };
  }

  /// Creates an object from a Map. Consistent with other models.
  factory DataBackup.fromMap(Map<String, dynamic> map) {
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
      dietaryProfile: map['dietaryProfile'] != null
          ? DietaryProfile(markdownText: map['dietaryProfile'])
          : null,
    );
  }

  /// --- NEW: Converts the object directly to a JSON string ---
  String toJson() => json.encode(toMap());

  /// --- NEW: Creates an object directly from a JSON string ---
  factory DataBackup.fromJson(String source) => DataBackup.fromMap(json.decode(source));
}