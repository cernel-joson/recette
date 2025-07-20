import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recipe_model.dart';

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
    String path = join(await getDatabasesPath(), 'recipes.db');
    return await openDatabase(path,
        version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
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
            sourceUrl TEXT NOT NULL,
            otherTimings TEXT 
          )
          ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE recipes ADD COLUMN otherTimings TEXT;");
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