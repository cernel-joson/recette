import 'dart:convert';

// --- Data Models ---

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

  factory Recipe.fromJson(Map<String, dynamic> json, String url) {
    var ingredientsList = json['ingredients'] as List? ?? [];
    List<Ingredient> ingredients = ingredientsList.map((i) => Ingredient.fromJson(i)).toList();

    var instructionsList = json['instructions'] as List? ?? [];
    List<String> instructions = instructionsList.map((i) => i.toString()).toList();

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

class Ingredient {
  final String quantity;
  final String unit;
  final String name;
  final String notes;

  Ingredient({required this.quantity, required this.unit, required this.name, required this.notes});

  Map<String, dynamic> toMap() {
    return {'quantity': quantity, 'unit': unit, 'name': name, 'notes': notes};
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      quantity: json['quantity'] ?? '',
      unit: json['unit'] ?? '',
      name: json['name'] ?? 'Unknown Ingredient',
      notes: json['notes'] ?? '',
    );
  }
  
  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      quantity: map['quantity'],
      unit: map['unit'],
      name: map['name'],
      notes: map['notes'] ?? '',
    );
  }

  @override
  String toString() {
    return '$quantity $unit $name'.trim();
  }
}