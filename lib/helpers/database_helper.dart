import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recipe_model.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  
  // Use a higher version number to trigger the onUpgrade method
  static const int _dbVersion = 5;

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
    debugPrint("--- executing _createDB (Database did not exist) ---");
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const nullableTextType = 'TEXT';

    await db.execute('''
      CREATE TABLE recipes ( 
        id $idType, 
        title $textType,
        description $nullableTextType,
        prepTime $nullableTextType,
        cookTime $nullableTextType,
        totalTime $nullableTextType,
        servings $nullableTextType,
        ingredients $textType,
        instructions $textType,
        sourceUrl $nullableTextType,
        otherTimings $nullableTextType,
        healthRating $nullableTextType,
        healthSummary $nullableTextType,
        healthSuggestions $nullableTextType,
        dietaryProfileFingerprint $nullableTextType
      )
    ''');
    debugPrint("--- _createDB complete. Table 'recipes' created with all columns. ---");
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
       // This is a safety net. We can check if columns exist before adding them
       // to avoid errors if a migration is re-run.
       await _addColumnIfNotExists(db, 'recipes', 'healthRating', 'TEXT');
       await _addColumnIfNotExists(db, 'recipes', 'healthSummary', 'TEXT');
       await _addColumnIfNotExists(db, 'recipes', 'healthSuggestions', 'TEXT');
       await _addColumnIfNotExists(db, 'recipes', 'dietaryProfileFingerprint', 'TEXT');
    }
    debugPrint("--- _upgradeDB complete. ---");
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

  Future<List<Recipe>> getAllRecipes() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('recipes', orderBy: 'title ASC');
    return List.generate(maps.length, (i) {
      return Recipe.fromMap(maps[i]);
    });
  }

  /// --- NEW: Fetches a single recipe by its ID. ---
  Future<Recipe?> getRecipeById(int id) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('recipes', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isNotEmpty) {
      return Recipe.fromMap(maps.first);
    }
    return null;
  }
}