import 'package:sqflite/sqflite.dart';
// We import the 'path' package with a prefix 'p' to prevent the
// name collision between its 'Context' class and Flutter's 'BuildContext'.
import 'package:path/path.dart' as p;

import '../models/recipe_model.dart';

// --- Database Helper Class ---
class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = p.join(await getDatabasesPath(), 'recipes.db');
    return await openDatabase(path,
        version: 1,
        onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE recipes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            prepTime TEXT,
            cookTime TEXT,
            totalTime TEXT,
            servings TEXT,
            ingredients TEXT NOT NULL,
            instructions TEXT NOT NULL,
            sourceUrl TEXT NOT NULL
          )
          ''');
  }

  Future<int> insert(Recipe recipe) async {
    Database db = await instance.database;
    return await db.insert('recipes', recipe.toMap());
  }

  Future<int> update(Recipe recipe) async {
    Database db = await instance.database;
    return await db.update('recipes', recipe.toMap(), where: 'id = ?', whereArgs: [recipe.id]);
  }

  // New method to delete a recipe by its ID.
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Recipe>> getAllRecipes() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('recipes', orderBy: 'title ASC');
    return List.generate(maps.length, (i) {
      return Recipe.fromMap(maps[i]);
    });
  }
}