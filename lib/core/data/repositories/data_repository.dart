import 'package:recette/core/services/database_helper.dart';

// A generic interface defining the contract for our models
abstract interface class DataModel {
  int? get id;
  Map<String, dynamic> toMap();
}

/// A generic repository for handling common CRUD operations for any data model.
class DataRepository<T extends DataModel> {
  final String tableName;
  final T Function(Map<String, dynamic>) fromMap;

  DataRepository({
    required this.tableName,
    required this.fromMap,
  });

  Future<T> create(T item) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert(tableName, item.toMap());
    // This is a simplified way to return the created item with its new ID.
    // A more robust implementation might re-fetch the item from the DB.
    final createdMap = item.toMap()..['id'] = id;
    return fromMap(createdMap);
  }

  Future<T?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return fromMap(maps.first);
    }
    return null;
  }

  Future<List<T>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(tableName);
    return maps.map((map) => fromMap(map)).toList();
  }

  Future<int> update(T item) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      tableName,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes all records from the table
  Future<void> clear() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(tableName);
  }

  /// --- NEW: Inserts a list of items in a single transaction ---
  Future<void> batchInsert(List<T> items) async {
    if (items.isEmpty) return;
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final item in items) {
        // We strip out the ID to ensure the database auto-generates a new one
        final map = item.toMap()..remove('id');
        await txn.insert(tableName, map);
      }
    });
  }
}