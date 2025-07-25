import 'package:flutter/material.dart';
import '../services/recipe_parsing_service.dart'; // Import the centralized helper
import '../helpers/database_helper.dart';
import '../helpers/usage_limiter.dart'; // Import the new helper
import '../models/recipe_model.dart';

class RecipeLibraryController with ChangeNotifier {
  List<Recipe>? _recipes;
  bool _isLoading = true;

  // Public "getters" for the UI to read the state
  List<Recipe>? get recipes => _recipes;
  bool get isLoading => _isLoading;

  RecipeLibraryController() {
    // Load recipes automatically when the controller is created
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    _isLoading = true;
    notifyListeners(); // Tell the UI we are in a loading state

    final recipeList = await DatabaseHelper.instance.getAllRecipes();
    _recipes = recipeList;
    _isLoading = false;
    notifyListeners(); // Tell the UI the data is ready and loading is false
  }

  Future<void> deleteRecipe(int id) async {
    await DatabaseHelper.instance.delete(id);
    // After deleting, just reload the list to ensure the UI is consistent
    await loadRecipes();
  }

  /// Analyzes an image from a given path.
  /// Contains only business logic, no UI code.
  Future<Recipe> analyzeImageFromPath(String imagePath) async {
    // 1. Check usage limit (Business Logic)
    final canScan = await UsageLimiter.canPerformScan();

    if (!canScan) {
      // Throw a specific, catchable error for the UI to handle.
      throw Exception('Daily scan limit reached.');
    }

    // 2. Call the parsing service (Business Logic)
    final recipe = await RecipeParsingService.analyzeImage(imagePath);

    // 3. Increment the counter on success (Business Logic)
    await UsageLimiter.incrementScanCount();

    // 4. Return the result
    return recipe;
  }

  /// Analyzes a recipe from a given URL.
  /// Contains only business logic, no UI code.
  Future<Recipe> analyzeUrl(String url) async {
    // For now, this is a simple pass-through, but if you needed
    // to add more logic (like checking usage limits), it would go here.
    final recipe = await RecipeParsingService.analyzeUrl(url);
    return recipe;
  }
}