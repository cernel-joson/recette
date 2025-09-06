import 'package:flutter/foundation.dart';
import 'package:recette/core/presentation/controllers/base_controller.dart'; // IMPORT the new base controller
import 'package:recette/features/recipes/services/services.dart';
import 'package:recette/features/recipes/data/models/models.dart';

// --- UPDATED: Extend the generic BaseController<Recipe> ---
class RecipeLibraryController extends BaseController<Recipe> {
  final RecipeService _recipeService;
  final SearchService _searchService;

  // --- REMOVED: The following properties are now handled by BaseController ---
  // List<Recipe> _recipes = [];
  // bool _isLoading = true;

  // --- RETAINED: These are specific to this controller's functionality ---
  List<Recipe> _searchResults = [];
  bool _isSearchActive = false;
  int? _navigatedFromRecipeId;

  RecipeLibraryController({
    RecipeService? recipeService,
    SearchService? searchService,
  })  : _recipeService = recipeService ?? RecipeService(),
        _searchService = searchService ?? SearchService();
        // The BaseController's constructor is called automatically, which triggers the initial load.

  // --- UPDATED: The public getter now uses the base class's `items` list ---
  List<Recipe> get recipes => _isSearchActive ? _searchResults : items;
  int? get navigatedFromRecipeId => _navigatedFromRecipeId;
  
  // --- RETAINED: Navigation logic is specific to this screen ---
  void setNavigationOrigin(int recipeId) {
    _navigatedFromRecipeId = recipeId;
  }

  void clearNavigationOrigin() {
    _navigatedFromRecipeId = null;
  }

  // --- REMOVED: The old `loadItems` method is now handled by the base class. ---
  
  // --- NEW: Implementation of the required abstract method from BaseController ---
  @override
  Future<List<Recipe>> fetchItems() {
    // This is where we tell the base controller HOW to get the items.
    _isSearchActive = false; // Reset search state on a full reload
    clearNavigationOrigin();
    return _recipeService.getAllRecipes();
  }

  // --- RETAINED: Search logic is specific to this controller ---
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      // If the query is empty, revert to the initial state by calling the base method.
      await super.loadItems(); // `loadItems` is the public method in BaseController
      return;
    }

    // Since search uses a different loading mechanism, we manage its state here.
    // We don't use the base controller's `_isLoading` for this part.
    _isSearchActive = true;
    notifyListeners();

    _searchResults = await _searchService.searchRecipes(query);
    notifyListeners();
  }
}