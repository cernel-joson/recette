import 'package:recette/core/data/models/data_backup_model.dart';
import 'package:recette/features/inventory/data/services/services.dart';
// import 'package:recette/features/meal_plan/meal_plan.dart';
import 'package:recette/features/meal_plan/data/services/services.dart';
import 'package:recette/features/recipes/data/services/services.dart';
import 'package:recette/features/shopping_list/shopping_list.dart';

/// A service to handle exporting all user data into a single backup file.
class ExportService {
  final RecipeService _recipeService;
  final InventoryService _inventoryService;
  final ShoppingListService _shoppingListService;
  final MealPlanService _mealPlanService;

  ExportService({
    required RecipeService recipeService,
    required InventoryService inventoryService,
    required ShoppingListService shoppingListService,
    required MealPlanService mealPlanService,
  })  : _recipeService = recipeService,
        _inventoryService = inventoryService,
        _shoppingListService = shoppingListService,
        _mealPlanService = mealPlanService;

  /// Gathers all data from the app and creates a JSON string representation.
  Future<String> exportData() async {
    // 1. Fetch all data from the respective services
    final recipes = await _recipeService.getAllRecipes();
    final inventoryItems = await _inventoryService.getInventory();
    final inventoryCategories = await _inventoryService.getCategories();
    final inventoryLocations = await _inventoryService.getLocations();
    final shoppingListItems = await _shoppingListService.getItems();
    final mealPlanEntries = await _mealPlanService.getEntries();

    // 2. Create the backup object
    final backup = DataBackup(
      version: 1,
      createdAt: DateTime.now(),
      recipes: recipes,
      inventoryItems: inventoryItems,
      inventoryCategories: inventoryCategories,
      inventoryLocations: inventoryLocations,
      shoppingListItems: shoppingListItems,
      mealPlanEntries: mealPlanEntries,
    );

    // 3. Convert to a formatted JSON string
    return backup.toJson();
  }
}