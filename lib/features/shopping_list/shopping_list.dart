// lib/features/shopping_list/shopping_list.dart
import 'package:recette/core/services/database_helper.dart';

// --- MODEL ---
class ShoppingListItem {
  final int? id;
  final String name;
  final bool isChecked;

  ShoppingListItem({this.id, required this.name, this.isChecked = false});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_checked': isChecked ? 1 : 0,
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'],
      name: map['name'],
      isChecked: map['is_checked'] == 1,
    );
  }
}

// --- SERVICE ---
class ShoppingListService {
  final _db = DatabaseHelper.instance;

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