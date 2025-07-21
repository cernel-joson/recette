import 'dart:convert';

/// A new class to represent a labeled duration.
class TimingInfo {
  final String label;
  final String duration;

  TimingInfo({required this.label, required this.duration});

  Map<String, dynamic> toMap() {
    return {'label': label, 'duration': duration};
  }

  factory TimingInfo.fromMap(Map<String, dynamic> map) {
    return TimingInfo(
      label: map['label'] ?? '',
      duration: map['duration'] ?? '',
    );
  }

  @override
  String toString() {
    return '$label: $duration';
  }
}

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
  final List<TimingInfo> otherTimings; // New field
  // NEW: Fields for caching health analysis
  String? healthRating; // e.g., "GREEN", "YELLOW", "RED"
  String? healthSummary; // AI-generated summary/suggestions
  List<String>? healthSuggestions; // AI-generated summary/suggestions
  String? dietaryProfileFingerprint; // Hash of the profile used for the rating

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
    this.otherTimings = const [], // Default to an empty list
    // NEW: Initialize new fields as null
    this.healthRating,
    this.healthSummary,
    this.healthSuggestions = const [],
    this.dietaryProfileFingerprint,
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
      // Encode the new list of timings into a JSON string for the database.
      'otherTimings': json.encode(otherTimings.map((t) => t.toMap()).toList()),
      // NEW: Add new fields to the map
      'healthRating': healthRating,
      'healthSummary': healthSummary,
      'healthSuggestions': healthSuggestions,
      'dietaryProfileFingerprint': dietaryProfileFingerprint,
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

    // Decode the new other_timings list from the AI response.
    var otherTimingsList = json['other_timings'] as List? ?? [];
    List<TimingInfo> otherTimings =
        otherTimingsList.map((t) => TimingInfo.fromMap(t)).toList();

    var healthSuggestionsList = json['healthSuggestions'] as List? ?? [];
    List<String> healthSuggestions =
        healthSuggestionsList.map((i) => i.toString()).toList();

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
      otherTimings: otherTimings,
      healthRating: json['healthRating'] ?? '',
      healthSummary: json['healthSummary'] ?? '',
      healthSuggestions: healthSuggestions,
      dietaryProfileFingerprint: json['dietaryProfileFingerprint'] ?? '',
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
      // Decode the otherTimings from the database, handling legacy data.
      otherTimings: map['otherTimings'] != null
          ? (json.decode(map['otherTimings']) as List)
              .map((t) => TimingInfo.fromMap(t))
              .toList()
          : [],
      // NEW: Extract new fields from the map
      healthRating: map['healthRating'],
      healthSummary: map['healthSummary'],
      healthSuggestions: List<String>.from(map['healthSuggestions'] ?? []),
      dietaryProfileFingerprint: map['dietaryProfileFingerprint'],
    );
  }
}

// ... (The Ingredient class remains the same) ...
class Ingredient {
  final String quantity;
  final String unit;
  final String name;
  final String notes;

  Ingredient({
    required this.quantity,
    required this.unit,
    required this.name,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'unit': unit,
      'name': name,
      'notes': notes,
    };
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

  factory Ingredient.fromString(String text) {
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

  @override
  String toString() {
    final parts = [quantity, unit, name];
    String mainString = parts.where((p) => p.isNotEmpty).join(' ').trim();
    if (notes.isNotEmpty) {
      return '$mainString ($notes)';
    }
    return mainString;
  }
}