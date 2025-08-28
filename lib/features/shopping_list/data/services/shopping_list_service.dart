import 'package:flutter/foundation.dart';
import 'package:recette/core/services/database_helper.dart';
import 'package:recette/features/shopping_list/data/models/models.dart';

// --- SERVICE ---
class ShoppingListService {
  final DatabaseHelper _db;

  // Public constructor uses the real instance
  ShoppingListService() : _db = DatabaseHelper.instance;

  // Internal constructor for testing
  @visibleForTesting
  ShoppingListService.internal(this._db);

  Future<List<ShoppingListItem>> getItems() async {
    final db = await _db.database;
    final maps = await db.query('shopping_list_items', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => ShoppingListItem.fromMap(maps[i]));
  }

  Future<void> addItem(String name) async {
    if (name.trim().isEmpty) return;
    final db = await _db.database;
    await db.insert('shopping_list_items', {'name': name, 'is_checked': 0});
  }

  Future<void> updateItem(ShoppingListItem item) async {
    final db = await _db.database;
    await db.update('shopping_list_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteItem(int id) async {
    final db = await _db.database;
    await db.delete('shopping_list_items', where: 'id = ?', whereArgs: [id]);
  }
}