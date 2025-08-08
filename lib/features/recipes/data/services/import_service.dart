import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:recette/core/services/database_helper.dart';
import 'package:recette/core/utils/utils.dart';
import 'package:recette/features/recipes/data/models/models.dart';

/// A data class to hold the result of an import operation.
class ImportResult {
  final int recipesAdded;
  final int duplicatesSkipped;

  ImportResult({required this.recipesAdded, required this.duplicatesSkipped});

  @override
  String toString() {
    if (recipesAdded == 0 && duplicatesSkipped == 0) {
      return 'The selected file contained no recipes.';
    }
    return 'Import complete! $recipesAdded recipes were added. $duplicatesSkipped duplicates were skipped.';
  }
}

class ImportService {
  /// Allows the user to select a JSON file and imports its recipes.
  static Future<ImportResult> importLibrary() async {
    // 1. Let the user pick a file.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      throw Exception('File selection was cancelled.');
    }

    // 2. Read the file's content.
    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();

    // 3. Decode the JSON string into a list of dynamic objects.
    final List<dynamic> jsonList = json.decode(jsonString);

    int recipesAdded = 0;
    int duplicatesSkipped = 0;

    // 4. Iterate over each recipe in the JSON file.
    for (var recipeMap in jsonList) {
      // Create a Recipe object from the map.
      final recipe = Recipe.fromMap(recipeMap as Map<String, dynamic>);

      // Ensure the recipe has a fingerprint. If it's an old backup,
      // the fingerprint might be null, so we generate a new one.
      final fingerprint = recipe.fingerprint ?? FingerprintHelper.generate(recipe);

      // 5. Check for duplicates before inserting.
      final bool exists = await DatabaseHelper.instance.doesRecipeExist(fingerprint);

      if (exists) {
        duplicatesSkipped++;
      } else {
        // If it doesn't exist, insert it into the database.
        // We create a copy with the definite fingerprint to be safe.
        await DatabaseHelper.instance.insert(recipe.copyWith(fingerprint: fingerprint));
        recipesAdded++;
      }
    }

    return ImportResult(
      recipesAdded: recipesAdded,
      duplicatesSkipped: duplicatesSkipped,
    );
  }
}