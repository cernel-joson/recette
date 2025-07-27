import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/ingredient_model.dart';
import '../models/timing_info_model.dart';
import '../helpers/fingerprint_helper.dart';


/// Represents a full recipe with all its details.
class Recipe implements Fingerprintable {
  final int? id;
  final int? parentRecipeId;
  final String? fingerprint;
  final String title;
  final String description;
  final String prepTime;
  final String cookTime;
  final String totalTime;
  final String servings;
  final List<Ingredient> ingredients;
  final List<String> instructions;
  final String sourceUrl;
  final List<TimingInfo> otherTimings;
  String? healthRating; // e.g., "GREEN", "YELLOW", "RED"
  String? healthSummary; // AI-generated summary
  List<String>? healthSuggestions; // AI-generated suggestions
  String? dietaryProfileFingerprint; // Hash of the profile used for the rating
  List<String> tags;

  Recipe({
    this.id,
    this.parentRecipeId,
    this.fingerprint,
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
    this.healthRating,
    this.healthSummary,
    this.healthSuggestions = const [],
    this.dietaryProfileFingerprint,
    this.tags = const [], // NEW: Initialize in constructor
  });

  // --- Implementation of the Fingerprintable contract ---
  @override
  String get fingerprintableString {
    // To create a consistent string, we combine key properties.
    // Crucially, we sort the ingredients before joining them. This ensures
    // that two recipes with the same ingredients in a different order
    // will still produce the same fingerprint.
    final ingredientNames = ingredients.map((i) => i.name).toList()..sort();
    
    // We join the core, user-editable text content together.
    return '$title$description${ingredientNames.join()}${instructions.join()}';
  }

  // --- DEFINITIVE FIX for copyWith Method ---
  // This version correctly handles all parameters and the logic for creating variations.
  // It prioritizes new values passed to it, falling back to the existing object's
  // values only if the new ones are null.
  Recipe copyWith({
    int? id,
    int? parentRecipeId,
    String? fingerprint,
    String? title,
    String? description,
    String? prepTime,
    String? cookTime,
    String? totalTime,
    String? servings,
    List<Ingredient>? ingredients,
    List<String>? instructions,
    String? sourceUrl,
    List<TimingInfo>? otherTimings,
    String? healthRating,
    String? healthSummary,
    List<String>? healthSuggestions,
    String? dietaryProfileFingerprint,
    List<String>? tags,
    bool isVariation = false, // Flag to indicate a variation is being created
  }) {
    return Recipe(
      // If creating a variation, the new ID is explicitly null.
      // Otherwise, use the provided id, falling back to the existing id.
      id: isVariation ? null : (id ?? this.id),
      // If creating a variation, the parent ID is set to the current recipe's ID.
      // Otherwise, use the provided parentId, falling back to the existing one.
      parentRecipeId: isVariation ? this.id : (parentRecipeId ?? this.parentRecipeId),
      fingerprint: fingerprint ?? this.fingerprint,
      title: title ?? this.title,
      description: description ?? this.description,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      totalTime: totalTime ?? this.totalTime,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      otherTimings: otherTimings ?? this.otherTimings,
      // --- FIX: When creating a variation, reset all health data. ---
      // This ensures a new variation starts with a clean slate and requires its own health check.
      healthRating: isVariation ? null : (healthRating ?? this.healthRating),
      healthSummary: isVariation ? null : (healthSummary ?? this.healthSummary),
      healthSuggestions: isVariation ? [] : (healthSuggestions ?? this.healthSuggestions),
      dietaryProfileFingerprint: isVariation ? null : (dietaryProfileFingerprint ?? this.dietaryProfileFingerprint),
      // Prioritize the new tags list, but fall back to the existing
      // tags list if no new one is provided.
      tags: tags ?? this.tags,
    );
  }

  /// Converts a Recipe object into a Map for database insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentRecipeId': parentRecipeId,
      'fingerprint': fingerprint,
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
      'healthRating': healthRating,
      'healthSummary': healthSummary,
      'healthSuggestions': json.encode(healthSuggestions),
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
        
    // It was incorrectly parsing json['instructions'] instead of json['tags'].
    var tagsList = json['tags'] as List? ?? [];
    List<String> tags = tagsList.map((tag) => tag.toString()).toList();

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
      tags: tags, // Use the correctly parsed list
    );
  }

  /// Factory constructor to create a Recipe from a database Map.
  factory Recipe.fromMap(Map<String, dynamic> map) {
    debugPrint(map.toString());
    return Recipe(
      id: map['id'],
      parentRecipeId: map['parentRecipeId'],
      fingerprint: map['fingerprint'],
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
      healthRating: map['healthRating'],
      healthSummary: map['healthSummary'],
      healthSuggestions: map['healthSuggestions'] != null
          ? List<String>.from(json.decode(map['healthSuggestions'].toString()))
          : [],
      dietaryProfileFingerprint: map['dietaryProfileFingerprint'],
    );
  }
}
