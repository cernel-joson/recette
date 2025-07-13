// lib/models/recipe_model.dart

import 'dart:convert';

/// Represents a full recipe with all its details.
class Recipe {
  final int? id;
  final String title;
  final String description;
  final String prepTime;
  final String cookTime;
  final String totalTime;
  final String servings;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final String sourceUrl;

  Recipe({
    this.id,
    required this.title,
    required this.description,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.sourceUrl,
  });

  /// Converts a Recipe object into a Map for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'totalTime': totalTime,
      'servings': servings,
      'ingredients': json.encode(ingredients.map((i) => i.toMap()).toList()),
      'instructions': json.encode(instructions),
      'sourceUrl': sourceUrl,
    };
  }

  /// Factory constructor to create a Recipe from a JSON map (from AI).
  factory Recipe.fromJson(Map<String, dynamic> json, String url) {
    var ingredientsList = json['ingredients'] as List? ?? [];
    List<Ingredient> ingredients =
        ingredientsList.map((i) => Ingredient.fromJson(i)).toList();

    var instructionsList = json['instructions'] as List? ?? [];
    List<String> instructions =
        instructionsList.map((i) => i.toString()).toList();

    return Recipe(
      title: json['title'] ?? 'No Title Provided',
      description: json['description'] ?? '',
      prepTime: json['prep_time'] ?? '',
      cookTime: json['cook_time'] ?? '',
      totalTime: json['total_time'] ?? '',
      servings: json['servings'] ?? '',
      ingredients: ingredients,
      instructions: instructions,
      sourceUrl: url,
    );
  }

  /// Factory constructor to create a Recipe from a database Map.
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      prepTime: map['prepTime'],
      cookTime: map['cookTime'],
      totalTime: map['totalTime'],
      servings: map['servings'],
      ingredients: (json.decode(map['ingredients']) as List)
          .map((i) => Ingredient.fromMap(i))
          .toList(),
      instructions: List<String>.from(json.decode(map['instructions'])),
      sourceUrl: map['sourceUrl'],
    );
  }
}

/// Represents a single ingredient in a recipe.
class Ingredient {
  final String quantity;
  final String unit;
  final String name;
  final String notes; // New field for additional comments.

  Ingredient({
    required this.quantity,
    required this.unit,
    required this.name,
    this.notes = '', // Default to an empty string.
  });

  /// Converts an Ingredient object to a Map.
  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'unit': unit,
      'name': name,
      'notes': notes,
    };
  }

  /// Factory constructor to create an Ingredient from a JSON map (from AI).
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      quantity: json['quantity'] ?? '',
      unit: json['unit'] ?? '',
      name: json['name'] ?? 'Unknown Ingredient',
      notes: json['notes'] ?? '',
    );
  }

  /// Factory constructor to create an Ingredient from a database Map.
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      quantity: map['quantity'],
      unit: map['unit'],
      name: map['name'],
      notes: map['notes'] ?? '', // Handle legacy data that might not have notes.
    );
  }

  /// A simplified factory constructor to parse an ingredient from a single string.
  /// This is used when saving from the simple text fields in the edit screen.
  /// It makes a best guess and is not as robust as the AI parser.
  factory Ingredient.fromString(String text) {
    // This is a very basic parser. A more complex regex could be used.
    final parts = text.split(' ');
    if (parts.length > 2) {
      return Ingredient(
        quantity: parts[0],
        unit: parts[1],
        name: parts.sublist(2).join(' '),
      );
    } else if (parts.length == 2) {
      return Ingredient(quantity: parts[0], unit: '', name: parts[1]);
    } else {
      return Ingredient(quantity: '', unit: '', name: text);
    }
  }

  /// Overrides the default toString() method for display purposes.
  @override
  String toString() {
    // Build the string piece by piece to handle missing parts gracefully.
    final parts = [quantity, unit, name];
    String mainString = parts.where((p) => p.isNotEmpty).join(' ').trim();
    if (notes.isNotEmpty) {
      return '$mainString ($notes)';
    }
    return mainString;
  }
}