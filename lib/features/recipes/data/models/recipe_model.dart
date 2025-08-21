import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ingredient_model.dart';
import 'timing_info_model.dart';
import 'package:recette/core/utils/fingerprint_helper.dart';

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
  final Map<String, dynamic>? nutritionalInfo;
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
    this.otherTimings = const [],
    this.healthRating,
    this.healthSummary,
    this.healthSuggestions = const [],
    this.dietaryProfileFingerprint,
    this.nutritionalInfo,
    this.tags = const [],
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
    Map<String, dynamic>? nutritionalInfo,
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
      nutritionalInfo: isVariation ? null : (nutritionalInfo ?? this.nutritionalInfo),
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
      'nutritionalInfo': nutritionalInfo != null ? json.encode(nutritionalInfo) : null,
    };
  }

  /// Factory constructor to create a Recipe from a JSON map (from AI).
  factory Recipe.fromJson(Map<String, dynamic> json, String url) {
    // --- THIS IS THE FIX ---
    // Safely access the nested health_analysis object.
    final healthAnalysis = json['health_analysis'] as Map<String, dynamic>? ?? {};
    final suggestionsList = healthAnalysis['suggestions'] as List? ?? [];
    final healthSuggestions = suggestionsList.map((s) => s.toString()).toList();

    return Recipe(
      title: json['title'] ?? 'No Title Provided',
      description: json['description'] ?? '',
      prepTime: json['prep_time'] ?? '',
      cookTime: json['cook_time'] ?? '',
      totalTime: json['total_time'] ?? '',
      servings: json['servings'] ?? '',
      ingredients: (json['ingredients'] as List? ?? []).map((i) => Ingredient.fromJson(i)).toList(),
      instructions: (json['instructions'] as List? ?? []).map((i) => i.toString()).toList(),
      sourceUrl: url,
      otherTimings: (json['other_timings'] as List? ?? []).map((t) => TimingInfo.fromMap(t)).toList(),
      // Extract values from the nested health_analysis object.
      healthRating: healthAnalysis['health_rating'] ?? '',
      healthSummary: healthAnalysis['summary'] ?? '',
      healthSuggestions: healthSuggestions,
      // Safely access the nutritional_info object.
      nutritionalInfo: json['nutritional_info'] as Map<String, dynamic>? ?? {},
      tags: (json['tags'] as List? ?? []).map((tag) => tag.toString()).toList(),
    );
  }

  /// Factory constructor to create a Recipe from a database Map.
  /// This version is now more defensive to handle missing or null data.
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      parentRecipeId: map['parentRecipeId'],
      fingerprint: map['fingerprint'],
      // Use the null-coalescing operator (??) to provide a default value.
      title: map['title'] ?? 'No Title',
      description: map['description'] ?? '',
      prepTime: map['prepTime'] ?? '',
      cookTime: map['cookTime'] ?? '',
      totalTime: map['totalTime'] ?? '',
      servings: map['servings'] ?? '',
      // Safely decode JSON strings that might be null or empty.
      ingredients: (json.decode(map['ingredients'] ?? '[]') as List)
          .map((i) => Ingredient.fromMap(i))
          .toList(),
      instructions: List<String>.from(json.decode(map['instructions'] ?? '[]')),
      sourceUrl: map['sourceUrl'] ?? '',
      otherTimings: map['otherTimings'] != null
          ? (json.decode(map['otherTimings']) as List)
              .map((t) => TimingInfo.fromMap(t))
              .toList()
          : [],
      healthRating: map['healthRating'],
      healthSummary: map['healthSummary'],
      healthSuggestions: map['healthSuggestions'] != null
          ? List<String>.from(json.decode(map['healthSuggestions']))
          : [],
      dietaryProfileFingerprint: map['dietaryProfileFingerprint'],
      nutritionalInfo: map['nutritionalInfo'] != null ? json.decode(map['nutritionalInfo']) : null,
    );
  }
}
