import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recette/core/data/models/data_backup_model.dart';
import 'package:recette/features/dietary_profile/services/profile_service.dart';
import 'package:recette/features/inventory/services/inventory_service.dart';
import 'package:recette/features/meal_plan/services/meal_plan_service.dart';
import 'package:recette/features/recipes/services/recipe_service.dart';
import 'package:recette/features/shopping_list/services/shopping_list_service.dart';
import 'package:share_plus/share_plus.dart';

/// A service to handle exporting all user data into a single backup file.
class ExportService {
  // Service dependencies are now handled with default initializers
  final RecipeService _recipeService;
  final InventoryService _inventoryService;
  final ShoppingListService _shoppingListService;
  final MealPlanService _mealPlanService;
  final ProfileService _profileService;

  ExportService({
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

  /// Gathers all data from the app and returns it as a DataBackup object.
  Future<DataBackup> _gatherDataForBackup() async {
    final recipes = await _recipeService.getAllRecipes();
    final inventoryItems = await _inventoryService.getInventory();
    final inventoryCategories = await _inventoryService.getCategories();
    final inventoryLocations = await _inventoryService.getLocations();
    final shoppingListItems = await _shoppingListService.getAllItems();
    final mealPlanEntries = await _mealPlanService.getEntries();
    final profile = await ProfileService.getProfile();

    return DataBackup(
      version: 1,
      createdAt: DateTime.now(),
      recipes: recipes,
      inventoryItems: inventoryItems,
      inventoryCategories: inventoryCategories,
      inventoryLocations: inventoryLocations,
      shoppingListItems: shoppingListItems,
      mealPlanEntries: mealPlanEntries,
      dietaryProfile: profile,
    );
  }

  /// Exports data and opens the native share dialog.
  Future<void> exportDataAndShare() async {
    final backup = await _gatherDataForBackup();
    final jsonString = const JsonEncoder.withIndent('  ').convert(backup.toJson());
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = await File('${tempDir.path}/recette_backup_$timestamp.json')
        .writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Recette Data Backup');
  }

  /// --- UPDATED: Now uses saveAs to open a file dialog ---
  Future<String> exportDataAndSaveAs() async {
    final backup = await _gatherDataForBackup();
    final jsonString = backup.toJson();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'recette_backup_$timestamp';

    Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));

    // Use the saveAs method to let the user choose the location
    String? filePath = await FileSaver.instance.saveAs(
      name: fileName,
      bytes: bytes,
      ext: 'json',
      mimeType: MimeType.json,
    );
    return filePath ?? 'Operation cancelled';
  }
}