import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:recette/core/services/database_helper.dart';

class ExportService {
  /// Fetches all recipes, converts them to a JSON file, and triggers sharing.
  static Future<void> exportLibrary() async {
    // 1. Fetch all recipes from the database.
    final recipes = await DatabaseHelper.instance.getAllRecipes();
    if (recipes.isEmpty) {
      throw Exception('Your recipe library is empty. Nothing to export.');
    }

    // 2. Convert the list of Recipe objects into a list of Maps.
    final recipeListAsMaps = recipes.map((recipe) => recipe.toMap()).toList();

    // 3. Encode the list of maps into a formatted JSON string.
    const jsonEncoder = JsonEncoder.withIndent('  '); // For pretty printing
    final jsonString = jsonEncoder.convert(recipeListAsMaps);

    // 4. Get a temporary directory on the device to save the file.
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/recipe_library_backup.json';
    final file = File(filePath);

    // 5. Write the JSON string to the file.
    await file.writeAsString(jsonString);

    // 6. Use the share_plus package to share the created file.
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Here is my recipe library backup.',
    );
  }
}