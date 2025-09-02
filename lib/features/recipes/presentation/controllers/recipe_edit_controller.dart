import 'package:flutter/material.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/features/recipes/data/exceptions/recipe_exceptions.dart';
import 'package:recette/features/recipes/data/services/services.dart';
import 'package:recette/features/recipes/data/services/recipe_service.dart'; // IMPORT the service

class RecipeEditController with ChangeNotifier {
  final Recipe? _initialRecipe;
  final int? parentRecipeId;
  final int? sourceJobId;
  final RecipeService _recipeService;

  // State
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController prepTimeController;
  late TextEditingController cookTimeController;
  late TextEditingController totalTimeController;
  late TextEditingController servingsController;

  late List<Ingredient> ingredients;
  late List<String> instructions;
  late List<TimingInfo> otherTimings;
  late String sourceUrl;

  bool isDirty = false;
  bool isAnalyzing = false;

  late List<String> tags;

  RecipeEditController(
    this._initialRecipe, {
    this.parentRecipeId,
    this.sourceJobId,
    // --- NEW: Allow injecting a mock service for testing ---
    RecipeService? recipeService,
  }) : _recipeService = recipeService ?? RecipeService() {
    _populateState(_initialRecipe);
    _addListeners();
  }

  void _populateState(Recipe? recipe) {
    titleController = TextEditingController(text: recipe?.title ?? '');
    descriptionController = TextEditingController(text: recipe?.description ?? '');
    prepTimeController = TextEditingController(text: recipe?.prepTime ?? '');
    cookTimeController = TextEditingController(text: recipe?.cookTime ?? '');
    totalTimeController = TextEditingController(text: recipe?.totalTime ?? '');
    servingsController = TextEditingController(text: recipe?.servings ?? '');
    ingredients = List<Ingredient>.from(recipe?.ingredients ?? []);
    instructions = List<String>.from(recipe?.instructions ?? []);
    otherTimings = List<TimingInfo>.from(recipe?.otherTimings ?? []);
    sourceUrl = recipe?.sourceUrl ?? '';

    // --- POPULATE TAGS ---
    tags = List<String>.from(recipe?.tags ?? []);

    notifyListeners();
  }

  void _addListeners() {
    titleController.addListener(_markDirty);
    descriptionController.addListener(_markDirty);
    prepTimeController.addListener(_markDirty);
    cookTimeController.addListener(_markDirty);
    totalTimeController.addListener(_markDirty);
    servingsController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!isDirty) {
      isDirty = true;
      notifyListeners();
    }
  }

  // --- List Management Methods ---
  void addIngredient(Ingredient newIngredient) {
    ingredients.add(newIngredient);
    _markDirty();
    notifyListeners();
  }

  void editIngredient(int index, Ingredient updatedIngredient) {
    ingredients[index] = updatedIngredient;
    _markDirty();
    notifyListeners();
  }

  void removeIngredient(int index) {
    ingredients.removeAt(index);
    _markDirty();
    notifyListeners();
  }

  void addInstruction() {
    instructions.add('New Step'); // Add a placeholder
    _markDirty();
    notifyListeners();
  }

  void editInstruction(int index, String updatedInstruction) {
    instructions[index] = updatedInstruction;
    _markDirty();
    notifyListeners();
  }

  void removeInstruction(int index) {
    instructions.removeAt(index);
    _markDirty();
    notifyListeners();
  }

  void addOtherTiming(TimingInfo newTiming) {
    otherTimings.add(newTiming);
    _markDirty();
    notifyListeners();
  }

  void editOtherTiming(int index, TimingInfo updatedTiming) {
    otherTimings[index] = updatedTiming;
    _markDirty();
    notifyListeners();
  }

  void removeOtherTiming(int index) {
    otherTimings.removeAt(index);
    _markDirty();
    notifyListeners();
  }
  
  void updateTags(List<String> newTags) {
    tags = newTags;
    _markDirty();
    notifyListeners();
  }

  /// Gathers form data and delegates saving to the RecipeService.
  /// Throws a [RecipeExistsException] if a duplicate is found.
  Future<bool> saveForm() async {
    // 1. Assemble the recipe object from the current state.
    final recipe = Recipe(
      id: _initialRecipe?.id,
      parentRecipeId: parentRecipeId,
      title: titleController.text,
      description: descriptionController.text,
      prepTime: prepTimeController.text,
      cookTime: cookTimeController.text,
      totalTime: totalTimeController.text,
      servings: servingsController.text,
      ingredients: ingredients,
      instructions: instructions,
      otherTimings: otherTimings,
      sourceUrl: sourceUrl,
      tags: tags,
      healthRating: _initialRecipe?.healthRating,
      healthSummary: _initialRecipe?.healthSummary,
      healthSuggestions: _initialRecipe?.healthSuggestions,
      dietaryProfileFingerprint: _initialRecipe?.dietaryProfileFingerprint,
      nutritionalInfo: _initialRecipe?.nutritionalInfo,
    );

    // 2. Delegate the entire save process to the service.
    //    The try/catch block now correctly belongs in the presentation layer
    //    (or the calling widget) to handle UI feedback.
    try {
      await _recipeService.saveRecipeFromEditor(recipe, jobId: sourceJobId);
      isDirty = false;
      notifyListeners();
      return true; // Indicate success
    } on RecipeExistsException {
      // Re-throw the specific exception so the UI can catch it and show
      // the appropriate dialog to the user.
      rethrow;
    } catch (e) {
      debugPrint("An unexpected error occurred in RecipeEditController: $e");
      // For other unexpected errors, return false.
      return false;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    prepTimeController.dispose();
    cookTimeController.dispose();
    totalTimeController.dispose();
    servingsController.dispose();
    super.dispose();
  }
}