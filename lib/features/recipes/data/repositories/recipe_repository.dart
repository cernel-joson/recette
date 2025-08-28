import 'package:sqflite/sqflite.dart';
import 'package:recette/core/data/repositories/data_repository.dart';
import 'package:recette/core/services/database_helper.dart';
import 'package:recette/features/recipes/data/models/recipe_model.dart';

/// The single data access point for all recipe-related data.
class RecipeRepository {
  /// A generic repository specifically for handling Recipe objects.
  final recipes = DataRepository<Recipe>(
    tableName: 'recipes',
    fromMap: (map) => Recipe.fromMap(map),
  );

  /// --- Custom Tag Management Logic ---
  /// This logic is specific to recipes and doesn't fit the generic repository.

  Future<void> addTagsToRecipe(int recipeId, List<String> tags) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final tagName in tags) {
        // Find tag or create it
        var tagId = (await txn.query('tags',
                columns: ['id'], where: 'name = ?', whereArgs: [tagName]))
            .firstOrNull?['id'] as int?;

        if (tagId == null) {
          tagId = await txn.insert('tags', {'name': tagName});
        }

        // Link tag to recipe
        await txn.insert(
            'recipe_tags', {'recipeId': recipeId, 'tagId': tagId},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<List<String>> getTagsForRecipe(int recipeId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT T.name FROM tags T
      INNER JOIN recipe_tags RT ON T.id = RT.tagId
      WHERE RT.recipeId = ?
    ''', [recipeId]);
    return result.map((row) => row['name'] as String).toList();
  }

  Future<void> clearTagsForRecipe(int recipeId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('recipe_tags', where: 'recipeId = ?', whereArgs: [recipeId]);
  }
  
  /// Checks if a recipe with the given fingerprint exists in the database.
  Future<bool> fingerprintExists(String fingerprint) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'recipes',
      columns: ['id'],
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}