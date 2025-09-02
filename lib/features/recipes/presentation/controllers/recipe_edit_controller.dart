import 'package:flutter/material.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:recette/features/recipes/data/exceptions/recipe_exceptions.dart';
import 'package:recette/features/recipes/data/services/services.dart';
import 'package:recette/features/recipes/data/services/recipe_service.dart';
import 'package:recette/features/recipes/presentation/controllers/list_manager_mixin.dart';

class RecipeEditController extends ChangeNotifier with ListManagerMixin {
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
    titleController.addListener(markDirty);
    descriptionController.addListener(markDirty);
    prepTimeController.addListener(markDirty);
    cookTimeController.addListener(markDirty);
    totalTimeController.addListener(markDirty);
    servingsController.addListener(markDirty);
  }

  // This method fulfills the contract of the ListManagerMixin.
  @override
  void markDirty() {
    if (!isDirty) {
      isDirty = true;
      notifyListeners();
    }
  }

  // --- Methods now correctly use the mixin's functions directly ---
  void addIngredient(Ingredient newIngredient) {
    addItemToList(ingredients, newIngredient);
  }

  void editIngredient(int index, Ingredient updatedIngredient) {
    updateItemInList(ingredients, index, updatedIngredient);
  }

  void removeIngredient(int index) {
    removeItemFromList(ingredients, index);
  }

  void addInstruction() {
    addItemToList(instructions, 'New Step');
  }

  void editInstruction(int index, String updatedInstruction) {
    updateItemInList(instructions, index, updatedInstruction);
  }

  void removeInstruction(int index) {
    removeItemFromList(instructions, index);
  }

  void addOtherTiming(TimingInfo newTiming) {
    addItemToList(otherTimings, newTiming);
  }

  void editOtherTiming(int index, TimingInfo updatedTiming) {
    updateItemInList(otherTimings, index, updatedTiming);
  }

  void removeOtherTiming(int index) {
    removeItemFromList(otherTimings, index);
  }

  void updateTags(List<String> newTags) {
    tags = newTags;
    markDirty();
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
  
  /// Discards the current recipe edit and archives the source job.
  Future<void> discardAndArchiveJob() async {
    if (sourceJobId != null) {
      await _recipeService.discardJob(sourceJobId!);
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