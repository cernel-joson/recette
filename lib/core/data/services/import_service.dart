import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'package:recette/core/data/models/data_backup_model.dart';
import 'package:recette/features/dietary_profile/data/services/profile_service.dart';
import 'package:recette/features/inventory/data/services/inventory_service.dart';
import 'package:recette/features/meal_plan/data/services/meal_plan_service.dart';
import 'package:recette/features/recipes/data/services/recipe_service.dart';
import 'package:recette/features/shopping_list/data/services/shopping_list_service.dart';

/// Service to handle importing data from a backup file and overwriting local data.
class ImportService {
  final RecipeService _recipeService;
  final InventoryService _inventoryService;
  final ShoppingListService _shoppingListService;
  final MealPlanService _mealPlanService;
  final ProfileService _profileService;

  ImportService({
    // Using default initializers for convenience
    RecipeService? recipeService,
    InventoryService? inventoryService,
    ShoppingListService? shoppingListService,
    MealPlanService? mealPlanService,
    ProfileService? profileService,
  })  : _recipeService = recipeService ?? RecipeService(),
        _inventoryService = inventoryService ?? InventoryService(),
        _shoppingListService = shoppingListService ?? ShoppingListService(),
        _mealPlanService = mealPlanService ?? MealPlanService(),
        _profileService = profileService ?? ProfileService();

  /// Opens a file picker, reads the backup file, and restores the data.
  Future<void> pickAndImportData() async {
    // 1. Let user pick a file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      throw Exception('File picking cancelled.');
    }

    // 2. Read and parse the file content
    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();


    // --- DEBUG LOGGING ---
    developer.log('--- STARTING IMPORT ---');
    developer.log('Raw string from file: $jsonString');
    developer.log('Type of data read from file: ${jsonString.runtimeType}');

    final backup;

    try {
      // This is where the error happens. We are passing a String
      // to a method that expects a Map.
      backup = DataBackup.fromMap(json.decode(jsonString));

      developer.log('Successfully parsed backup file.');
    } catch (e, s) {
      developer.log('ERROR DURING IMPORT: $e');
      developer.log('Stack trace: $s');
      // Re-throw the exception so the UI can catch it
      throw Exception('Failed to parse backup file. Invalid format.');
    }

    // 3. Clear all existing data
    await _clearAllData();

    // 4. Batch insert all new data
    await _inventoryService.batchInsertCategories(backup.inventoryCategories);
    await _inventoryService.batchInsertLocations(backup.inventoryLocations);
    await _inventoryService.batchInsertItems(backup.inventoryItems);
    await _recipeService.batchInsertRecipes(backup.recipes);
    await _shoppingListService.batchInsertItems(backup.shoppingListItems);
    await _mealPlanService.batchInsertEntries(backup.mealPlanEntries);

    if (backup.dietaryProfile != null) {
      // await _profileService.saveProfile(backup.dietaryProfile!);
      await ProfileService.saveProfile(backup.dietaryProfile!);
    }
  }

  /// Wipes all data from the relevant database tables.
  Future<void> _clearAllData() async {
    // Services are called in reverse order of dependency for safety
    await _mealPlanService.clearPlan();
    await _shoppingListService.clearList();
    await _recipeService.clearAllRecipes();
    await _inventoryService.clearAllInventory();
    // await _profileService.clearProfile();
    await ProfileService.clearProfile();
  }
}