import 'package:flutter/material.dart';
import 'package:intelligent_nutrition_app/features/recipes/data/services/services.dart';
import 'package:intelligent_nutrition_app/core/services/database_helper.dart';
import 'package:intelligent_nutrition_app/core/utils/utils.dart';
import 'package:intelligent_nutrition_app/features/recipes/data/models/models.dart';

// --- NEW: Instantiate the search service ---
final SearchService _searchService = SearchService();

class RecipeLibraryController with ChangeNotifier {
  List<Recipe> _recipes = []; // Default to empty list
  List<Recipe> _searchResults = []; // --- NEW: List for search results ---
  
  bool _isLoading = true;
  bool _isSearchActive = false; // --- NEW: Flag to track search state ---
  
  // --- NEW: Add property to track navigation state ---
  int? _navigatedFromRecipeId;

  // --- NEW: Public getter for the UI to read the state ---
  int? get navigatedFromRecipeId => _navigatedFromRecipeId;

  List<Recipe> get recipes => _isSearchActive ? _searchResults : _recipes;
  bool get isLoading => _isLoading;

  RecipeLibraryController() {
    loadInitialRecipes();
  }

  // --- NEW: Methods to manage the navigation state ---
  void setNavigationOrigin(int recipeId) {
    _navigatedFromRecipeId = recipeId;
    // No need to notify listeners, this state is for the next build.
  }

  void clearNavigationOrigin() {
    _navigatedFromRecipeId = null;
  }

  /// Loads the initial, default view (e.g., recent recipes).
  Future<void> loadInitialRecipes() async {
    _isLoading = true;
    notifyListeners();

    // For now, we still load all recipes for the default view.
    // This can be changed later to "recent" or "favorites".
    final recipeList = await DatabaseHelper.instance.getAllRecipes();
    _recipes = recipeList;
    _isLoading = false;
    _isSearchActive = false;
    clearNavigationOrigin(); // Clear navigation state on a full reload
    notifyListeners();
  }

  /// --- NEW: Performs a search and updates the UI ---
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      // If the query is empty, revert to the initial state.
      _isSearchActive = false;
      _searchResults = [];
      clearNavigationOrigin(); // Clear navigation state on a full reload
      notifyListeners();
      return;
    }

    _isLoading = true;
    _isSearchActive = true;
    notifyListeners();

    _searchResults = await _searchService.searchRecipes(query);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRecipe(int id) async {
    await DatabaseHelper.instance.delete(id);
    // After deleting, reload the initial list.
    await loadInitialRecipes();
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