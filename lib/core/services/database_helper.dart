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
  static const int _dbVersion = 7;

  Future<Database> get database async {
    debugPrint("--- Database getter called ---");
    if (_database != null) {
      debugPrint("--- Returning existing _database instance. ---");
      return _database!;
    }
    debugPrint("--- _database is null. Initializing new instance. ---");
    _database = await _initDB('recipes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    debugPrint("--- Database path: $path ---");

    return await openDatabase(
      path,
      version: _dbVersion, // Set the new version
      onCreate: _createDB,
      onUpgrade: _upgradeDB, // Add the upgrade callback
    );
  }

  // This method is called when the database is created for the first time.
  Future _createDB(Database db, int version) async {
    // --- Recipe Tables ---
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
        dietaryProfileFingerprint TEXT
      )
    ''');
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

    // --- NEW: Inventory Tables ---
    await _createInventoryTables(db);
  }
  
  // IMPORTANT: This method handles database schema updates for existing users.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint("--- executing _upgradeDB (Upgrading from v$oldVersion to v$newVersion) ---");
    
    // Migrations from previous versions...
    if (oldVersion < 2) {
      await _addColumnIfNotExists(db, 'recipes', 'otherTimings', 'TEXT');
    }
    if (oldVersion < 3) {
      await _addColumnIfNotExists(db, 'recipes', 'healthRating', 'TEXT');
      await _addColumnIfNotExists(db, 'recipes', 'healthSummary', 'TEXT');
      await _addColumnIfNotExists(db, 'recipes', 'healthSuggestions', 'TEXT');
      await _addColumnIfNotExists(db, 'recipes', 'dietaryProfileFingerprint', 'TEXT');
    }
    if (oldVersion < 4) {
      await _addColumnIfNotExists(db, 'recipes', 'fingerprint', 'TEXT');
    }
    if (oldVersion < 5) {
      await _addColumnIfNotExists(db, 'recipes', 'parentRecipeId', 'INTEGER');
    }
    if (oldVersion < 6) {
      await db.execute('''CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )''');
      await db.execute('''CREATE TABLE recipe_tags (
        recipeId INTEGER,
        tagId INTEGER,
        FOREIGN KEY (recipeId) REFERENCES recipes (id) ON DELETE CASCADE,
        FOREIGN KEY (tagId) REFERENCES tags (id) ON DELETE CASCADE,
        PRIMARY KEY (recipeId, tagId)
      )''');
    }
    
    // --- NEW: Migration for Inventory System ---
    if (oldVersion < 7) {
        debugPrint("--- Upgrading from v6 to v7: Adding Inventory Tables ---");
        await _createInventoryTables(db);
    }
    debugPrint("--- _upgradeDB complete. ---");
  }

  // --- NEW: Helper to create inventory tables to avoid duplication ---
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

  /// Adds a list of tags to a specific recipe atomically.
  Future<void> addTagsToRecipe(int recipeId, List<String> tags) async {
    final db = await instance.database;
    
    await db.transaction((txn) async {
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
    });
  }

  /// Fetches all tags for a given recipe ID.
  Future<List<String>> getTagsForRecipe(int recipeId) async {
      final db = await instance.database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
          SELECT T.name FROM tags T
          INNER JOIN recipe_tags RT ON T.id = RT.tagId
          WHERE RT.recipeId = ?
      ''', [recipeId]);
      return result.map((map) => map['name'] as String).toList();
  }
  
  Future<void> _addColumnIfNotExists(Database db, String tableName, String columnName, String columnType) async {
    var result = await db.rawQuery("PRAGMA table_info($tableName)");
    var columnNames = result.map((row) => row['name'] as String).toList();
    if (!columnNames.contains(columnName)) {
      debugPrint("--- Column '$columnName' does not exist. Adding it. ---");
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
    } else {
      debugPrint("--- Column '$columnName' already exists. Skipping. ---");
    }
  }

  Future<int> insert(Recipe recipe) async {
    Database db = await instance.database;
    return await db.insert('recipes', recipe.toMap());
  }

  Future<int> update(Recipe recipe) async {
    Database db = await instance.database;
    return await db.update('recipes', recipe.toMap(),
        where: 'id = ?', whereArgs: [recipe.id]);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Recipe>> getAllRecipes() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('recipes', orderBy: 'title ASC');

    List<Recipe> recipes = List.generate(maps.length, (i) {
      return Recipe.fromMap(maps[i]);
    });

    for (int i = 0; i < recipes.length; i++) {
      final recipeTags = await getTagsForRecipe(recipes[i].id!);
      recipes[i].tags = recipeTags;
    }
    
    return recipes;
  }

  Future<Recipe?> getRecipeById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('recipes', where: 'id = ?', whereArgs: [id], limit: 1);

    if (maps.isNotEmpty) {
      final recipe = Recipe.fromMap(maps.first);
      final recipeTags = await getTagsForRecipe(recipe.id!);
      recipe.tags = recipeTags;
      return recipe;
    }
    return null;
  }
  
  Future<bool> doesRecipeExist(String fingerprint) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
    );
    return maps.isNotEmpty;
  }

  Future<List<Recipe>> getVariationsForRecipe(int parentId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'parentRecipeId = ?',
      whereArgs: [parentId],
      orderBy: 'title ASC',
    );
    return List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
  }

  Future<List<Recipe>> searchRecipes(String whereClause, List<Object?> whereArgs) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'title ASC',
    );

    if (maps.isEmpty) {
      return [];
    }
    
    List<Recipe> recipes = List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
    for (int i = 0; i < recipes.length; i++) {
      recipes[i].tags = await getTagsForRecipe(recipes[i].id!);
    }
    
    return recipes;
  }

  Future<List<String>> getAllUniqueTags() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query('tags', orderBy: 'name ASC');
    return result.map((map) => map['name'] as String).toList();
  }

  Future<List<Recipe>> findCandidateMatches(int newRecipeId, List<String> keyIngredients) async {
    final db = await instance.database;
    
    final whereClauses = keyIngredients.map((ing) => 'ingredients LIKE ?').join(' OR ');
    final whereArgs = keyIngredients.map((ing) => '%"name":"%$ing%"%').toList();
    
    final finalWhere = 'id != ? AND ($whereClauses)';
    final finalArgs = [newRecipeId, ...whereArgs];

    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: finalWhere,
      whereArgs: finalArgs,
      limit: 10,
    );
    
    List<Recipe> recipes = List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
    for (int i = 0; i < recipes.length; i++) {
      recipes[i].tags = await getTagsForRecipe(recipes[i].id!);
    }
    
    return recipes;
  }
}