// lib/core/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  // IMPORTANT: Increment the DB version to trigger the upgrade.
  static const int _dbVersion = 13;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recipes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint("--- Database path: $path ---");

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: onCreate,
      onUpgrade: _upgradeDB,
    );
  }

  // This method is now public for testing purposes.
  Future onCreate(Database db, int version) async {
    await _createRecipeTable(db);
    await _createRecipeTagTables(db);
    await _createInventoryTables(db);
    await _createShoppingListTables(db);
    await _createMealPlanTables(db);
    await _createGeneratedRecipesTable(db);
    await _createJobHistoryTable(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // --- All upgrade logic remains the same ---
    debugPrint("--- executing _upgradeDB (Upgrading from v$oldVersion to v$newVersion) ---");
    
    if (oldVersion < 2) await _addColumnIfNotExists(db, 'recipes', 'otherTimings', 'TEXT');
    if (oldVersion < 3) {
      await _addColumnIfNotExists(db, 'recipes', 'healthRating', 'TEXT');
      await _addColumnIfNotExists(db, 'recipes', 'healthSummary', 'TEXT');
      await _addColumnIfNotExists(db, 'recipes', 'healthSuggestions', 'TEXT');
      await _addColumnIfNotExists(db, 'recipes', 'dietaryProfileFingerprint', 'TEXT');
    }
    if (oldVersion < 4) await _addColumnIfNotExists(db, 'recipes', 'fingerprint', 'TEXT');
    if (oldVersion < 5) await _addColumnIfNotExists(db, 'recipes', 'parentRecipeId', 'INTEGER');
    if (oldVersion < 6) {
        await _createRecipeTagTables(db);
    }
    if (oldVersion < 7) await _createInventoryTables(db);
    if (oldVersion < 8) {
        await _createShoppingListTables(db);
        await _createMealPlanTables(db);
    }
    if (oldVersion < 9) await _addColumnIfNotExists(db, 'recipes', 'nutritionalInfo', 'TEXT');
    if (oldVersion < 10) await _createGeneratedRecipesTable(db);
    if (oldVersion < 11) await _createJobHistoryTable(db);
    if (oldVersion < 12) await _addColumnIfNotExists(db, 'job_history', 'title', 'TEXT');
    if (oldVersion < 13) await _addColumnIfNotExists(db, 'job_history', 'error_message', 'TEXT');

    debugPrint("--- _upgradeDB complete. ---");
  }

  // --- REFACTORED: Centralized method for inserting/updating tags ---
  Future<void> _manageTags(Transaction txn, int recipeId, List<String> tags) async {
    await txn.delete('recipe_tags', where: 'recipeId = ?', whereArgs: [recipeId]);
    for (String tagName in tags) {
      var existingTag = await txn.query('tags', where: 'name = ?', whereArgs: [tagName.toLowerCase()]);
      int tagId;
      if (existingTag.isEmpty) {
        tagId = await txn.insert('tags', {'name': tagName.toLowerCase()});
      } else {
        tagId = existingTag.first['id'] as int;
      }
      await txn.insert('recipe_tags', {'recipeId': recipeId, 'tagId': tagId});
    }
  }

  // --- REFACTORED: Centralized method for getting tags ---
  Future<List<String>> _getTagsForRecipe(DatabaseExecutor db, int recipeId) async {
    final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT T.name FROM tags T
        INNER JOIN recipe_tags RT ON T.id = RT.tagId
        WHERE RT.recipeId = ?
    ''', [recipeId]);
    return result.map((map) => map['name'] as String).toList();
  }

  // --- REFACTORED: A single, private helper to query recipes and attach their tags ---
  Future<List<Recipe>> _getRecipesWithTags({String? where, List<Object?>? whereArgs}) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'title ASC',
    );

    if (maps.isEmpty) return [];

    // Use Future.wait for more efficient, parallel fetching of tags.
    final recipes = await Future.wait(maps.map((map) async {
      final recipe = Recipe.fromMap(map);
      recipe.tags = await _getTagsForRecipe(db, recipe.id!);
      return recipe;
    }));
    
    return recipes.toList();
  }

  // --- REFACTORED: insert and update now use a transaction for atomicity ---
  Future<int> insert(Recipe recipe, List<String> tags) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final newId = await txn.insert('recipes', recipe.toMap());
      await _manageTags(txn, newId, tags);
      return newId;
    });
  }

  Future<int> update(Recipe recipe, List<String> tags) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final rowsAffected = await txn.update('recipes', recipe.toMap(), where: 'id = ?', whereArgs: [recipe.id]);
      await _manageTags(txn, recipe.id!, tags);
      return rowsAffected;
    });
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  // --- All public recipe-fetching methods now use the central helper ---
  Future<List<Recipe>> getAllRecipes() async {
    return _getRecipesWithTags();
  }

  Future<Recipe?> getRecipeById(int id) async {
    final recipes = await _getRecipesWithTags(where: 'id = ?', whereArgs: [id]);
    return recipes.isNotEmpty ? recipes.first : null;
  }

  Future<List<Recipe>> getVariationsForRecipe(int parentId) async {
    return _getRecipesWithTags(where: 'parentRecipeId = ?', whereArgs: [parentId]);
  }
  
  Future<List<Recipe>> searchRecipes(String whereClause, List<Object?> whereArgs) async {
    return _getRecipesWithTags(where: whereClause, whereArgs: whereArgs);
  }

  Future<bool> doesRecipeExist(String fingerprint) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1
    );
    return maps.isNotEmpty;
  }
  
  // --- Other methods remain largely the same ---
  
  Future<List<String>> getAllUniqueTags() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query('tags', orderBy: 'name ASC');
    return result.map((map) => map['name'] as String).toList();
  }

  Future<void> _addColumnIfNotExists(Database db, String tableName, String columnName, String columnType) async {
    var result = await db.rawQuery("PRAGMA table_info($tableName)");
    var columnNames = result.map((row) => row['name'] as String).toList();
    if (!columnNames.contains(columnName)) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
    }
  }

  // --- REFACTORED: Helper for Recipe-related tables ---
  Future<void> _createRecipeTable(Database db) async {
    await db.execute('''
      CREATE TABLE recipes ( 
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parentRecipeId INTEGER,
        fingerprint TEXT,
        title TEXT NOT NULL,
        description TEXT,
        prepTime TEXT,
        cookTime TEXT,
        totalTime TEXT,
        servings TEXT,
        ingredients TEXT NOT NULL,
        instructions TEXT NOT NULL,
        sourceUrl TEXT,
        otherTimings TEXT,
        healthRating TEXT,
        healthSummary TEXT,
        healthSuggestions TEXT,
        dietaryProfileFingerprint TEXT,
        nutritionalInfo TEXT
      )
    ''');
  }
  
  Future<void> _createRecipeTagTables(Database db) async {
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE recipe_tags (
        recipeId INTEGER,
        tagId INTEGER,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (tagId) REFERENCES tags (id) ON DELETE CASCADE,
        PRIMARY KEY (recipeId, tagId)
      )
    ''');
  }

  Future<void> _createInventoryTables(Database db) async {
      await db.execute('''
        CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            icon_name TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
        )
      ''');
      await db.execute('''
        CREATE TABLE inventory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            brand TEXT,
            quantity TEXT,
            unit TEXT,
            location_id INTEGER,
            category_id INTEGER,
            health_rating TEXT,
            notes TEXT,
            FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE,
            FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
        )
      ''');

      // --- NEW: Insert default locations ---
      var batch = db.batch();
      batch.insert('locations', {'name': 'Pantry'});
      batch.insert('locations', {'name': 'Fridge'});
      batch.insert('locations', {'name': 'Freezer'});
      batch.insert('locations', {'name': 'Spice Rack'});
      await batch.commit(noResult: true);
  }

  Future<void> _createShoppingListTables(Database db) async {
    await db.execute('''
      CREATE TABLE shopping_list_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }
  
  Future<void> _createMealPlanTables(Database db) async {
    await db.execute('''
      CREATE TABLE meal_plan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        breakfast_recipe_id INTEGER,
        lunch_recipe_id INTEGER,
        dinner_recipe_id INTEGER,
        FOREIGN KEY (breakfast_recipe_id) REFERENCES recipes (id) ON DELETE SET NULL,
        FOREIGN KEY (lunch_recipe_id) REFERENCES recipes (id) ON DELETE SET NULL,
        FOREIGN KEY (dinner_recipe_id) REFERENCES recipes (id) ON DELETE SET NULL
      )
    ''');
  }
  
  Future<void> _createGeneratedRecipesTable(Database db) async {
    await db.execute('''
      CREATE TABLE generated_recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        payload TEXT NOT NULL, -- Stores the full Recipe JSON
        status TEXT NOT NULL DEFAULT 'pending' -- pending, saved, discarded
      )
    ''');
  }

  Future<void> _createJobHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE job_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_type TEXT NOT NULL,
        title TEXT,
        status TEXT NOT NULL,
        error_message TEXT,
        priority TEXT NOT NULL DEFAULT 'normal',
        request_fingerprint TEXT UNIQUE,
        request_payload TEXT,
        prompt_text TEXT,
        response_payload TEXT,
        created_at DATETIME NOT NULL,
        completed_at DATETIME
      )
    ''');
  }
}