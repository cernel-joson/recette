import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intelligent_nutrition_app/features/recipes/data/models/models.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  
  // IMPORTANT: Increment the DB version to trigger the upgrade.
  static const int _dbVersion = 6;

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
    // This now includes the parentRecipeId column from the start.
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
    // Create a table for all unique tags
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    // Create a "join table" to link recipes and tags
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
  
  // IMPORTANT: This method handles database schema updates for existing users.
  // It's called when the _dbVersion is higher than the version on the user's device.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint("--- executing _upgradeDB (Upgrading from v$oldVersion to v$newVersion) ---");
    
    if (oldVersion < 2) {
      debugPrint("--- Upgrading from v1: Adding all new columns. ---");
      await db.execute("ALTER TABLE recipes ADD COLUMN otherTimings TEXT");
    }
    
    if (oldVersion < 3) {
      debugPrint("--- Upgrading from v2: Adding all new columns. ---");
      // We are upgrading from version 2 to 3.
      // Add the new columns without deleting existing data.
      await db.execute('ALTER TABLE recipes ADD COLUMN healthRating TEXT');
      await db.execute('ALTER TABLE recipes ADD COLUMN healthSummary TEXT');
      await db.execute('ALTER TABLE recipes ADD COLUMN healthSuggestions TEXT');
      await db.execute('ALTER TABLE recipes ADD COLUMN dietaryProfileFingerprint TEXT');
    }
    
    if (oldVersion < 4) {
      debugPrint("--- Upgrading from v3: Adding all new columns. ---");
      await _addColumnIfNotExists(db, 'recipes', 'fingerprint', 'TEXT');
    }

    // --- NEW: Add the parentRecipeId column if upgrading from a version less than 5. ---
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
    debugPrint("--- _upgradeDB complete. ---");
  }

  /// Adds a list of tags to a specific recipe atomically.
  Future<void> addTagsToRecipe(int recipeId, List<String> tags) async {
    final db = await instance.database;
    
    await db.transaction((txn) async {
      // Step 1: Delete all existing tags for this recipe.
      await txn.delete('recipe_tags', where: 'recipeId = ?', whereArgs: [recipeId]);

      // Step 2: Loop through and add the new tags.
      for (String tagName in tags) {
        // Get tag ID or insert it if new.
        var existingTag = await txn.query('tags', where: 'name = ?', whereArgs: [tagName.toLowerCase()]);
        int tagId;
        if (existingTag.isEmpty) {
          tagId = await txn.insert('tags', {'name': tagName.toLowerCase()});
        } else {
          tagId = existingTag.first['id'] as int;
        }
        
        // Link recipe and tag.
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
  
  // Helper to prevent errors if an upgrade is attempted multiple times.
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

  /// --- UPDATED to fetch tags ---
  Future<List<Recipe>> getAllRecipes() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('recipes', orderBy: 'title ASC');

    // Create a list of recipes from the maps.
    List<Recipe> recipes = List.generate(maps.length, (i) {
      return Recipe.fromMap(maps[i]);
    });

    // --- NEW: Loop through each recipe and fetch its tags ---
    for (int i = 0; i < recipes.length; i++) {
      final recipeTags = await getTagsForRecipe(recipes[i].id!);
      recipes[i].tags = recipeTags; // Assign the fetched tags
    }
    
    return recipes;
  }

  /// --- UPDATED to fetch tags ---
  Future<Recipe?> getRecipeById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('recipes', where: 'id = ?', whereArgs: [id], limit: 1);

    if (maps.isNotEmpty) {
      final recipe = Recipe.fromMap(maps.first);
      // --- NEW: Fetch and assign the tags for the single recipe ---
      final recipeTags = await getTagsForRecipe(recipe.id!);
      recipe.tags = recipeTags;
      return recipe;
    }
    return null;
  }
  
  // Method to check for a duplicate recipe by its fingerprint.
  Future<bool> doesRecipeExist(String fingerprint) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recipes',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
    );
    return maps.isNotEmpty;
  }

  /// --- NEW: Fetches all variations for a given parent recipe ID. ---
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

  /// NEW: A generic search method for recipes.
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
    
    // As before, we need to hydrate the recipes with their tags.
    List<Recipe> recipes = List.generate(maps.length, (i) => Recipe.fromMap(maps[i]));
    for (int i = 0; i < recipes.length; i++) {
      recipes[i].tags = await getTagsForRecipe(recipes[i].id!);
    }
    
    return recipes;
  }
}