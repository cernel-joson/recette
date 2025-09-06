// lib/core/data/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:recette/features/recipes/data/models/models.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  // IMPORTANT: Increment the DB version to trigger the upgrade.
  static const int _dbVersion = 20;

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
    await _createChatMessagesTable(db);
    await _createShoppingListCategoriesTable(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
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
    if (oldVersion < 14) await _addColumnIfNotExists(db, 'job_history', 'raw_ai_response', 'TEXT');
    if (oldVersion < 15) {
      await db.execute('DROP TABLE IF EXISTS meal_plan');
      await _createMealPlanTables(db);
    }
    if (oldVersion < 16) await _createChatMessagesTable(db);
    if (oldVersion < 17) await _createShoppingListCategoriesTable(db);
    // Add a robust migration to rebuild the shopping list table correctly.
    // This replaces the previous, simpler migration for version 18.
    if (oldVersion < 19) {
      await db.execute('ALTER TABLE shopping_list_items RENAME TO _shopping_list_items_old');
      await _createShoppingListTables(db);
      
      // Copy data from the old table to the new one, mapping old 'name' column
      // to the new 'raw_text' and 'parsed_name' columns.
      await db.execute('''
        INSERT INTO shopping_list_items (id, raw_text, parsed_name, is_checked)
        SELECT id, name, name, is_checked FROM _shopping_list_items_old
      ''');
      
      await db.execute('DROP TABLE _shopping_list_items_old');
    }
    // Safely migrate the meal plan table to the new, more flexible schema.
    if (oldVersion < 20) {
      await db.execute('DROP TABLE IF EXISTS meal_plan_entries');
      await _createMealPlanTables(db);
    }

    debugPrint("--- _upgradeDB complete. ---");
  }

  Future<void> _addColumnIfNotExists(Database db, String tableName, String columnName, String columnType) async {
    var result = await db.rawQuery("PRAGMA table_info($tableName)");
    var columnNames = result.map((row) => row['name'] as String).toList();
    if (!columnNames.contains(columnName)) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $columnType');
    }
  }

  // --- SCHEMA DEFINITIONS ---
  // These methods define the database schema and are appropriately called by onCreate/onUpgrade.

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
        category_id INTEGER,
        raw_text TEXT NOT NULL,
        parsed_name TEXT,
        parsed_quantity TEXT,
        is_checked INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES shopping_list_categories (id) ON DELETE SET NULL
      )
    ''');
  }
  
  // The schema is updated to support both recipe and text entries.
  Future<void> _createMealPlanTables(Database db) async {
    await db.execute('''
      CREATE TABLE meal_plan_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        entry_type TEXT NOT NULL,
        recipe_id INTEGER,
        recipe_title TEXT,
        text_entry TEXT,
        FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE SET NULL
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
        raw_ai_response TEXT,
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

  Future<void> _createChatMessagesTable(Database db) async {
    await db.execute('''
  CREATE TABLE chat_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    role TEXT NOT NULL, -- 'user' or 'model'
    content TEXT NOT NULL,
    timestamp DATETIME NOT NULL
  )
''');
  }

  Future<void> _createShoppingListCategoriesTable(Database db) async {
    await db.execute('''
  CREATE TABLE shopping_list_categories  (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
  )
''');

    // Add a default category to ensure the list is never empty.
    await db.insert('shopping_list_categories', {'name': 'Uncategorized'});
  }
}