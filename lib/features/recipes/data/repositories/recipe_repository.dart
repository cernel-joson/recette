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

  /// A generic repository specifically for handling Recipe objects.
  final recipeTags = DataRepository<Recipe>(
    tableName: 'recipe_tags',
    fromMap: (map) => Recipe.fromMap(map),
  );
  
  /// A generic repository specifically for handling Recipe objects.
  final tags = DataRepository<Recipe>(
    tableName: 'tags',
    fromMap: (map) => Recipe.fromMap(map),
  );

  // --- Centralized Query Helper ---
  Future<List<Recipe>> _getRecipesWithTags({String? where, List<Object?>? whereArgs}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'title ASC',
    );

    if (maps.isEmpty) return [];

    return await Future.wait(maps.map((map) async {
      final recipe = Recipe.fromMap(map);
      final tags = await getTagsForRecipe(recipe.id!);
      return recipe.copyWith(tags: tags);
    }));
  }

  // --- Public Query Methods ---
  
  Future<List<Recipe>> getAllRecipes() => _getRecipesWithTags();

  Future<Recipe?> getRecipeById(int id) async {
    final recipes = await _getRecipesWithTags(where: 'id = ?', whereArgs: [id]);
    return recipes.isNotEmpty ? recipes.first : null;
  }
  
  Future<List<Recipe>> getVariationsForRecipe(int parentId) {
    return _getRecipesWithTags(where: 'parentRecipeId = ?', whereArgs: [parentId]);
  }

  Future<List<Recipe>> searchRecipes(String whereClause, List<Object?> whereArgs) {
    return _getRecipesWithTags(where: whereClause, whereArgs: whereArgs);
  }

  /// Fetches a list of the most recently added recipes.
  Future<List<Recipe>> getRecentRecipes({int limit = 5}) async {
    // This custom query remains as it has special ordering and limiting.
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      orderBy: 'id DESC',
      limit: limit,
    );
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
  }

  // --- Tag Management ---

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

  Future<List<String>> getAllUniqueTags() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('tags', orderBy: 'name ASC');
    return result.map((map) => map['name'] as String).toList();
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
  
  Future<void> clearAll() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('recipes');
    await db.delete('tags');
    await db.delete('recipe_tags');
  }
}