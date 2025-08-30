import 'package:flutter/material.dart';
import 'package:recette/features/recipes/data/services/services.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:recette/features/recipes/data/models/recipe_model.dart';

class RecipeLibraryController with ChangeNotifier {
  final RecipeService _recipeService;
  final SearchService _searchService;

  List<Recipe> _recipes = []; // Default to empty list
  List<Recipe> _searchResults = []; // --- NEW: List for search results ---
  bool _isLoading = true;
  bool _isSearchActive = false; // --- NEW: Flag to track search state ---
  // --- NEW: Add property to track navigation state ---
  int? _navigatedFromRecipeId;

  RecipeLibraryController({
    RecipeService? recipeService,
    SearchService? searchService,
  }) : _recipeService = recipeService ?? RecipeService(),
       _searchService = searchService ?? SearchService() {
    loadRecipes();
  }

  // --- NEW: Public getter for the UI to read the state ---
  List<Recipe> get recipes => _isSearchActive ? _searchResults : _recipes;
  bool get isLoading => _isLoading;
  int? get navigatedFromRecipeId => _navigatedFromRecipeId;

  // --- NEW: Methods to manage the navigation state ---
  void setNavigationOrigin(int recipeId) {
    _navigatedFromRecipeId = recipeId;
    // No need to notify listeners, this state is for the next build.
  }

  void clearNavigationOrigin() {
    _navigatedFromRecipeId = null;
  }

  /// Loads the initial, default view (e.g., recent recipes).
  Future<void> loadRecipes() async {
    _isLoading = true;
    notifyListeners();

    // For now, we still load all recipes for the default view.
    // This can be changed later to "recent" or "favorites".
    final recipeList = await _recipeService.getAllRecipes();
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
}